/*data bestand_stoppers;*/
/*	set hiz.stopdatums ;*/
/*	where stopdatum_final lt &rapportdatum and not missing(stopdatum_final);*/
/*	keep ecpid stopjaarkwartaal stopreden datumaanmelding stopdatum_final;*/
/*run;*/


proc datasets lib=work nolist;
	delete rapport_C:;
quit;


data rapport_c;
	length rapportdeel $ 30 onderwerp $ 40
		stopjaar stopkwartaal pats gebruik_periode gem_gebr_periode 8;
	stop;
run;


%macro maak_rapport_block(onderwerp);

proc summary data = hiz.stopdatums nway missing;
	where stopdatum_final lt &rapportdatum and not missing(stopdatum_final);
	class &onderwerp stopjaar stopkwartaal;
	var gebruik_periode;
	output out = rapport_c_&onderwerp (rename = (_freq_ = pats &onderwerp = onderwerp) drop = _type_) sum= mean(gebruik_periode)=gem_gebr_periode;
quit;


data rapport_c_&onderwerp;
	length rapportdeel $ 30 onderwerp $ 40;
	set rapport_c_&onderwerp;
	rapportdeel = "&onderwerp";
run;

proc append base=rapport_c new=rapport_c_&onderwerp force;
quit;

%mend maak_rapport_block;



%maak_rapport_block(leeftijd_staffel);
%maak_rapport_block(gesl);
%maak_rapport_block(gewicht_staffel);
%maak_rapport_block(omschrijving);
%maak_rapport_block(regio);
%maak_rapport_block(zone);


proc datasets lib = work nolist;
	modify rapport_c;
	format gem_gebr_periode commax10.1;
quit;



/************************* DEEL 2 *************************/
data rapport_C_deel_2;
	set hiz.stopdatums;
	where not missing(stopdatum_final);
	keep ecpid omschrijving stopdatum_final datumAanmelding;
run;

proc sql;
	create table rapport_C_deel_2 as 
	select distinct 
		ecpid,
		(omschrijving) as reden,
		(stopdatum_final) as datum_Stop format = yymmdd10.,
		(datumAanmelding) as datum_Start format = yymmdd10.
	from
		rapport_C_deel_2
/*	group by 1*/
	where stopdatum_final lt &rapportDatum
	order by 1;
quit;
