/* Bereken populatie, leeftijd, korter dan 180 dagen per patient */
/*%let rapportagedatum = '31mar2015'd;*/

/* Let op: twee keer draaien.
	1. hiz.stopdatums_rapporta (dat is zonder twee doctoren)
	-> verander proc append	
	2. hiz.stopdatums (dat is MET die twee)
*/

/* We hebben het over twee input datasets, die voor 2 output datasets zorgen. */


proc datasets lib = work nolist;
	delete rapport_a rapport_amin_2;
quit; 


%macro maak_rapport_block(onderwerp, output=);
	proc summary data = in_scope&output. nway missing;
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

	proc append base=rapport_a&output new=rapport_a_&onderwerp force nowarn;
	quit;

%mend maak_rapport_block;


%macro maak_scope(output=);

	%if &output ne %then %let output2=_&output.;
	%else %let output2=&output.;

	data in_scope&output.;
		set hiz.stopdatums&output2.;

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
%mend maak_scope;

%macro run_datum(rapportagedatum);

	proc datasets lib = work nolist; 
		delete rapport_a_: ;
	quit;

	%maak_scope();
	%maak_scope(output=min_2);

	%maak_rapport_block(leeftijd_staffel);
	%maak_rapport_block(gesl);
	%maak_rapport_block(gewicht_staffel);
	%maak_rapport_block(regio);
	%maak_rapport_block(zone);
	%maak_rapport_block(leeftijd_staffel, output=min_2);
	%maak_rapport_block(gesl, output=min_2);
	%maak_rapport_block(gewicht_staffel, output=min_2);
	%maak_rapport_block(regio, output=min_2);
	%maak_rapport_block(zone, output=min_2);

%mend run_datum;

data _null_;
	length rundatums $ 32000;
	format rundatum date9.;
	startdatum = '31mar2012'd;
	rundatum = startdatum;
	do while (rundatum le &rapportdatum.);
		rundatums = strip(rundatums) || rundatum;
		rundatum = intnx('qtr', rundatum, 1, 'e');
		put rundatum=;
	end;
	call symput('rundatums', strip(rundatums));
run;


%macro rundats;
	%let i = 1;
	%do %while( %scan(&rundatums, &i) NE );
		%let rapportagedatum = %scan(&rundatums, &i);
		%let i = %eval(&i + 1);		
		%run_datum(&rapportagedatum.);
	%end;
%mend rundats;
%rundats;

