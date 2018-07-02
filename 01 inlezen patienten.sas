 /**********************************************************************
 *   PRODUCT:   SAS
 *   VERSION:   9.2
 *   CREATOR:   External File Interface
 *   DATE:      11JAN14
 *   DESC:      Generated SAS Datastep Code
 *   TEMPLATE SOURCE:  (None Specified.)
 ***********************************************************************/
%let datumformat=yymmdd10.;


data PATIENTEN                                ;  
    	infile "&inputData.\hizentra_receptregels.csv" delimiter = ';' MISSOVER DSD lrecl=32767 firstobs=2 ;
       informat ECPID best32. ;
       informat datumAanmelding &datumformat ;
       informat product $49. ;
/*	   informat patientStatus $8.;*/
	   length patientStatus $ 20;
	   informat receptVanaf &datumformat;
       informat toedieningsadvies $32. ;
       informat geboortedatum &datumformat ;
       informat geslacht $10. ;
       informat postcodeKlant $8. ;
       informat gewicht commax32. ;
       informat indicatie $27. ;
       informat indicatieIndienOverig $89. ;
       informat voorschrijver $29. ;
	   informat specialisme $30.;
       informat postcodeZiekenhuis $8. ;
       format ECPID best12. ;
	   format patientStatus $20.;
       format datumAanmelding &datumformat ;
       format product $49. ;
       format toedieningsadvies $32. ;
       format geboortedatum receptVanaf &datumformat ;
       format geslacht $10. ;
       format postcodeKlant $8. ;
/*       format gewicht comma12. ;*/
       format indicatie $27. ;
       format indicatieIndienOverig $89. ;
       format voorschrijver $29. ;
	   format specialisme $30.;
       format postcodeZiekenhuis $8. ;
    input
                ECPID
				patientStatus $
                datumAanmelding
                product $
				receptVanaf
                toedieningsadvies $
                geboortedatum
                geslacht $
                postcodeKlant $
                gewicht
                indicatie $
                indicatieIndienOverig $
                voorschrijver $
				specialisme $
                postcodeZiekenhuis $
    ;
	if toedieningsadvies = '0.00 keer per 7.00 dagen' then call missing(toedieningsadvies);
	if missing(receptVanaf) then do;
		*receptVanaf = datumAanmelding;
		receptVanafAltered = 1;
	end;
	else do;
		receptVanafAltered = 0;
	end;

	if ecpid = 52035 and receptVanaf = '27nov2012'd then delete;

	if ecpid = 55435 then do;
		geboortedatum = '7mar1943'd;
	end;

	if ecpid = 139641 then delete; * patient per 23 juni 2015 op hizentra. Daarvoor op andere dienst.. ;

	if ecpid = 53942 then patientStatus = 'inactief'; * Patient is al in 2013 gestopt. ;	

	select(ecpid);
		when(51082) datumAanmelding = '17oct2012'd;
		when(52023) datumAanmelding = '14mar2012'd;
		when(162625) datumAanmelding = '14jun2016'd;
		otherwise;
	end;

	/* Niet gestart */
	* info Marieke 2016 07 15;
	if &rapportdatum = '30jun2016'd then do;
		if ecpid in (162578, 162131, 163825) then delete;
		if ecpid = 53395 then patientStatus = 'actief';
		if ecpid = 52905 then patientStatus = 'actief';
		if ecpid = 53393 then patientStatus = 'inactief'; * Patient is 2015 gestopt. ;	
		if ecpid = 53398 then patientStatus = 'inactief'; 
		if ecpid = 53917 then patientStatus = 'actief';
		if ecpid = 75077 then patientStatus = 'inactief'; 
		if ecpid = 162222 then patientStatus = 'inactief';
		if ecpid = 163411 then patientStatus = 'inactief';
	end;
	

	if &rapportdatum = '30sep2016'd then do;
		if ecpid in (162578, 162131, 163825) then delete;
		if ecpid = 53395 then patientStatus = 'actief';
		if ecpid in( 58790, 146038, 163409) then patientStatus = 'actief'; /* later gestopt */
		if ecpid = 53393 then patientStatus = 'inactief'; * Patient is 2015 gestopt. ;	
		if ecpid = 53398 then patientStatus = 'inactief'; 
/*		if ecpid = 53917 then patientStatus = 'actief';*/
		if ecpid = 75077 then patientStatus = 'actief'; 
		if ecpid = 162222 then patientStatus = 'actief';
		if ecpid = 163411 then patientStatus = 'actief';
	end;

	if &rapportdatum = '31dec2016'd then do;

		/* Gevallen voor Janeed deel 1 2017 01 18 */ 
		if ecpid in (175216, 176583, 177516) then delete; /* onbekend in Navision */
		if ecpid in( 74327, 151772, 171110,172253, 172996, 172998, 176966,
                     177616, 155571, 167557) then patientStatus = 'actief';	
		if ecpid in(55239, 54784, 55075, 52028, 54722, 69981, 151131) then patientStatus = 'inactief'; 

		/* Gevallen voor Janeed deel 2 2017 01 19 */ 
		if ecpid in (53393, 53398, 68325) then patientStatus = 'inactief';
		if ecpid in (75077, 151772, 157834, 159387, 167557, 171110, 171463, 
					 172253, 172996, 172998, 172999, 175540) then patientStatus = 'actief';

	end;

	if &rapportdatum = '31mar2017'd then do;
		if ecpid in (50655, 51804, 52157, 52301, 52311, 52728, 52729, 52853, 52853)
			and missing(receptVanaf) then delete;
		/* Gevallen voor Janeed dd 2017 04 12 */
		if ecpid in (176583, 167557, 186035) then delete;
		if ecpid in (53393, 53398, 157834, 163825, 170634) then patientStatus = 'inactief';
		if ecpid in (170862, 179534, 182376, 183049, 183375, 183568, 185866, 185867) then patientStatus = 'actief';
	end;

	if ecpid = 175151 then delete;   /* SB 2017/04/11 */

	if ecpid = 55508 then ecpid = 159387;	
	if ecpid = 54722 then patientStatus = 'inactief'; * Patient is 1 februari 2013 gestopt. ;	

	if &rapportdatum = '30jun2017'd then do;
		if ecpid in (176583, 199577, 190643, 151131, 188868, 199908, 189581, 194498, 199973) then delete;
		if ecpid in (52028, 54722, 54784, 55239) then delete;
		if ecpid in (53393, 53398) then patientStatus = 'actief';
	end;	


	if &rapportdatum = '30sep2017'd then do;
		/* Gevallen voor Karin dd 2017 10 06 */
		if ecpid in (52028 54722 54784 55239 151131 176583 202996 203737 214459 214559 216423 69981 155571 167557 183335 214613 214614 199257 201393) then delete;
		if ecpid in (53393, 53398 66710 66638  151371 157834 /* 204567 205589 205590 */ 212396 213814 214206 ) then patientStatus = 'inactief';
	end;

	if &rapportdatum = '31dec2017'd then do;
		/* Gevallen voor Karin dd 2018  01 15 */
		if ecpid in (199257 176583 202996 203737 224274 228947 230578 52028	54722	54784	55239	151131	216423	217311	217532	221381	225189	225510	225814	225842	226703	228132	
					228224	228538	228904	229928	230578	69981 155571 167557	183335	188868	212396) then delete;
		if ecpid in (53393 55240 ) then patientStatus = 'inactief';

*		if ecpid in (52028 54722 54784 55239 151131 176583 202996 203737 214459 214559 216423 69981 155571 167557 183335 214613 214614 199257 201393) then delete;
* 		if ecpid in (53393, 53398 66710 66638  151371 157834 /* 204567 205589 205590 */ 212396 213814 214206 ) then patientStatus = 'inactief';
	end;

	if &rapportdatum = '31mar2018'd then do;
		/* Fout in data */
		if ecpid in (	52028	54722	54784	55239	69981	151131	155571	167557	176583	183335
						188868	202996	203737	204596 216423	224274
						228947	231769) then delete;
		/* Nog geen pompdata voor ontvangen */
		if ecpid in ( 224274 225510 225814  225842 226703 230578 231769 234953 237281 237282 237283 241652 243268 244084) then delete;
	end;


	/* Niet Belgische postcodes omzetten naar Belgische  */
	select (ecpid);	
		when (52038) postcodeKlant = '1200';
		when (61150) postcodeKlant = '1740';
		when (151967)postcodeKlant = '3000';
		when (151971)postcodeKlant = '3000';
		otherwise;
	end;
run;




proc freq data=patienten noprint;
	tables receptVanafAltered / missing out=altered;
quit;


/* Recept geldigheid per patient - recept combinatie */
data patienten_receptdatum;
	set patienten;
	if missing(receptVanaf) then receptVanaf = datumAanmelding;
	keep ecpid receptVanaf;
run;


proc sort data=patienten_receptdatum nodup; 
	by ecpid descending receptvanaf ;
quit;


data patienten_receptdatum_min_max;
	set patienten_receptdatum;
	by ecpid descending receptvanaf;
	format prev_receptVanaf receptEind date9.;
	retain prev_receptVanaf;
	if first.ecpid then do;
		prev_receptVanaf = receptVanaf;
		receptEind = '31dec9999'd;
	end;
	else do;
		receptEind = prev_receptVanaf - 1;
		prev_receptVanaf = receptVanaf;
	end;
	drop prev_: ;
run;
	


proc sql;
	create table patienten_indicaties as 
	select distinct
		ecpid,
		count(distinct indicatie) as aantal,
		indicatie,
		indicatieindienoverig,
		case when indicatie in ('-- kies --', 'Overig')
			then indicatieIndienOverig
			else indicatie
		end as rapportage_indicatie
	from 
		patienten
	group by 1;
quit;

/* Zowel NULL als nietnull voor product */
proc sql;
	create table null_nietnull as 
	select distinct a.ecpid from 
		patienten as a inner join patienten as b
	on a.ecpid = b.ecpid 
		and a.product eq 'NULL' and b.product ne 'NULL';
quit; 
/* 5x */


/* Totale dosering per receptmoment */
proc sql;
	create table producten as select distinct product from patienten;
quit;

proc sort data=patienten;
	by ecpid receptVanaf;
quit;

data recept_dosis / view=recept_dosis;
	set patienten;
	by ecpid receptVanaf;
	retain hizentra_ml;
	if first.receptVanaf then do;
		call missing(hizentra_ml);
	end;
	select (product);
		when('NULL', '') do;
			/* niets */
		end;
		when ('Hizentra 1g (5ml) sc immunoglobulines') do;
			hizentra_ml = sum(hizentra_ml, 5);
		end;
		when ('Hizentra 2g (10ml) sc immunoglobulines') do;
			hizentra_ml = sum(hizentra_ml, 10);
		end;
		when ('Hizentra 3g (15ml) sc immunoglobulines') do;
			hizentra_ml = sum(hizentra_ml, 15);
		end;
		when ('Hizentra 4g (20ml) sc immunoglobulines') do;
			hizentra_ml = sum(hizentra_ml, 20);
		end;
	end;
	if last.receptVanaf then output;
	keep ecpid receptVanaf hizentra_ml toedieningsadvies;
run;


/*
proc sql;
	create table dubbele_recepten as 
	select
		ecpid, count(distinct receptVanaf) as aantal, * 
	from 
		patienten 
	group by 1
	having calculated aantal > 1; quit;
*/

proc summary data = recept_dosis nway;
	class ecpid receptVanaf toedieningsadvies;
	var hizentra_ml;
	output out=patient_recept_dosering (drop = _type_ _freq_ ) sum=;
quit;

%nodub(patient_recept_dosering, ecpid);


proc sql;	
	create table hiz.patienten as 
	select distinct 

		patienten.ecpid,
		patienten.datumAanmelding,
		patienten.geboortedatum,
		patienten.postcodeKlant,
		patienten.gewicht,
		patienten.postcodeZiekenhuis,
		patienten.geslacht,
		patienten.patientStatus,
		patienten.voorschrijver,

		patienten.specialisme, 
		patienten_receptdatum_min_max.receptVanaf,
	   	patienten_receptdatum_min_max.receptEind,
		patient_recept_dosering.toedieningsadvies,
		patient_recept_dosering.hizentra_ml,
		patienten_indicaties.indicatie,
		patienten_indicaties.indicatieindienoverig,
		patienten_indicaties.rapportage_indicatie
	from
		(select distinct ecpid, receptVanaf, datumaanmelding, geboortedatum, postcodeklant, gewicht, postcodeziekenhuis, geslacht, patientStatus, voorschrijver, specialisme from patienten ) as patienten
			left join patienten_receptdatum_min_max
				on (patienten.ecpid = patienten_receptdatum_min_max.ecpid
						and patienten.receptVanaf = patienten_receptdatum_min_max.receptVanaf )
			left join patient_recept_dosering
				on (patienten.ecpid = patient_recept_dosering.ecpid
						and patienten.receptVanaf = patient_recept_dosering.receptVanaf)
			left join patienten_indicaties
				on (patienten.ecpid = patienten_indicaties.ecpid);
quit; 
%nodub(hiz.patienten, ecpid);

/* Uit bovenstaande nodub komen patienten die twee records hebben waarvan de eerste met allemaal missings.
   Er is ook 1 patient (52375) die daadwerkelijk een andere dosering heeft gekregen. 
   Ik zie nog 1 patient (55329) die daadwerkelijk een andere dosering heeft gekregen.
   Ik zie nog 1 patient (55501) waarbij de tweede, de meest recente, allemaal missing is. 
*/

proc sql;
	create table unieke_patienten as 
	select distinct ecpid from
	patienten order by 1;
quit;

* 380, maar daar gaan er later nog een paar vanaf. ;



/* Invullen ontbrekende specialismen */
proc sql noprint;
	update hiz.patienten set specialisme = 'Kinderarts' where postcodeZiekenhuis = '1020' and missing(specialisme);
	update hiz.patienten set specialisme = 'Oncoloog' where postcodeZiekenhuis = '1200' and year(datumAanmelding)= 2012 and missing(specialisme);	
	update hiz.patienten set specialisme = 'Hematoloog' where postcodeZiekenhuis = '5530' and year(datumAanmelding) = 2006 and missing(specialisme);
	update hiz.patienten set specialisme = 'Longarts' where postcodeZiekenhuis = '9900' and year(datumAanmelding) = 2013 and missing(specialisme);
	update hiz.patienten set specialisme = 'Oncoloog' where postcodeZiekenhuis = '9300' and year(datumAanmelding) = 2012 and missing(specialisme);
	update hiz.patienten set specialisme = 'Internist' where year(datumAanmelding) = 2012 and missing(specialisme);
quit;

/*
...ontbrekende voorschrijvers... 
where ecpid in (49501 203378 203379 204596 212396)
*/

%nodub(hiz.patienten, %str(ecpid, voorschrijver));
