package main

import (
    "net/http"
    "net/http/httptest"
    "strings"
    "testing"
)

func TestHealthz(t *testing.T) {
    req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
    w := httptest.NewRecorder()
    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        health(w, r)
    })
    handler.ServeHTTP(w, req)
    if w.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", w.Code)
    }
}

func TestExampleCompatJSON(t *testing.T) {
    req := httptest.NewRequest(http.MethodGet, "/v1/compatibility/example", nil)
    w := httptest.NewRecorder()
    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        exampleCompat(w, r)
    })
    handler.ServeHTTP(w, req)
    if w.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", w.Code)
    }
    body := w.Body.String()
    if !strings.Contains(body, `"class_"`) || !strings.Contains(body, `"SAFE"`) {
        t.Fatalf("unexpected body: %s", body)
    }
}
