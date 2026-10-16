package main

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/majd/ipatool/v2/pkg/appstore"
)

func TestClassifyMapsErrorCodes(t *testing.T) {
	cases := map[error]string{
		appstore.ErrAuthCodeRequired:     "code_required",
		appstore.ErrLicenseRequired:      "license_required",
		appstore.ErrPasswordTokenExpired: "token_expired",
		appstore.ErrAppNotFound:          "not_found",
		context.Canceled:                 "cancelled",
		errors.New("boom"):               "other",
	}
	for err, code := range cases {
		if got := classify(err).Code; got != code {
			t.Errorf("classify(%v).Code = %q, want %q", err, got, code)
		}
	}
}

func TestSessionsExpireAndCap(t *testing.T) {
	s := newSessions()
	s.put("a", nil)
	if s.get("a") == nil {
		t.Fatal("session a should be present")
	}
	s.mu.Lock()
	s.byID["a"].lastUsed = time.Now().Add(-sessionTTL - time.Minute)
	s.mu.Unlock()
	if s.get("a") != nil {
		t.Error("session a should have expired")
	}
	for i := 0; i < maxSessions+10; i++ {
		s.put(strconv.Itoa(i), nil)
	}
	s.mu.Lock()
	size := len(s.byID)
	s.mu.Unlock()
	if size > maxSessions {
		t.Errorf("session count %d exceeds cap %d", size, maxSessions)
	}
}

func TestSessionsConcurrentAccess(t *testing.T) {
	s := newSessions()
	var wg sync.WaitGroup
	for i := 0; i < 64; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			id := strconv.Itoa(i % 8)
			s.put(id, nil)
			if live := s.get(id); live != nil {
				live.mu.Lock()
				live.mu.Unlock()
			}
		}(i)
	}
	wg.Wait()
}

func TestAuthorize(t *testing.T) {
	secured := server{token: "secret", sessions: newSessions()}
	rec := httptest.NewRecorder()
	if secured.authorize(rec, httptest.NewRequest("POST", "/v1/versions", nil)) {
		t.Error("missing token should be rejected")
	}
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("code = %d, want 401", rec.Code)
	}

	req := httptest.NewRequest("POST", "/v1/versions", nil)
	req.Header.Set("Authorization", "Bearer secret")
	if !secured.authorize(httptest.NewRecorder(), req) {
		t.Error("correct token should be accepted")
	}

	open := server{token: "", sessions: newSessions()}
	if !open.authorize(httptest.NewRecorder(), httptest.NewRequest("POST", "/x", nil)) {
		t.Error("empty-token server should accept requests")
	}
}

func TestLimitBodyRejectsOversized(t *testing.T) {
	handler := limitBody(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, err := io.ReadAll(r.Body); err != nil {
			http.Error(w, "too big", http.StatusRequestEntityTooLarge)
			return
		}
		w.WriteHeader(http.StatusOK)
	}))
	rec := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", strings.NewReader(strings.Repeat("a", 2<<20)))
	handler.ServeHTTP(rec, req)
	if rec.Code != http.StatusRequestEntityTooLarge {
		t.Errorf("code = %d, want 413", rec.Code)
	}
}

func TestRecoverPanicsReturns500(t *testing.T) {
	handler := recoverPanics(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		panic("boom")
	}))
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, httptest.NewRequest("GET", "/", nil))
	if rec.Code != http.StatusInternalServerError {
		t.Errorf("code = %d, want 500", rec.Code)
	}
}

func TestHandlerRejectsInvalidBody(t *testing.T) {
	s := server{token: "", cache: t.TempDir(), sessions: newSessions()}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/v1/versions", strings.NewReader("not json"))
	s.handleVersions(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Errorf("code = %d, want 400", rec.Code)
	}
}
