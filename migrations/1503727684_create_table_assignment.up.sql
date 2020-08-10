create table assignment
(
    id int not null,
    to_icao character varying, 
    from_icao character varying,
    amount int,
    unit_type character varying,
    commodity character varying,
    pay real, 
    expires character varying,
    type character varying,
    pt_assignment boolean,
    aircraft_id int,
    constraint assignment_pkey primary key (id)
);