package main

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"net/http/cookiejar"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

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

type apiError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func classify(err error) apiError {
	switch {
	case errors.Is(err, appstore.ErrAuthCodeRequired):
		return apiError{Code: "code_required", Message: err.Error()}
	case errors.Is(err, appstore.ErrLicenseRequired):
		return apiError{Code: "license_required", Message: err.Error()}
	case errors.Is(err, appstore.ErrPasswordTokenExpired):
		return apiError{Code: "token_expired", Message: err.Error()}
	case errors.Is(err, appstore.ErrAppNotFound):
		return apiError{Code: "not_found", Message: err.Error()}
	case errors.Is(err, context.Canceled):
		return apiError{Code: "cancelled", Message: err.Error()}
	default:
		return apiError{Code: "other", Message: err.Error()}
	}
}

type server struct {
	token string
	cache string
}

func (s server) store(macAddress string) (appstore.AppStore, error) {
	jar, err := cookiejar.New(nil)
	if err != nil {
		return nil, err
	}
	return appstore.NewAppStore(appstore.Args{
		Keychain:        newMemoryKeychain(),
		CookieJar:       savingCookieJar{jar},
		OperatingSystem: operatingsystem.New(),
		Machine:         fixedMachine{macAddress: macAddress, home: s.cache},
	}), nil
}

type appRequest struct {
	Credential json.RawMessage `json:"credential"`
	MacAddress string          `json:"macAddress"`
	AppID      int64           `json:"appID"`
	BundleID   string          `json:"bundleID"`
	VersionID  string          `json:"versionID"`
}

func (r appRequest) resolve(s server) (appstore.AppStore, appstore.Account, appstore.App, error) {
	var account appstore.Account
	if len(r.Credential) > 0 {
		if err := json.Unmarshal(r.Credential, &account); err != nil {
			return nil, account, appstore.App{}, err
		}
	}
	store, err := s.store(r.MacAddress)
	return store, account, appstore.App{ID: r.AppID, BundleID: r.BundleID}, err
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func writeError(w http.ResponseWriter, err error) {
	writeJSON(w, http.StatusBadGateway, map[string]any{"error": classify(err)})
}

func decode(w http.ResponseWriter, r *http.Request, value any) bool {
	if err := json.NewDecoder(r.Body).Decode(value); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{
			"error": apiError{Code: "invalid_request", Message: "could not decode request"},
		})
		return false
	}
	return true
}

func (s server) authorize(w http.ResponseWriter, r *http.Request) bool {
	if s.token == "" {
		return true
	}
	header := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	if subtle.ConstantTimeCompare([]byte(header), []byte(s.token)) != 1 {
		writeJSON(w, http.StatusUnauthorized, map[string]any{
			"error": apiError{Code: "unauthorized", Message: "invalid token"},
		})
		return false
	}
	return true
}

type loginRequest struct {
	Email      string `json:"email"`
	Password   string `json:"password"`
	Code       string `json:"code"`
	MacAddress string `json:"macAddress"`
}

func (s server) handleLogin(w http.ResponseWriter, r *http.Request) {
	if !s.authorize(w, r) {
		return
	}
	var input loginRequest
	if !decode(w, r, &input) {
		return
	}
	store, err := s.store(input.MacAddress)
	if err != nil {
		writeError(w, err)
		return
	}
	output, err := store.Login(appstore.LoginInput{
		Email: input.Email, Password: input.Password, AuthCode: input.Code,
	})
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"account": output.Account})
}

func (s server) handleVersions(w http.ResponseWriter, r *http.Request) {
	if !s.authorize(w, r) {
		return
	}
	var input appRequest
	if !decode(w, r, &input) {
		return
	}
	store, account, app, err := input.resolve(s)
	if err != nil {
		writeError(w, err)
		return
	}
	output, err := store.ListVersions(appstore.ListVersionsInput{
		Context: r.Context(), Account: account, App: app, Platform: appstore.PlatformIPhone,
	})
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"versions": output.ExternalVersionIdentifiers,
		"latest":   output.LatestExternalVersionID,
	})
}

func (s server) handleVersion(w http.ResponseWriter, r *http.Request) {
	if !s.authorize(w, r) {
		return
	}
	var input appRequest
	if !decode(w, r, &input) {
		return
	}
	store, account, app, err := input.resolve(s)
	if err != nil {
		writeError(w, err)
		return
	}
	output, err := store.GetVersionMetadata(appstore.GetVersionMetadataInput{
		Context: r.Context(), Account: account, App: app,
		VersionID: input.VersionID, Platform: appstore.PlatformIPhone,
	})
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"displayVersion": output.DisplayVersion,
		"releaseDate":    output.ReleaseDate.Format(time.RFC3339),
	})
}

func (s server) handleDownload(w http.ResponseWriter, r *http.Request) {
	if !s.authorize(w, r) {
		return
	}
	var input appRequest
	if !decode(w, r, &input) {
		return
	}
	store, account, app, err := input.resolve(s)
	if err != nil {
		writeError(w, err)
		return
	}

	dir, err := os.MkdirTemp(s.cache, "download-")
	if err != nil {
		writeError(w, err)
		return
	}
	defer os.RemoveAll(dir)
	destination := filepath.Join(dir, "app.ipa")

	download := func() (appstore.DownloadOutput, error) {
		return store.Download(appstore.DownloadInput{
			Context: r.Context(), Account: account, App: app, OutputPath: destination,
			Progress: progressbar.NewOptions64(1, progressbar.OptionSetWriter(io.Discard)),
			ExternalVersionID: input.VersionID, Platform: appstore.PlatformIPhone,
		})
	}

	out, err := download()
	if errors.Is(err, appstore.ErrLicenseRequired) {
		if perr := store.Purchase(appstore.PurchaseInput{
			Account: account, App: app, Platform: appstore.PlatformIPhone,
		}); perr != nil && !errors.Is(perr, appstore.ErrLicenseAlreadyExists) {
			writeError(w, perr)
			return
		}
		out, err = download()
	}
	if err != nil {
		writeError(w, err)
		return
	}

	if serr := store.ReplicateSinf(appstore.ReplicateSinfInput{
		Sinfs: out.Sinfs, PackagePath: out.DestinationPath,
	}); serr != nil {
		writeError(w, serr)
		return
	}

	file, err := os.Open(out.DestinationPath)
	if err != nil {
		writeError(w, err)
		return
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		writeError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Set("Content-Length", strconv.FormatInt(info.Size(), 10))
	w.Header().Set("X-IPA-Version", app.Version)
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, file)
}

func main() {
	address := os.Getenv("IPA_SERVER_ADDRESS")
	if address == "" {
		address = ":8080"
	}
	cache := os.Getenv("IPA_SERVER_CACHE")
	if cache == "" {
		base, err := os.UserCacheDir()
		if err != nil {
			base = os.TempDir()
		}
		cache = filepath.Join(base, "ipa-server")
	}
	if err := os.MkdirAll(cache, 0o700); err != nil {
		log.Fatalf("cache directory: %v", err)
	}

	srv := server{token: os.Getenv("IPA_SERVER_TOKEN"), cache: cache}
	if srv.token == "" {
		log.Println("warning: IPA_SERVER_TOKEN is empty; the server accepts unauthenticated requests")
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{"ok": true})
	})
	mux.HandleFunc("POST /v1/login", srv.handleLogin)
	mux.HandleFunc("POST /v1/versions", srv.handleVersions)
	mux.HandleFunc("POST /v1/version", srv.handleVersion)
	mux.HandleFunc("POST /v1/download", srv.handleDownload)

	httpServer := &http.Server{
		Addr:              address,
		Handler:           mux,
		ReadHeaderTimeout: 15 * time.Second,
	}
	log.Printf("ipa server listening on %s (cache %s)", address, cache)
	if err := httpServer.ListenAndServe(); err != nil {
		log.Fatalf("server: %v", err)
	}
}
