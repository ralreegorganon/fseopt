with
recursive
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
		case when type = 'Trip-Only' then 0 else row_number() over (order by type) end c,
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
		rental_type,
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
		type,
		c as special_type,
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
idassigned as
(
	select
		cast(row_number() over (order by registration, from_icao, to_icao, unit_type, amount) as varchar) as id,
		dense_rank() over (order by registration, from_icao, to_icao, special_type) as group_id,
		case when unit_type = 'kg' then amount else amount * 77 end as weight_cost,
		pay::numeric::money || ' / ' || amount || ' ' || unit_type || ' / ' || type as uniqueid,
		*
	from
		trip
),
builtlist(id, group_id, picked_items, picked_item_names, nr_items, total_weight, total_value, total_pt, total_pax, cargo_25, max_pax) as
(
	select
		id,
		group_id,
		ARRAY[id] as picked_items,
		ARRAY[uniqueid] as picked_item_names,
		1 as nr_items,
		weight_cost as total_weight,
		pay as total_value,
		case when pt_assignment = true then 1 else 0 end as total_pt,
		case when unit_type = 'passengers' then amount else 0 end as total_pax,
		cargo_25,
		max_pax
	from
		idassigned
	union all
	select
        i.id,
        i.group_id,
        picked_items || i.id,
        picked_item_names || i.uniqueid,
        nr_items + 1,
        weight_cost + total_weight,
        pay + total_value,
        case when pt_assignment = true then 1 else 0 end + total_pt,
        case when unit_type = 'passengers' then amount else 0 end + total_pax,
        i.cargo_25,
        i.max_pax
    from
    	idassigned i
    	inner join builtlist b
    		on i.group_id = b.group_id
    where
    	picked_items::varchar[] @> ARRAY[i.id] = false
        and weight_cost + total_weight <= i.cargo_25
        and case when unit_type = 'passengers' then amount else 0 end + total_pax <= i.max_pax
        and i.id > b.id
),
group_attributes as
(
	select
		group_id,
		rental_type,
		make_model,
		registration,
		from_icao,
		to_icao,
		distance,
		cruise,
		est_minutes,
		fuel_pct,
		route_net,
		max_pax,
		cargo_25,
		cargo_100,
		home,
		before_distance,
		after_distance
	from
		idassigned
	group by
		group_id,
		rental_type,
		make_model,
		registration,
		from_icao,
		to_icao,
		distance,
		cruise,
		est_minutes,
		fuel_pct,
		route_net,
		max_pax,
		cargo_25,
		cargo_100,
		home,
		before_distance,
		after_distance
),
optimized as
(
	select
		ga.rental_type,
		ga.make_model,
		ga.registration,
		ga.from_icao,
		ga.to_icao,
		b.total_weight,
		b.total_value as total_pay,
		b.total_pt,
		b.total_pax,
		ga.distance,
		ga.cruise,
		ga.est_minutes,
		ga.fuel_pct,
		ga.route_net,
		ga.max_pax,
		ga.cargo_25,
		ga.cargo_100,
		ga.home,
		ga.before_distance,
		ga.after_distance,
		b.picked_item_names
	from
		builtlist b
		inner join group_attributes ga
			on b.group_id = ga.group_id
),
outcomes as
(
	select
		*,
		round(total_pay * 0.9 + route_net - (case when total_pt > 5 then total_pay * 0.01 * total_pt - 5 else 0 end)) as best_net,
		round((total_pay * 0.9 + route_net - (case when total_pt > 5 then total_pay * 0.01 * total_pt - 5 else 0 end)) / greatest(1, est_minutes) * 60) as best_net_hourly
	from
		optimized
),
jsonsubset as
(
	select
		make_model,
		registration,
		rental_type,
		from_icao,
		to_icao,
		fuel_pct,
		distance,
		est_minutes,
		total_weight,
		total_pay,
		best_net,
		best_net_hourly,
		picked_item_names as assignments
	from
		outcomes
	where
		1=1
		--and make_model = 'Fairchild C119'
		--and from_icao = 'FAJS'
		--and to_icao = 'PANC'
		--and distance < 300
		--and distance > 30
		--and total_pay > 4000
		--and from_icao = 'PAKN'
		--and make_model = 'Quest Kodiak'
		--and total_amount <= max_pax
		and est_minutes < 30
		--and best_net_hourly > 3000
	order by
		best_net desc
	limit 20
)
select
	--json_agg(jsonsubset)
	*
from
	jsonsubset
