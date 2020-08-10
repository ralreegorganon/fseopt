create table aircraft
(
    serial_number int not null,
    make_model character varying,
    registration character varying,
    owner character varying,
    location character varying,
    home character varying,
    equipment character varying,
    rental_dry real,
    rental_wet real,
    rental_type character varying,
    bonus real,
    rented_by character varying,
    fuel_pct real,
    needs_repair int,
    airframe_time character varying,
    engine_time character varying,
    time_last_100hr character varying,
    constraint aircraft_pkey primary key (serial_number)
);
