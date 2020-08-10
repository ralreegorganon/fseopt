package fseopt

import (
	"github.com/guregu/null"
)

type JobContainer struct {
	Assignments []Assignment `xml:"Assignment"`
}

type Assignment struct {
	ID           int64       `xml:"Id" json:"id" db:"id"`
	ToIcao       null.String `xml:"ToIcao" json:"toIcao" db:"to_icao"`
	FromIcao     null.String `xml:"FromIcao" json:"fromIcao" db:"from_icao"`
	Amount       null.Int    `xml:"Amount" json:"amount" db:"amount"`
	UnitType     null.String `xml:"UnitType" json:"unitType" db:"unit_type"`
	Commodity    null.String `xml:"Commodity" json:"commodity" db:"commodity"`
	Pay          null.Float  `xml:"Pay" json:"pay" db:"pay"`
	Expires      null.String `xml:"expires" json:"expires" db:"expires"`
	Type         null.String `xml:"Type" json:"type" db:"type"`
	PtAssignment null.String `xml:"PtAssignment" json:"ptAssignment" db:"pt_assignment"`
	AircraftID   null.String `xml:"AircraftId" json:"aircraftId" db:"aircraft_id"`
}
