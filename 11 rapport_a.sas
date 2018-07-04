/* Bereken populatie, leeftijd, korter dan 180 dagen per patient */
/*%let rapportagedatum = '31mar2015'd;*/

/* Let op: twee keer draaien.
	1. hiz.stopdatums_rapporta (dat is zonder twee doctoren)
	-> verander proc append	
	2. hiz.stopdatums (dat is MET die twee)
*/


proc datasets lib = work nolist;
	delete rapport_a;
quit; 

%macro runit(rapportagedatum);
data in_scope;
	set hiz.stopdatums_rapporta;

	if datumAanmelding le &rapportagedatum le stopdatum_final;

	leeftijd_op_rapportagedatum = intck('year', geboortedatum, &rapportagedatum);
	%leeftijd_naar_staffel(leeftijd_op_rapportagedatum); /* geeft leeftijd_staffel */

	if &rapportagedatum - datumAanmelding le 180 then minder_dan_zes_maanden = 1;
	else minder_dan_zes_maanden = 0;
	
	if missing(gesl) then gesl = 'O';
	else gesl = upcase(substr(strip(geslacht),1,1));

	if missing(gewicht) then gewicht_staffel = 'gewicht onbekend';
	else if gewicht le 50 then gewicht_staffel = 'gewicht 00 - 50';
	else gewicht_staffel = 'gewicht 50+';

	%advies_naar_freq_per_dag; /* Geeft freq_per_dag */

	if not missing(hizentra_ml) and not missing(freq_per_dag) then do;
		dagdosering = hizentra_ml * freq_per_dag / 5;
	end;
	else call missing(dagdosering);

	if missing(regio) then regio = 'Onbekend';
	jaar = year(&rapportagedatum);
	kwartaal = qtr(&rapportagedatum);
	keep ecpid leeftijd_staffel gesl gewicht_staffel regio minder_dan_zes_maanden dagdosering jaar kwartaal hizentra_ml zone;
run;

%macro maak_rapport_block(onderwerp);
proc summary data = in_scope nway missing;
	class &onderwerp jaar kwartaal;
	var minder_dan_zes_maanden dagdosering;
	format dagdosering commax10.4;
	output out = rapport_a_&onderwerp (rename = (_freq_ = pats &onderwerp = onderwerp) drop = _type_) 
		sum(minder_dan_zes_maanden)=sum_minder_dan_zes_maanden
		mean(dagdosering)=gem_dagdosering;
quit;

data rapport_a_&onderwerp;
	length rapportdeel $ 30 onderwerp $ 16;	
	set rapport_a_&onderwerp;
	rapportdeel = "&onderwerp";
run;

proc append base=rapport_a new=rapport_a_&onderwerp force nowarn;
quit;

%mend maak_rapport_block;

proc datasets lib = work nolist; delete rapport_a_: ; quit;

%maak_rapport_block(leeftijd_staffel);
%maak_rapport_block(gesl);
%maak_rapport_block(gewicht_staffel);
%maak_rapport_block(regio);
%maak_rapport_block(zone);
%mend runit; 

/**/
%runit('31mar2012'd);
%runit('30jun2012'd);
%runit('30sep2012'd);
%runit('31dec2012'd);

%runit('31mar2013'd);
%runit('30jun2013'd);
%runit('30sep2013'd);
%runit('31dec2013'd);

%runit('31mar2014'd);
%runit('30jun2014'd);
%runit('30sep2014'd);
%runit('31dec2014'd);

%runit('31mar2015'd);
%runit('30jun2015'd);
%runit('30sep2015'd);
%runit('31dec2015'd);

%runit('31mar2016'd);
%runit('30jun2016'd);
%runit('30sep2016'd);
%runit('31dec2016'd);

%runit('31mar2017'd);
%runit('30jun2017'd);
%runit('30sep2017'd);
%runit('31dec2017'd);

%runit('31mar2018'd);
%runit('30jun2018'd);
* %runit('30sep2018'd);
* %runit('31dec2018'd);

/**/
/*proc sql;*/
/*	create table a as select distinct toedieningsadvies from hiz.stopdatums;*/
/*quit;*/
