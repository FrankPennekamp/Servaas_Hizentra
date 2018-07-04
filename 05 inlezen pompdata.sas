 /**********************************************************************
 *   PRODUCT:   SAS
 *   VERSION:   9.2
 *   CREATOR:   External File Interface
 *   DATE:      11JAN14
 *   DESC:      Generated SAS Datastep Code
 *   TEMPLATE SOURCE:  (None Specified.)
 ***********************************************************************/
data HIZ.Pompdata                                 ;
    infile "&inputData.\Pompdata.csv" delimiter = ';' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat Klant $6. ;
	informat Geboortedatum ddmmyy10. ;
	informat Postcode $6. ;
	informat Land $10. ;
	informat Geslacht $6. ;
	informat Dagen best32. ;
	informat Bedrag comma6.1 ;
	informat Maand anydtdtm40. ;

	format Klant $6. ;
	format Geboortedatum ddmmyy10. ;
	format Postcode $6. ;
	format Land $10. ;
	format Geslacht $6. ;
	format Dagen best12. ;
	format Bedrag best12. ;
	format Maand datetime. ;
    input
                Klant $
                Geboortedatum
                Postcode $
                Land $
                Geslacht $
                Dagen
                Bedrag
                Maand
    ;

	if Klant in ('K70634') then do;
		/* Klant moet weg van Servaas, record gebruikt voor K58635 SB 2017/04/11 
		*/
		if &rapportdatum = '31mar2017'd then do;
			klant = 'K58635';
			call missing(geboortedatum, postcode, land, geslacht, bedrag);
			dagen = 31;
			maand = '01MAR17:00:00:00'dt;
		end;
		else delete;
	end;

	if &rapportdatum = '31mar2017'd then do;
		if klant = 'K73892' then delete;
	end;

	if &rapportdatum = '30jun2017'd then do;
		if klant in ('K75677') then delete;
	end;

	if &rapportdatum = '30sep2017'd then do;
		if klant in ('K75677', 'K78202', 'K78207') then delete;
	end;

	if &rapportdatum = '31dec2017'd then do;
		if klant in ('K75677') then delete;
	end;

	if &rapportdatum = '30jun2018'd then do;
		if klant in ('K83919') then delete;
	end;
run;

/* SB 2017/04/11 : klant koopt geen pomp, maar doet wel mee */
data geenpomp;
	set hiz.pompdata (obs = 1);
	call missing(geboortedatum, postcode, land, geslacht, bedrag);
	klant = 'NOPOMP';
	maand = '01MAR17:00:00:00'dt;
	dagen = 31;
run;


proc append base = hiz.pompdata new = geenpomp;
quit;


proc sql;
		update HIZ.Pompdata
		set maand = '01FEB14:00:00:00'dt
		where maand = '01MAR14:00:00:00'dt 
			and dagen = 28;
quit;

proc sql;
	create table unieke_pompen 
	as select distinct klant 
	from hiz.pompdata order by 1;
quit;

proc sort data=hiz.pompdata;
	by klant maand;
quit;

%nodub(hiz.pompdata, %str(klant, maand));
proc sql;
	create table dubbele_pompduur as 
	select 
		klant,
		maand,
		min(maand) as eerste_maand,
		sum(dagen) as tot_dagen
	from
		hiz.pompdata
	group by 
		1,2
	having 
		tot_dagen > 31 
			and eerste_maand ne maand;
quit;

proc sql;
	create table xx as select * from hiz.pompdata where klant in (select klant from dubbele_pompduur) order by klant, maand;
quit;
