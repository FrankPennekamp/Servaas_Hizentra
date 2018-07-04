proc sort data = hiz.pompdata;
	by klant maand;
quit;

proc sql;
	create table pompdata_summed as
	select distinct
		klant,
		datepart(maand) as maand format = date9.,
		sum(dagen) as dagen 
	from
		hiz.pompdata
	group by 1,2
	order by 1,2;
quit;
		

data stopdata_pompdata;
	set pompdata_summed;
	by klant maand;	
	retain first_pomp_seen ;
	if first.klant then do;
		first_pomp_seen = maand;
	end;
	format stopdatum first_pomp_seen date9. ;
	stopdatum = maand + dagen - 1 ;
	if last.klant;
	* keep klant stopdatum dagen;
run;

		
/* Stopdata combineren !! */
proc sql;
	create table stopdata_combined as 
	select 
		stopdata_pompdata.klant,
		stopdata_pompdata.stopdatum as stopdatum_pomp format = date9.,
		stopdata_pompdata.first_pomp_seen,
		stopdata_pompdata.maand,
		stopdata_pompdata.dagen
/*		, stopdata_toebehoren.stopdatum as stopdatum_toebehoren format = date9.*/
	from
		stopdata_pompdata 
/*			left join stopdata_toebehoren*/
/*				on stopdata_pompdata.klant = stopdata_toebehoren.klant*/
;
quit;

data stopdata_final;
	set stopdata_combined;
	format hci_stopdatum date9.;
	if stopdatum_pomp < &rapportdatum 
/*		or  stopdatum_toebehoren + &stopdatum_uitloop_periode < &rapportdatum */
	then do;
/*		hci_stopdatum = min(stopdatum_pomp, stopdatum_toebehoren);*/
		hci_stopdatum = stopdatum_pomp;
	end;
	else call missing(hci_stopdatum);
run;


/************* STOPDATA PATIENTEN ***************/
proc sql;
	create table stop_hizentra as 
	select distinct
		rits.ecpid,
		rits.klant,
		stoppers.stopdatum,
		stoppers.stopreden,
		max(contact.datumcontact) as datumcontact format = date9.
	from
		rits left join hiz.stoppers stoppers
			on rits.ecpid = stoppers.ecpid
		left join hiz.zorgcontacten contact
			on rits.ecpid = contact.ecpid
	group by 1;
quit;

%nodub(stop_hizentra, ecpid);

proc sql;
	create table stopdatums as 
	select distinct 
		stop_hizentra.*,
		stopdata_final.*,
		pat.*,
		regio.regio
	from
		stop_hizentra left join stopdata_final
			on stop_hizentra.klant = stopdata_final.klant
		left join hiz.patienten pat
			on stop_hizentra.ecpid = pat.ecpid
		left join hiz.pc_regio regio
			on (regio.postal_code = input(strip(pat.postcodeklant),  best.)
				or regio.postal_code =input(substr(strip(pat.postcodeklant),3), best.))
	order by ecpid, receptVanaf desc;
quit;

%nodub(stopdatums, ecpid);


data stopdatums_min_null;
	set stopdatums;
	by ecpid descending receptVanaf;
	if not first.ecpid AND missing(hizentra_ml) and missing(receptVanaf) then delete;

	if ecpid = 52375 and receptVanaf = '2sep2014'd then delete;

	/* In de eerste maand is het aantal dagen van de pomp niet goed !!  */
	if 
		( intnx('month', datumAanmelding, 0, 'b') =  intnx('month', stopdatum_pomp, 0, 'b')  /* datum aanmelding = eerste pompmaand */
			or ( maand = first_pomp_seen and stopdatum_pomp lt &rapportdatum))  /* meest recente maand = eerste pompmaand */

and missing(stopdatum) and patientStatus = 'actief' then do;
		*if datumAanmelding + dagen >  &rapportdatum  then do;
			*output;
/*if ( maand = first_pomp_seen and stopdatum_pomp lt &rapportdatum) then put ecpid datumaanmelding klant stopdatum_pomp maand date.;*/
			call missing(stopdatum_pomp, hci_stopdatum);
			stopdatum_pomp = &rapportdatum;
		*end;
	end;

	/* Er zijn ook twee gevallen waarbij startdatum = eind augustus*/
	if ecpid in (143875, 143878) and datumAanmelding = '31aug2015'd and patientStatus = 'actief' then do;
		if missing(stopdatum) then do;
			*output;			
			call missing(stopdatum_pomp, hci_stopdatum);
			stopdatum_pomp = &rapportdatum;
		end;
	end;

	if ecpid = 73846 and patientStatus = 'inactief' then stopdatum = '31dec2015'd;
	
run;


%nodub(stopdatums_min_null, ecpid);
		

proc sql;
	create table stopdatums_reden as 
	select 
		stopdatums.*,
		stopredenen.omschrijving
	from
		stopdatums_min_null stopdatums left join hiz.stopredenen
			on stopdatums.stopreden = stopredenen.stopreden
	order by ecpid;;
quit;

/* Omzetten postcode naar zone */
data stopdatums_reden_zone;
	set stopdatums_reden;
	length zone $ 10;

	if missing(postcodeKlant) then nw_pc = strip(postcodeZiekenhuis);
	else if length( compress(postcodeKlant, '- ')) > 5 /* nl klanten */ or 
		upcase(substr(strip(postcodeKlant),1,1)) = 'L' /* luxemburg klanten */
		then nw_pc = strip(postcodeZiekenhuis);
	else do;
		nw_pc = coalescec(strip(postcodeKlant), strip(postcodeZiekenhuis));
	end;
	* nw_pc = strip( postcodeKlant);
	nw_pc = compress(nw_pc, '- ');
	if upcase(substr(nw_pc,1,1)) = 'B' then do;
		nw_pc = substr(nw_pc,2);
	end;
	if upcase(substr(nw_pc,1,1)) = 'L' then do;
		call missing(nw_pc);
	end;
	if length(nw_pc) > 4 then do;
		call missing(nw_pc);
	end;
	nw_pc_num = input(nw_pc, best.);

	if (1000 le nw_pc_num le 1299) or (3000 le nw_pc_num le 3499) then do;
		zone = 'Brussel'; zone_afk = 'BR';
	end;
	else if (1500 le nw_pc_num le 1999) 
			or (2000 le nw_pc_num le 2999) 
			or (3500 le nw_pc_num le 3999) 
			or (8000 le nw_pc_num le 9999) then do;
		zone = 'Vlaanderen'; zone_afk = 'VL';
	end;
	else if (1300 le nw_pc_num le 1499) 
		or (4000 le nw_pc_num le 7999) then do;
		zone = 'Walonie'; zone_afk = 'WA';
	end;

	drop nw_pc nw_pc_num;
run;

/*proc sql; select count(*) as aantal from stopdatums_reden_zone where missing(zone); quit;


*/


data hiz.stopdatums;
	set stopdatums_reden_zone;
	format stopdatum_final date9.;
	length leeftijd_staffel leeftijd_staffel_startdatum gewicht_staffel $ 16;
	if not missing(stopdatum) then do;
		if stopdatum_pomp < datumAanmelding then stopdatum_final = stopdatum;
		else stopdatum_final = min(stopdatum, stopdatum_pomp);
	end;
	else do;
/*		stopdatum_final = min(stopdatum_pomp, stopdatum_toebehoren);*/
		stopdatum_final = stopdatum_pomp;
	end;

	/* Als de pomp voor het eerst verschijnt in de rapportagemaand, neem dan deze hele maand mee! */


	stopjaar = year(stopdatum_final);
	stopkwartaal = qtr(stopdatum_final);
	stopjaarkwartaal = put(stopdatum_final, yyq10.);
	leeftijd_op_stopdatum = intck('year', geboortedatum, stopdatum_final);

	/* Leeftijd op STARTDATUM */
	%leeftijd_naar_staffel(leeftijd_op_startdatum); /* geeft leeftijd_staffel */
	leeftijd_staffel_startdatum = leeftijd_staffel;

	/* Leeftijd op STOPDATUM */
	%leeftijd_naar_staffel(leeftijd_op_stopdatum); /* geeft leeftijd_staffel */
	

	leeftijd_op_startdatum = intck('year', geboortedatum, datumAanmelding);
	if 0 le leeftijd_op_startdatum le 3 then leeftijd_staffel_startdatum2  = 'lft 00 - 03';
	else if  4 le leeftijd_op_startdatum le  6 then leeftijd_staffel_startdatum2  = 'lft 04 - 06';
	else if  7 le leeftijd_op_startdatum le 12 then leeftijd_staffel_startdatum2  = 'lft 07 - 12';
	else if 13 le leeftijd_op_startdatum le 17 then leeftijd_staffel_startdatum2  = 'lft 13 - 17';
	else if 18 le leeftijd_op_startdatum le 25 then leeftijd_staffel_startdatum2  = 'lft 18 - 25';
	else if 26 le leeftijd_op_startdatum le 40 then leeftijd_staffel_startdatum2  = 'lft 26 - 40';
	else if 41 le leeftijd_op_startdatum le 59 then leeftijd_staffel_startdatum2  = 'lft 41 - 59';
	else if 60 le leeftijd_op_startdatum le 70 then leeftijd_staffel_startdatum2  = 'lft 60 - 70';
	else if 71 le leeftijd_op_startdatum then leeftijd_staffel_startdatum2  = 'lft 71 - 99';
	else leeftijd_staffel_startdatum2 = 'lft onbekend';

	gesl = upcase(substr(strip(geslacht),1,1));

	if missing(gewicht) then gewicht_staffel = 'gewicht onbekend';
	else if gewicht le 50 then gewicht_staffel = 'gewicht 00 - 50';
	else gewicht_staffel = 'gewicht 50+';

	if stopreden = 'overstap naar andere medicatie/therapie' then 
		stopreden = 'switch';

	gebruik_periode = stopdatum_final - datumaanmelding;
run;

%nodub(hiz.stopdatums, ecpid);

proc sql;
	delete from hiz.stopdatums where ecpid = 55329 and receptVanaf = '11mar2013'd;
	delete from hiz.stopdatums where ecpid = 55501 and missing(toedieningsadvies);
	delete from hiz.stopdatums where ecpid = 139474 and receptVanaf = '01jul2015'd;
	delete from hiz.stopdatums where ecpid = 165624 and missing(toedieningsadvies);
quit;

%nodub(hiz.stopdatums, ecpid);


/*
	Alleen Belgische patienten
*/


proc sql;
	create table pc_non_belgie as 
	select 
		ecpid, 
		postcodeKlant , 
		lengthn( strip(postcodeKlant)) as a
	from 
		hiz.stopdatums
	where 
		length(strip(postcodeKlant)) ne 4
			and not(  prxmatch('/b\d{4}/', lowcase( compress(postcodeKlant, '- ') )  
								) 
					) 
				;
quit; 


proc sql;
	delete from hiz.stopdatums 
	where ecpid in (select distinct ecpid from pc_non_belgie) ;
quit;


/*
	Sommige voorschrijvers verwijderen. 
*/
data hiz.stopdatums_min_2;
	set hiz.stopdatums;
run;


proc sql noprint;
	delete from hiz.stopdatums_min_2
	where ecpid in ( 
		select distinct 
			pat.ecpid 
		from 
			hiz.patienten as pat 
				inner join hiz.voorschrijvers_exclude as excl 
					on pat.voorschrijver = excl.voorschrijver
		) 
	;
quit;
/*
proc compare 
		base=hiz.stopdatums_rapporta 
		comp=hiz.stopdatums outbase outcomp outdiff outnoequal out=papa;
	id ecpid; 
quit;
*/

