create table airport
(
    airport_id serial not null,
    icao character varying not null,
    name character varying not null,
    city character varying not null,
    state character varying not null,
    country character varying not null,
    latitude double precision not null,
    longitude double precision not null,
    the_geog geography(POINT,4326) not null,
    constraint position_pkey primary key (airport_id)
);
