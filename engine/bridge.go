package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/cookiejar"
	"sync"
	"unsafe"

	"github.com/byteness/keyring"
	"github.com/majd/ipatool/v2/pkg/appstore"
	"github.com/majd/ipatool/v2/pkg/util/operatingsystem"
)

type memoryKeychain struct {
	mu    sync.Mutex
	items map[string][]byte
}

func newMemoryKeychain() *memoryKeychain {
	return &memoryKeychain{items: map[string][]byte{}}
}

func (k *memoryKeychain) Get(key string) ([]byte, error) {
	k.mu.Lock()
	defer k.mu.Unlock()
	value, ok := k.items[key]
	if !ok {
		return nil, keyring.ErrKeyNotFound
	}
	return value, nil
}

func (k *memoryKeychain) Set(key string, data []byte) error {
	k.mu.Lock()
	defer k.mu.Unlock()
	k.items[key] = append([]byte(nil), data...)
	return nil
}

func (k *memoryKeychain) Remove(key string) error {
	k.mu.Lock()
	defer k.mu.Unlock()
	delete(k.items, key)
	return nil
}

type fixedMachine struct {
	macAddress string
	home       string
}

func (m fixedMachine) MacAddress() (string, error) {
	if m.macAddress == "" {
		return "", errors.New("mac address is not set")
	}
	return m.macAddress, nil
}

func (m fixedMachine) HomeDirectory() string { return m.home }

func (fixedMachine) ReadPassword(int) ([]byte, error) {
	return nil, errors.New("interactive password input is not available")
}

type savingCookieJar struct {
	http.CookieJar
}

func (savingCookieJar) Save() error { return nil }

type loginRequest struct {
	Email      string `json:"email"`
	Password   string `json:"password"`
	Code       string `json:"code"`
	MacAddress string `json:"macAddress"`
	Home       string `json:"home"`
}

type bridgeError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type loginResponse struct {
	Account *appstore.Account `json:"account,omitempty"`
	Error   *bridgeError      `json:"error,omitempty"`
}

func newStore(macAddress, home string) (appstore.AppStore, error) {
	jar, err := cookiejar.New(nil)
	if err != nil {
		return nil, err
	}
	return appstore.NewAppStore(appstore.Args{
		Keychain:        newMemoryKeychain(),
		CookieJar:       savingCookieJar{jar},
		OperatingSystem: operatingsystem.New(),
		Machine:         fixedMachine{macAddress: macAddress, home: home},
	}), nil
}

func marshal(value any) *C.char {
	data, err := json.Marshal(value)
	if err != nil {
		return C.CString(`{"error":{"code":"other","message":"failed to encode response"}}`)
	}
	return C.CString(string(data))
}

//export ipa_login
func ipa_login(request *C.char) *C.char {
	var input loginRequest
	if err := json.Unmarshal([]byte(C.GoString(request)), &input); err != nil {
		return marshal(loginResponse{Error: &bridgeError{Code: "other", Message: "invalid request"}})
	}

	store, err := newStore(input.MacAddress, input.Home)
	if err != nil {
		return marshal(loginResponse{Error: &bridgeError{Code: "other", Message: err.Error()}})
	}

	output, err := store.Login(appstore.LoginInput{
		Email:    input.Email,
		Password: input.Password,
		AuthCode: input.Code,
	})
	if err != nil {
		return marshal(loginResponse{Error: classify(err)})
	}

	return marshal(loginResponse{Account: &output.Account})
}

//export ipa_free
func ipa_free(pointer *C.char) {
	C.free(unsafe.Pointer(pointer))
}

func classify(err error) *bridgeError {
	switch {
	case errors.Is(err, appstore.ErrAuthCodeRequired):
		return &bridgeError{Code: "code_required", Message: err.Error()}
	case errors.Is(err, appstore.ErrLicenseRequired):
		return &bridgeError{Code: "license_required", Message: err.Error()}
	case errors.Is(err, appstore.ErrPasswordTokenExpired):
		return &bridgeError{Code: "token_expired", Message: err.Error()}
	case errors.Is(err, appstore.ErrAppNotFound):
		return &bridgeError{Code: "not_found", Message: err.Error()}
	default:
		return &bridgeError{Code: "other", Message: err.Error()}
	}
}

func main() {}
