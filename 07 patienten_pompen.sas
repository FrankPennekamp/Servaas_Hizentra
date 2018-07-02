
/* Belangrijk gegeven: Gamma norm patienten !! */
proc sql;
	delete from hiz.pompdata  
	where klant in ('K40820', 'K57756', 'K57951', 'K61396', 'K63760', 'K65595');
quit;


/* patienten en pompen */
proc sql;
	create table patienten_pompen as
	select distinct 
		patienten.ecpid,
		patienten.geslacht,
		patienten.postcodeklant,
		patienten.geboortedatum,
		pompdata.klant,
		pompdata.postcode,
		pompdata.land
	from
		hiz.patienten left join hiz.pompdata 
			on ((lowcase(patienten.geslacht) = lowcase(pompdata.geslacht)
					or patienten.geslacht = 'onbekend'
)
				and (  not missing(patienten.geboortedatum)  
						and patienten.geboortedatum = pompdata.geboortedatum)
				and (

						strip(patienten.postcodeklant) = strip(substr(pompdata.postcode, 3))
						or strip(substr(patienten.postcodeklant,3)) = strip(substr(pompdata.postcode, 3))))
	order by 6;
quit;

proc sql;
	delete from patienten_pompen where ecpid = 55394 and klant = 'K40602';
quit;

data patienten_pompen_match patienten_pompen_non_match;
	set patienten_pompen;
	if not missing(klant) then output patienten_pompen_match;
	else output patienten_pompen_non_match;
run;

/* patienten en pompen */
proc sql;
	create table patienten_pompen as
	select distinct 
		patienten.ecpid,
		patienten.geslacht,
		patienten.postcodeklant,
		patienten.geboortedatum,
		pompdata.klant,
		pompdata.postcode,
		pompdata.land
	from
		patienten_pompen_non_match as patienten left join hiz.pompdata 
			on ((lowcase(patienten.geslacht) = lowcase(pompdata.geslacht)
					or patienten.geslacht = 'onbekend'
					or 1
)
				and (  not missing(patienten.geboortedatum) 
						and patienten.geboortedatum = pompdata.geboortedatum )
				and (

						strip(patienten.postcodeklant) = strip(substr(pompdata.postcode, 3))
						or strip(substr(patienten.postcodeklant,3)) = strip(substr(pompdata.postcode, 3))))
	order by 6;
quit;

data patienten_pompen_match_2 patienten_pompen_non_match;
	set patienten_pompen;
	if not missing(klant) then output patienten_pompen_match_2;
	else output patienten_pompen_non_match;
run;

/* patienten en pompen */
proc sql;
	create table patienten_pompen as
	select distinct 
		patienten.ecpid,
		patienten.geslacht,
		patienten.postcodeklant,
		patienten.geboortedatum,
		pompdata.klant,
		pompdata.postcode,
		pompdata.land
	from
		patienten_pompen_non_match as patienten left join hiz.pompdata 
			on ((lowcase(patienten.geslacht) = lowcase(pompdata.geslacht)
					or patienten.geslacht = 'onbekend'
)
				and ( not missing(patienten.geboortedatum) 
						and patienten.geboortedatum = pompdata.geboortedatum)
				and (
1 or				
						strip(patienten.postcodeklant) = strip(substr(pompdata.postcode, 3))
						or strip(substr(patienten.postcodeklant,3)) = strip(substr(pompdata.postcode, 3))))
	order by 6;
quit;

data patienten_pompen_match_3 patienten_pompen_non_match;
	set patienten_pompen;
	if not missing(klant) then output patienten_pompen_match_3;
	else output patienten_pompen_non_match;
run;

/* patienten en pompen */
proc sql;
	create table patienten_pompen as
	select distinct 
		patienten.ecpid,
		patienten.geslacht,
		patienten.postcodeklant,
		patienten.geboortedatum,
		pompdata.klant,
		pompdata.postcode,
		pompdata.land,
		pompdata.geboortedatum as geboortedatumpompen
	from
		patienten_pompen_non_match as patienten left join hiz.pompdata 
			on ((lowcase(patienten.geslacht) = lowcase(pompdata.geslacht)
					or patienten.geslacht = 'onbekend'
)
/*				and patienten.geboortedatum = pompdata.geboortedatum*/
				and (
				
						strip(patienten.postcodeklant) = strip(substr(pompdata.postcode, 3))
						or strip(substr(patienten.postcodeklant,3)) = strip(substr(pompdata.postcode, 3))))
	order by 6;
quit;

data patienten_pompen_match_4 patienten_pompen_non_match;
	set patienten_pompen;
	if not missing(klant) then output patienten_pompen_match_4;
	else output patienten_pompen_non_match;
run;

data patienten_pompen;
	set patienten_pompen_match
	    patienten_pompen_match_2
		patienten_pompen_match_3;
run;

%nodub(patienten_pompen, %str(ecpid));
