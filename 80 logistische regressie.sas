/* Logistische regressie */
data logres_data;
	set rapport_persistance_final (keep = startmaand gebruik_periode leeftijd_staffel_startdatum2 geslacht indicatie specialisme zone_afk ecpid) ;
	if indicatie in ('-- kies --', 'Overig', 'CLL', '0', 'Hypogammaglobulinemie') then indicatie = 'Ov./Onb.';
	if specialisme in ('Endocrinoloog','Neuroloog','Onbekend') then specialisme = 'Ov./Onb.';
	if gebruik_periode >= 730 then nog_op_product_730 = 1; else nog_op_product_730 = 0;
	startjaar = input(scan(startmaand,1, '-'), best.);
	if startmaand <=  '2015-09';
run;

proc sql;
	create table logres_plus as 
	select 
		logres.*,
		patind.indicatieIndienOverig
	from
		logres_data logres
			left join patienten_indicaties patind
				on logres.ecpid = patind.ecpid
					and patind.indicatie eq 'Overig'
	;
quit;

data logres_plus_final;
	set logres_plus;
	if indicatieIndienOverig eq 'CVID' then indicatie = 'CVID';
run;


proc freq data=logres_plus_final;
	tables indicatie ;
quit;
		
ods pdf base="c:\temp\papa";
proc logistic data=logres_plus_final outest=model descending covout;
	class startjaar leeftijd_staffel_startdatum2 geslacht indicatie specialisme zone_afk;
	model nog_op_product_730 = startjaar leeftijd_staffel_startdatum2 geslacht indicatie specialisme zone_afk
		/ alpha=0.05 rl ctable pprob=0.5 details lackfit selection=backward;
	output out=probs predicted=phat; 
run;

ods pdf close;
