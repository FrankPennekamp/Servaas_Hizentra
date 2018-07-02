/* Bereken populatie, leeftijd, korter dan 180 dagen per patient */
/*%let rapportagedatum = '31mar2015'd;*/

proc datasets lib = work nolist;
	delete rapport_b;
quit; 

options missing='';
title;

/*%put &rapportagedatum;*/

data in_scope;
	length rapportage_indicatie _rapportage_indicatie wrd $ 200;	
	set hiz.stopdatums;	

	jaar = year(datumAanmelding);
	kwartaal = qtr(datumAanmelding);

	/*
		t2 = toedieningsadvies;
		toedieningsadvies = prxchange("s/(.*) keer per (.*) dagen/$2 keer per $1 dagen/i", -1, t2);
	*/
	/*	if not(receptVanaf le &rapportagedatum le receptEind);*/
	/*		if receptVanaf le &rapportagedatum le receptEind;*/

	call missing(rapportage_indicatie);

	/*	Hypogammaglobulinemie*/
	_rapportage_indicatie = strip(indicatie) || ' ' || strip(indicatieIndienOverig);
	do i = 1 to 10 while (scan(_rapportage_indicatie, i) ne '');
		wrd = scan(_rapportage_indicatie, i);
		if length(wrd) > 6 then do;
			if lowcase(substr(strip(wrd), 1, 7)) eq 'hypogam' then wrd = 'hypogammaglobulinemie';
			if lowcase(strip(wrd)) in ( 'hypogqmmaglobulinemie', 'hypohammaglobulinemie', 'hypoimmunoglobun‚mie', 
			'hypoimmunoglobun‚mie', 'hyppogammaglobunemie', 'hyppogammaglobunemie' )then wrd = 'hypogammaglobulinemie';
		end;
		rapportage_indicatie = strip( strip(rapportage_indicatie) || ' ' || wrd);
	end;

	/* LEEFTIJD OP STARTDATUM !!!! */
	leeftijd_op_startdatum = intck('year', geboortedatum, datumAanmelding);

	%leeftijd_naar_staffel(leeftijd_op_startdatum); /* Geeft leeftijd_staffel */
	leeftijd_staffel_startdatum = leeftijd_staffel; /* Om maar geen neveneffecten te hebben van de invoering van de macro */

	if &rapportdatum - datumAanmelding le 180 then minder_dan_zes_maanden = 1;
	else minder_dan_zes_maanden = 0;

	if missing(geslacht) then gesl = 'O'; 
	gesl = upcase(substr(strip(geslacht),1,1));
	if missing(gesl) then gesl = 'O'; 

	if missing(gewicht) then gewicht_staffel = 'gewicht onbekend';
	else if gewicht le 50 then gewicht_staffel = 'gewicht 00 - 50';
	else gewicht_staffel = 'gewicht 50+';
	

	%advies_naar_freq_per_dag; /* Geeft freq_per_dag uit toedieningsadvies */

	dagen_tussen = 1 / freq_per_dag;
	if missing(regio) then regio = 'Onbekend';
	if not missing(hizentra_ml) and not missing(freq_per_dag) then do;
		dagdosering = hizentra_ml * freq_per_dag;
	end;
	else call missing(dagdosering);

	*keep ecpid leeftijd_staffel gesl gewicht_staffel regio minder_dan_zes_maanden 
		 dagdosering rapportage_indicatie jaar kwartaal toedieningsadvies datumAanmelding;
run;

%macro maak_rapport_block(onderwerp, extra=);
proc summary data = in_scope nway missing;	
	class &onderwerp jaar kwartaal;
	var minder_dan_zes_maanden dagdosering;
	output out = rapb_&onderwerp (rename = (_freq_ = pats &onderwerp = onderwerp) drop = _type_) 
		sum(minder_dan_zes_maanden)=sum_minder_dan_zes_maanden
		mean(dagdosering)=gem_dagdosering;
quit;

data rapb_&onderwerp;
	length rapportdeel onderwerp $ 30;
	set rapb_&onderwerp;
	rapportdeel = "&onderwerp";
run;

proc append base=rapport_b new=rapb_&onderwerp force;
quit;
%mend maak_rapport_block;

proc datasets lib = work nolist; delete rapb_: ; quit;

/* Eerst degene met twee levels.. */
/*proc summary data = in_scope nway;*/
/*	class indicatie indicatieindienoverig jaar kwartaal;*/
/*	var minder_dan_zes_maanden dagdosering;*/
/*	output out = rapport_b_indicatie (rename = (_freq_ = pats indicatie = onderwerp) drop = _type_) */
/*		sum(minder_dan_zes_maanden)=sum_minder_dan_zes_maanden*/
/*		mean(dagdosering)=gem_dagdosering;*/
/*quit;*/
/**/
data rapport_b;
	length rapportdeel $ 30 onderwerp $ 30
		jaar kwartaal pats sum_minder_dan_zes_maanden gem_dagdosering 8;
	stop;
run;

/* Plak de rest er aan vast */

%maak_rapport_block(leeftijd_staffel_startdatum);
%maak_rapport_block(gesl);
%maak_rapport_block(rapportage_indicatie);
%maak_rapport_block(gewicht_staffel);
%maak_rapport_block(regio);
%maak_rapport_block(zone);
 

proc datasets lib = work nolist;
	modify rapport_b;
	format gem_dagdosering commax10.4;
quit;

/**/
/*proc sql;*/
/*	create table a as select distinct toedieningsadvies from hiz.stopdatums;*/
/*quit;*/
/************************************ DEEL 2 ***********************************************/
data rapport_B_deel2;
	set in_scope;
	geboortejaar = year(geboortedatum);
	keep ecpid gesl geboortejaar  gewicht dagen_tussen rapportage_indicatie datumAanmelding zone;
run;

proc sort data = rapport_B_deel2 nodup;
	by ecpid;
quit;

proc datasets lib = work nolist;
	modify rapport_B_deel2;
	format gewicht commax10.1;
quit;
