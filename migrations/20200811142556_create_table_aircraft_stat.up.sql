create table aircraft_stat
(
    make_model character varying,
    cost_per_nm real,
    cruise real,
    max_pax int,
    padding_minutes int,
    query boolean,
    constraint aircraft_stat_pkey primary key (make_model)
);

insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, padding_minutes, query) values ('Quest Kodiak', 1.13, 180, 9, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, padding_minutes, query) values ('Eclipse 500', 0.82, 370, 5, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, padding_minutes, query) values ('Pilatus PC-12', 0.9, 270, 10, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, padding_minutes, query) values ('Socata TBM 850', 0.84, 310, 6, 0, true);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, padding_minutes, query) values ('Douglas DC-3', 2.99, 140, 26, 0, false);