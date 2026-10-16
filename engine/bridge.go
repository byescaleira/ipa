package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/cookiejar"
	"os"
	"strconv"
	"sync"
	"time"
	"unsafe"

	"github.com/byteness/keyring"
	"github.com/majd/ipatool/v2/pkg/appstore"
	"github.com/majd/ipatool/v2/pkg/util/operatingsystem"
	"github.com/schollz/progressbar/v3"
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

type bridgeError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type baseRequest struct {
	Credential json.RawMessage `json:"credential"`
	MacAddress string          `json:"macAddress"`
	Home       string          `json:"home"`
	AppID      int64           `json:"appID"`
	BundleID   string          `json:"bundleID"`
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

func (b baseRequest) resolve() (appstore.AppStore, appstore.Account, appstore.App, error) {
	var account appstore.Account
	if len(b.Credential) > 0 {
		if err := json.Unmarshal(b.Credential, &account); err != nil {
			return nil, account, appstore.App{}, err
		}
	}
	store, err := newStore(b.MacAddress, b.Home)
	return store, account, appstore.App{ID: b.AppID, BundleID: b.BundleID}, err
}

func marshal(value any) *C.char {
	data, err := json.Marshal(value)
	if err != nil {
		return C.CString(`{"error":{"code":"other","message":"failed to encode response"}}`)
	}
	return C.CString(string(data))
}

func failure(err error) *C.char {
	return marshal(map[string]any{"error": classify(err)})
}

type loginRequest struct {
	Email      string `json:"email"`
	Password   string `json:"password"`
	Code       string `json:"code"`
	MacAddress string `json:"macAddress"`
	Home       string `json:"home"`
}

//export ipa_login
func ipa_login(request *C.char) *C.char {
	var input loginRequest
	if err := json.Unmarshal([]byte(C.GoString(request)), &input); err != nil {
		return failure(errors.New("invalid request"))
	}
	store, err := newStore(input.MacAddress, input.Home)
	if err != nil {
		return failure(err)
	}
	output, err := store.Login(appstore.LoginInput{
		Email: input.Email, Password: input.Password, AuthCode: input.Code,
	})
	if err != nil {
		return failure(err)
	}
	return marshal(map[string]any{"account": output.Account})
}

//export ipa_versions
func ipa_versions(request *C.char) *C.char {
	var input baseRequest
	if err := json.Unmarshal([]byte(C.GoString(request)), &input); err != nil {
		return failure(errors.New("invalid request"))
	}
	store, account, app, err := input.resolve()
	if err != nil {
		return failure(err)
	}
	output, err := store.ListVersions(appstore.ListVersionsInput{
		Context: context.Background(), Account: account, App: app,
		Platform: appstore.PlatformIPhone,
	})
	if err != nil {
		return failure(err)
	}
	return marshal(map[string]any{
		"versions": output.ExternalVersionIdentifiers,
		"latest":   output.LatestExternalVersionID,
	})
}

type metadataRequest struct {
	baseRequest
	VersionID string `json:"versionID"`
}

//export ipa_version_metadata
func ipa_version_metadata(request *C.char) *C.char {
	var input metadataRequest
	if err := json.Unmarshal([]byte(C.GoString(request)), &input); err != nil {
		return failure(errors.New("invalid request"))
	}
	store, account, app, err := input.resolve()
	if err != nil {
		return failure(err)
	}
	output, err := store.GetVersionMetadata(appstore.GetVersionMetadataInput{
		Context: context.Background(), Account: account, App: app,
		VersionID: input.VersionID, Platform: appstore.PlatformIPhone,
	})
	if err != nil {
		return failure(err)
	}
	return marshal(map[string]any{
		"displayVersion": output.DisplayVersion,
		"releaseDate":    output.ReleaseDate.Format(time.RFC3339),
	})
}

//export ipa_purchase
func ipa_purchase(request *C.char) *C.char {
	var input baseRequest
	if err := json.Unmarshal([]byte(C.GoString(request)), &input); err != nil {
		return failure(errors.New("invalid request"))
	}
	store, account, app, err := input.resolve()
	if err != nil {
		return failure(err)
	}
	err = store.Purchase(appstore.PurchaseInput{
		Account: account, App: app, Platform: appstore.PlatformIPhone,
	})
	if err != nil && !errors.Is(err, appstore.ErrLicenseAlreadyExists) {
		return failure(err)
	}
	return marshal(map[string]any{"ok": true})
}

type downloadState struct {
	mu        sync.Mutex
	phase     string
	completed int64
	total     int64
	done      bool
	fileName  string
	version   string
	size      int64
	err       *bridgeError
	cancel    context.CancelFunc
}

var (
	tasks   = map[string]*downloadState{}
	tasksMu sync.Mutex
	taskSeq int64
)

type downloadRequest struct {
	baseRequest
	VersionID  string `json:"versionID"`
	OutputPath string `json:"outputPath"`
}

//export ipa_download_start
func ipa_download_start(request *C.char) *C.char {
	var input downloadRequest
	if err := json.Unmarshal([]byte(C.GoString(request)), &input); err != nil {
		return failure(errors.New("invalid request"))
	}
	store, account, app, err := input.resolve()
	if err != nil {
		return failure(err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	state := &downloadState{phase: "downloading", cancel: cancel}
	tasksMu.Lock()
	taskSeq++
	id := strconv.FormatInt(taskSeq, 10)
	tasks[id] = state
	tasksMu.Unlock()

	go runDownload(ctx, store, account, app, input, state)
	return marshal(map[string]any{"taskID": id})
}

func runDownload(
	ctx context.Context, store appstore.AppStore, account appstore.Account, app appstore.App,
	input downloadRequest, state *downloadState,
) {
	bar := progressbar.NewOptions64(1, progressbar.OptionSetWriter(nopWriter{}))
	stop := make(chan struct{})
	go func() {
		ticker := time.NewTicker(200 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-stop:
				return
			case <-ticker.C:
				s := bar.State()
				state.mu.Lock()
				state.total = int64(s.Max)
				state.completed = int64(s.CurrentNum)
				state.mu.Unlock()
			}
		}
	}()

	download := func() (appstore.DownloadOutput, error) {
		return store.Download(appstore.DownloadInput{
			Context: ctx, Account: account, App: app, OutputPath: input.OutputPath,
			Progress: bar, ExternalVersionID: input.VersionID, Platform: appstore.PlatformIPhone,
		})
	}

	out, err := download()
	if errors.Is(err, appstore.ErrLicenseRequired) {
		state.setPhase("licensing")
		perr := store.Purchase(appstore.PurchaseInput{
			Account: account, App: app, Platform: appstore.PlatformIPhone,
		})
		if perr != nil && !errors.Is(perr, appstore.ErrLicenseAlreadyExists) {
			close(stop)
			state.fail(perr)
			return
		}
		state.setPhase("downloading")
		out, err = download()
	}
	close(stop)
	if err != nil {
		state.fail(err)
		return
	}

	state.setPhase("signing")
	if serr := store.ReplicateSinf(appstore.ReplicateSinfInput{
		Sinfs: out.Sinfs, PackagePath: out.DestinationPath,
	}); serr != nil {
		state.fail(serr)
		return
	}

	var size int64
	if info, statErr := os.Stat(out.DestinationPath); statErr == nil {
		size = info.Size()
	}
	state.mu.Lock()
	state.done = true
	state.phase = "done"
	state.fileName = out.DestinationPath
	state.version = app.Version
	state.size = size
	state.mu.Unlock()
}

func (s *downloadState) setPhase(phase string) {
	s.mu.Lock()
	s.phase = phase
	s.mu.Unlock()
}

func (s *downloadState) fail(err error) {
	s.mu.Lock()
	s.err = classify(err)
	s.done = true
	s.mu.Unlock()
}

//export ipa_task_status
func ipa_task_status(taskID *C.char) *C.char {
	tasksMu.Lock()
	state := tasks[C.GoString(taskID)]
	tasksMu.Unlock()
	if state == nil {
		return failure(errors.New("unknown task"))
	}
	state.mu.Lock()
	defer state.mu.Unlock()
	result := map[string]any{
		"phase": state.phase, "completed": state.completed, "total": state.total,
		"done": state.done, "fileName": state.fileName, "version": state.version,
		"size": state.size,
	}
	if state.err != nil {
		result["error"] = state.err
	}
	return marshal(result)
}

//export ipa_task_cancel
func ipa_task_cancel(taskID *C.char) {
	id := C.GoString(taskID)
	tasksMu.Lock()
	state := tasks[id]
	delete(tasks, id)
	tasksMu.Unlock()
	if state != nil && state.cancel != nil {
		state.cancel()
	}
}

//export ipa_free
func ipa_free(pointer *C.char) {
	C.free(unsafe.Pointer(pointer))
}

type nopWriter struct{}

func (nopWriter) Write(p []byte) (int, error) { return len(p), nil }

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
	case errors.Is(err, context.Canceled):
		return &bridgeError{Code: "cancelled", Message: err.Error()}
	default:
		return &bridgeError{Code: "other", Message: err.Error()}
	}
}

func main() {}
