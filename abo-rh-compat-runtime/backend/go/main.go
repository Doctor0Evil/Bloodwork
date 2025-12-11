package main

import (
	"encoding/json"
	"log"
	"net/http"
)

type CompatibilityResult struct {
	Class    string `json:"class_"`
	ABOOk    bool   `json:"abo_ok"`
	RhOk     bool   `json:"rh_ok"`
	Rationale string `json:"rationale"`
}

func health(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
}

func exampleCompat(w http.ResponseWriter, _ *http.Request) {
	resp := CompatibilityResult{
		Class:    "SAFE",
		ABOOk:    true,
		RhOk:     true,
		Rationale: "ABO_COMPATIBLE",
	}
	_ = json.NewEncoder(w).Encode(resp)
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", health)
	mux.HandleFunc("/v1/compatibility/example", exampleCompat)
	log.Println("Go gateway on :8090")
	log.Fatal(http.ListenAndServe(":8090", mux))
}
