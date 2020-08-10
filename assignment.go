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

type AircraftItems struct {
	Aircraft []Aircraft `xml:"Aircraft"`
}

type Aircraft struct {
	SerialNumber  int64       `xml:"SerialNumber" json:"serialNumber" db:"serial_number"`
	MakeModel     null.String `xml:"MakeModel" json:"makeModel" db:"make_model"`
	Registration  null.String `xml:"Registration" json:"registration" db:"registration"`
	Owner         null.String `xml:"Owner" json:"owner" db:"owner"`
	Location      null.String `xml:"Location" json:"location" db:"location"`
	Home          null.String `xml:"Home" json:"home" db:"home"`
	Equipment     null.String `xml:"Equipment" json:"equipment" db:"equipment"`
	RentalDry     null.Float  `xml:"RentalDry" json:"rentalDry" db:"rental_dry"`
	RentalWet     null.Float  `xml:"RentalWet" json:"rentalWet" db:"rental_wet"`
	RentalType    null.String `xml:"RentalType" json:"rentalType" db:"rental_type"`
	Bonus         null.Float  `xml:"Bonus" json:"bonus" db:"bonus"`
	RentedBy      null.String `xml:"RentedBy" json:"rentedBy" db:"rented_by"`
	FuelPct       null.Float  `xml:"FuelPct" json:"fuelPct" db:"fuel_pct"`
	NeedsRepair   null.Int    `xml:"NeedsRepair" json:"needsRepair" db:"needs_repair"`
	AirframeTime  null.String `xml:"AirframeTime" json:"airframeTime" db:"airframe_time"`
	EngineTime    null.String `xml:"EngineTime" json:"engineTime" db:"engine_time"`
	TimeLast100hr null.String `xml:"TimeLast100hr" json:"timeLast100hr" db:"time_last_100hr"`
}
