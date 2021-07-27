create table aircraft_stat
(
    make_model character varying,
    cost_per_nm real,
    cruise real,
    max_pax int,
    cargo_25 int,
    cargo_100 int,
    padding_minutes int,
    query boolean,
    constraint aircraft_stat_pkey primary key (make_model)
);

insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Quest Kodiak', 1.13, 180, 9, 1286, 641, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Eclipse 500', 0.82, 370, 5, 930, 467, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Pilatus PC-12', 0.9, 270, 10, 1545, 727, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Socata TBM 850', 0.84, 310, 6, 993, 389, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Douglas DC-3', 2.99, 140, 26, 3813, 2192, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('DeHavilland DHC-6 300 Twin Otter (Aerosoft Extended)', 1.43, 170, 19, 1946, 1035, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Fairchild C119', 2.65, 200, 65, 14048, 12838, 0, false);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Cessna 208 Caravan', 1.23, 182, 13, 1610, 941, 0, true);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Beechcraft King Air 350', 1.38, 258, 14, 2241, 1153, 0, true);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Socata TBM 930 (MSFS)', 0.76, 295, 7, 981, 392, 0, true);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Cessna Citation CJ4 (MSFS)', 1.67, 400, 10, 2443, 710, 0, true);
insert into aircraft_stat (make_model, cost_per_nm, cruise, max_pax, cargo_25, cargo_100, padding_minutes, query) values ('Cessna Citation Longitude', 2.31, 465, 8, 5406, 1052, 0, true);