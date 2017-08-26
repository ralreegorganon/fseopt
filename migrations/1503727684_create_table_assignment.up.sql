create table assignment
(
    id int not null,
    to_icao character varying, 
    from_icao character varying,
    amount int,
    unit_type character varying,
    pay real, 
    type character varying,
    constraint assignment_pkey primary key (id)
);