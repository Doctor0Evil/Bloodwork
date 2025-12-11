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

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", health)
	mux.HandleFunc("/v1/compatibility/example", exampleCompat)

	// Calibration discovery endpoints (stubs/proxies)
	mux.HandleFunc("/calibration/descriptor", calDescriptor)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"registry_label":"Minimal-BodyTrack-Biosense-Calibration-Grid","registry_version":"1.0.0","compliance_tag":"ISO13485-CAL-READY"}`))
	})

	mux.HandleFunc("/calibration/device-families", deviceFamilies)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[]`))
	})

	mux.HandleFunc("/calibration/bodytrack-profiles", bodytrackProfiles)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[]`))
	})

	mux.HandleFunc("/calibration/biosense-profiles", biosenseProfiles)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[]`))
	})

	mux.HandleFunc("/calibration/logistics-profiles", logisticsProfiles)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[]`))
	})

	log.Println("Go gateway on :8090")
	log.Fatal(http.ListenAndServe(":8090", mux))
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

func calDescriptor(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`{"registry_label":"Minimal-BodyTrack-Biosense-Calibration-Grid","registry_version":"1.0.0","compliance_tag":"ISO13485-CAL-READY"}`))
}

func deviceFamilies(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`[]`))
}

func bodytrackProfiles(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`[]`))
}

func biosenseProfiles(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`[]`))
}

func logisticsProfiles(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`[]`))
}
