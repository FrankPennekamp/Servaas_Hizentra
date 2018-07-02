proc sql;
	create table stoppers_dit_kwartaal as 
	select
		s.ecpid,
		s.stopdatum,
		s.stopreden length = 2,
		red.omschrijving,
		s.stopreden_details
	from
		hiz.stoppers as s
			left join hiz.stopredenen as red
				on s.stopreden = red.stopreden
	where
		stopdatum between intnx('qtr', &rapportdatum., 0, 'B')  and &rapportdatum.
	order by 
		1;
quit;

