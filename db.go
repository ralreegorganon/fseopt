package fseopt

import (
	"encoding/xml"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"
)

type DB struct {
	*sqlx.DB
	FSEUserKey string
}

func (db *DB) Open(connectionString string) error {
	d, err := sqlx.Open("postgres", connectionString)
	if err != nil {
		return err
	}
	db.DB = d
	return nil
}

func (db *DB) GetAssignments() ([]*Assignment, error) {
	assignments := []*Assignment{}
	err := db.Select(&assignments, `
		select 
			*
		from 
			assignment
	`)
	if err != nil {
		return nil, err
	}
	return assignments, nil
}

func (db *DB) UpdateAssignments() error {
	c := &http.Client{
		Timeout: time.Second * 60,
	}

	assignments := map[int64]Assignment{}

	var icaos string

	err := db.Get(&icaos, `
		select string_agg(icao, '-' order by icao) from airport where state in ('Washington', 'Alaska') limit 1
	`)
	if err != nil {
		return err
	}

	urls := []string{
		"http://server.fseconomy.net/data?userkey=" + db.FSEUserKey + "&format=xml&query=icao&search=jobsto&icaos=" + icaos,
		"http://server.fseconomy.net/data?userkey=" + db.FSEUserKey + "&format=xml&query=icao&search=jobsfrom&icaos=" + icaos,
	}

	for _, url := range urls {
		resp, err := c.Get(url)
		if err != nil {
			return err
		}
		defer resp.Body.Close()
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return err
		}

		var to JobContainer
		err = xml.Unmarshal(body, &to)
		if err != nil {
			return err
		}

		for _, a := range to.Assignments {
			assignments[a.ID] = a
		}
	}

	txn, err := db.Begin()
	if err != nil {
		return err
	}

	_, err = txn.Exec("delete from assignment")
	if err != nil {
		txn.Rollback()
		return err
	}

	stmt, err := txn.Prepare(pq.CopyIn("assignment", "id", "to_icao", "from_icao", "amount", "unit_type", "commodity", "pay", "expires", "type", "pt_assignment", "aircraft_id"))
	if err != nil {
		txn.Rollback()
		return err
	}

	for _, a := range assignments {
		_, err = stmt.Exec(a.ID, a.ToIcao, a.FromIcao, a.Amount, a.UnitType, a.Commodity, a.Pay, a.Expires, a.Type, a.PtAssignment, a.AircraftID)
		if err != nil {
			txn.Rollback()
			return err
		}
	}

	_, err = stmt.Exec()
	if err != nil {
		txn.Rollback()
		return err
	}

	err = stmt.Close()
	if err != nil {
		txn.Rollback()
		return err
	}

	err = txn.Commit()
	if err != nil {
		txn.Rollback()
		return err
	}

	return nil
}

func (db *DB) GetAircraft() ([]*Aircraft, error) {
	aircraft := []*Aircraft{}
	err := db.Select(&aircraft, `
		select 
			*
		from 
			aircraft
	`)
	if err != nil {
		return nil, err
	}
	return aircraft, nil
}

func (db *DB) UpdateAircraft() error {
	c := &http.Client{
		Timeout: time.Second * 60,
	}

	aircraft := map[int64]Aircraft{}

	urls := []string{
		"https://server.fseconomy.net/data?userkey=" + db.FSEUserKey + "&format=xml&query=aircraft&search=makemodel&makemodel=Quest%20Kodiak",
		// "https://server.fseconomy.net/data?userkey=" + db.FSEUserKey + "&format=xml&query=aircraft&search=makemodel&makemodel=Eclipse%20500",
		// "https://server.fseconomy.net/data?userkey=" + db.FSEUserKey + "&format=xml&query=aircraft&search=makemodel&makemodel=Pilatus%20PC-12",
		// "https://server.fseconomy.net/data?userkey=" + db.FSEUserKey + "&format=xml&query=aircraft&search=makemodel&makemodel=Socata%20TBM%20850",
	}

	for _, url := range urls {
		resp, err := c.Get(url)
		if err != nil {
			return err
		}
		defer resp.Body.Close()
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return err
		}

		var to AircraftItems
		err = xml.Unmarshal(body, &to)
		if err != nil {
			return err
		}

		for _, a := range to.Aircraft {
			aircraft[a.SerialNumber] = a
		}
	}

	txn, err := db.Begin()
	if err != nil {
		return err
	}

	_, err = txn.Exec("delete from aircraft")
	if err != nil {
		txn.Rollback()
		return err
	}

	stmt, err := txn.Prepare(pq.CopyIn("aircraft", "serial_number", "make_model", "registration", "owner", "location", "home", "equipment", "rental_dry", "rental_wet", "rental_type", "bonus", "rented_by", "fuel_pct", "needs_repair", "airframe_time", "engine_time", "time_last_100hr"))
	if err != nil {
		txn.Rollback()
		return err
	}

	for _, a := range aircraft {
		_, err = stmt.Exec(a.SerialNumber, a.MakeModel, a.Registration, a.Owner, a.Location, a.Home, a.Equipment, a.RentalDry, a.RentalWet, a.RentalType, a.Bonus, a.RentedBy, a.FuelPct, a.NeedsRepair, a.AirframeTime, a.EngineTime, a.TimeLast100hr)
		if err != nil {
			txn.Rollback()
			return err
		}
	}

	_, err = stmt.Exec()
	if err != nil {
		txn.Rollback()
		return err
	}

	err = stmt.Close()
	if err != nil {
		txn.Rollback()
		return err
	}

	err = txn.Commit()
	if err != nil {
		txn.Rollback()
		return err
	}

	return nil
}
