package fseopt

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"
)

func CreateRouter(server *HTTPServer) (*mux.Router, error) {
	r := mux.NewRouter()
	m := map[string]map[string]HttpApiFunc{
		"GET": {
			"/api/assignments": server.GetAssignments,
			"/api/aircraft":    server.GetAircraft,
		},
		"POST": {
			"/api/assignments":                  server.UpdateAssignments,
			"/api/aircraft":                     server.UpdateAircraft,
			"/api/from-assignments-by-aircraft": server.FromAssignmentsByAircraft,
		},
		"PUT": {},
		"OPTIONS": {
			"": options,
		},
	}

	for method, routes := range m {
		for route, handler := range routes {
			localRoute := route
			localHandler := handler
			localMethod := method
			f := makeHttpHandler(localMethod, localRoute, localHandler)

			if localRoute == "" {
				r.Methods(localMethod).HandlerFunc(f)
			} else {
				r.Path(localRoute).Methods(localMethod).HandlerFunc(f)
			}
		}
	}

	return r, nil
}

func makeHttpHandler(localMethod string, localRoute string, handlerFunc HttpApiFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		writeCorsHeaders(w, r)
		if err := handlerFunc(w, r, mux.Vars(r)); err != nil {
			httpError(w, err)
		}
	}
}

func writeCorsHeaders(w http.ResponseWriter, r *http.Request) {
	w.Header().Add("Access-Control-Allow-Origin", "*")
	w.Header().Add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
	w.Header().Add("Access-Control-Allow-Methods", "GET, POST, DELETE, PUT, OPTIONS")
}

type HttpApiFunc func(w http.ResponseWriter, r *http.Request, vars map[string]string) error

type HTTPServer struct {
	DB *DB
}

func NewHTTPServer(db *DB) *HTTPServer {
	s := &HTTPServer{
		DB: db,
	}

	return s
}

func writeJSON(w http.ResponseWriter, code int, thing interface{}) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	val, err := json.Marshal(thing)
	w.Write(val)
	return err
}

func writeGeoJSON(w http.ResponseWriter, code int, thing []byte) {
	w.Header().Set("Content-Type", "application/vnd.geo+json")
	w.WriteHeader(code)
	w.Write(thing)
}

func writeJSONDirect(w http.ResponseWriter, code int, thing []byte) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	w.Write(thing)
}

func httpError(w http.ResponseWriter, err error) {
	statusCode := http.StatusInternalServerError

	if err != nil {
		log.WithField("err", err).Error("http error")
		http.Error(w, err.Error(), statusCode)
	}
}

func options(w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	w.WriteHeader(http.StatusOK)
	return nil
}

func (s *HTTPServer) GetAssignments(w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	assignments, err := s.DB.GetAssignments()

	if err != nil {
		return err
	}

	writeJSON(w, http.StatusOK, assignments)

	return nil
}

func (s *HTTPServer) UpdateAssignments(w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	err := s.DB.UpdateAssignments()

	if err != nil {
		return err
	}

	w.WriteHeader(http.StatusOK)

	return nil
}

func (s *HTTPServer) FromAssignmentsByAircraft(w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	err := s.DB.FromAssignmentsByAircraft()

	if err != nil {
		return err
	}

	w.WriteHeader(http.StatusOK)

	return nil
}

func (s *HTTPServer) GetAircraft(w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	aircraft, err := s.DB.GetAircraft()

	if err != nil {
		return err
	}

	writeJSON(w, http.StatusOK, aircraft)

	return nil
}

func (s *HTTPServer) UpdateAircraft(w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	err := s.DB.UpdateAircraft()

	if err != nil {
		return err
	}

	w.WriteHeader(http.StatusOK)

	return nil
}
