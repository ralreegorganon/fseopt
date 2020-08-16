with 
assignments_and_locations as
(
	select
		id,
		from_icao,
		to_icao,
		pay,
		amount,
		unit_type,
		type,
		pt_assignment,
		round(st_distance(f.the_geog, t.the_geog) / 1852) distance,
		mod(round(degrees(st_azimuth(f.the_geog, t.the_geog)))::integer+360, 360) bearing,
		f.the_geog from_geog,
		t.the_geog to_geog
	from
		assignment a
		inner join airport f
			on a.from_icao = f.icao
		inner join airport t
			on a.to_icao = t.icao
	where
		1=1
--		and unit_type = 'passengers'
		and type != 'All-In'
),
ac as
(
	select
		a.make_model,
		r.from_icao,
		r.to_icao,
		r.distance,
		r.bearing,
		round(((st_distance(r.from_geog, aa.the_geog) - st_distance(r.to_geog, aa.the_geog)) / 1852 / 100 * a.bonus)) flight_bonus,
		r.pay,
		r.amount,
		r.unit_type,
		a.registration,
		a.home,
		a.rental_dry,
		a.rental_wet,
		a.fuel_pct,
		a.bonus,
		r.type,
		r.pt_assignment,
		round(st_distance(r.from_geog, aa.the_geog) / 1852) before_distance,
		round(st_distance(r.to_geog, aa.the_geog) / 1852) after_distance,
		s.cost_per_nm as cost_per_mile,
		s.cruise,
		s.max_pax,
		s.cargo_25,
		s.cargo_100
	from 
		assignments_and_locations r
		inner join aircraft a
			on a.location = r.from_icao
		inner join airport aa
			on a.home = aa.icao 
		inner join aircraft_stat s
			on a.make_model = s.make_model
	where
		a.needs_repair = 0
		and (a.rental_dry > 0 or a.rental_wet > 0)
		and rented_by = 'Not rented.'
		and equipment = 'IFR/AP/GPS'
		and 
		(
			(
				amount <= s.max_pax
				and unit_type = 'passengers'
			)
			or
			(
				amount <= s.cargo_25
				and unit_type = 'kg'
			)
		)
),
mathed as
(
	select
		make_model,
		registration,
		from_icao,
		to_icao,
		distance,
		cruise,
		round(distance * cost_per_mile) as est_fuel_cost,
		round(distance/cruise * 60) as est_minutes,
		round(distance/cruise * rental_wet) as est_wet,
		round(distance/cruise * rental_dry + distance*cost_per_mile) as est_dry,
		round(fuel_pct * 100) as fuel_pct,
		flight_bonus,
		pay,
		amount,
		unit_type,
		type,
		pt_assignment,
		max_pax,
		cargo_25,
		cargo_100,
		home,
		before_distance,
		after_distance
	from ac
),
rental as
(
	select
		make_model,
		registration,
		from_icao,
		to_icao,
		distance,
		cruise,
		est_minutes,
		fuel_pct,
		case 
			when est_wet = 0 then est_dry
			when est_wet < est_dry then est_wet 
			else est_dry
		end rental_cost,
		case 
			when est_wet = 0 then 'dry'
			when est_wet < est_dry then 'wet' 
			else 'dry'
		end rental_type,
		flight_bonus,
		pay,
		amount,
		unit_type,
		type,
		pt_assignment,
		max_pax,
		cargo_25,
		cargo_100,
		home,
		before_distance,
		after_distance
	from 
		mathed
),
trip as
(
	select
		make_model,
		registration,
		from_icao,
		to_icao,
		distance,
		cruise,
		est_minutes,
		fuel_pct,
		-1*rental_cost + flight_bonus as route_net,
		pay,
		amount,
		unit_type,
		sum(pay) over (partition by make_model, registration, from_icao, to_icao, type, unit_type) as total_pay,
		sum(amount) over (partition by make_model, registration, from_icao, to_icao, type, unit_type) as total_amount,
		sum(case when pt_assignment = true then 1 else 0 end) over (partition by make_model, registration, from_icao, to_icao, type, unit_type) as pt_count,
		type,
		pt_assignment,
		max_pax,
		cargo_25,
		cargo_100,
		home,
		before_distance,
		after_distance
	from 
		rental
),
outcomes as
(
	select 
		make_model,
		registration,
		from_icao,
		to_icao,
		distance,
		cruise,
		est_minutes,
		fuel_pct,
		type,
		pt_assignment,
		route_net,
		pay,
		amount,
		unit_type,
		total_pay,
		total_amount,
		max_pax,
		cargo_25,
		cargo_100,
		pt_count,
		home,
		before_distance,
		after_distance,
		round(pay * 0.9 + route_net) as worst_net,
		round(total_pay * 0.9 + route_net - (case when pt_count > 5 then total_pay * 0.01 * pt_count - 5 else 0 end)) as best_net,
		round((pay * 0.9 + route_net) / greatest(1, est_minutes) * 60) as worst_net_hourly,
		round((total_pay * 0.9 + route_net - (case when pt_count > 5 then total_pay * 0.01 * pt_count - 5 else 0 end)) / greatest(1, est_minutes) * 60) as best_net_hourly
	from 
		trip
)
select * from outcomes
where 
1=1
--and make_model = 'Fairchild C119'
--and from_icao = 'PASV' and to_icao = 'PANC'
--and distance < 300
--and distance > 30
--and total_pay > 4000
--and from_icao = 'PAKN'
--and make_model = 'Quest Kodiak'
--and total_amount <= max_pax
--and est_minutes < 20
--and best_net_hourly > 3000
and unit_type = 'kg'
and total_amount <= cargo_100
order by best_net desc