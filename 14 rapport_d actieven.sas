

proc sql;
	create table stop_act_data as 
	select distinct
		stopdatums.*, 
		patienten.*
	from
		hiz.stopdatums left join hiz.patienten
			on stopdatums.ecpid= patienten.ecpid
order by klant;
quit;




proc sql;
	create table stop_act as 
	select distinct
		stopdatums.ecpid, 
		stopdatums.klant,
		case 
			when stopdatums.stopdatum_final ge &op_therapie_min_datum - 1
			then 1
			else 0 
		end as opTherapie,
		patienten.patientStatus
	from
		hiz.stopdatums left join hiz.patienten
			on stopdatums.ecpid= patienten.ecpid;
quit;


%nodub(stop_Act, ecpid);
%nodub(stop_act, klant);

		
proc freq data=stop_act noprint;
	tables opTherapie * patientStatus / out = rapport_d;
quit;

proc sql;
	create table rapport_d_Export as 
	select 
		* 
	from
		stop_Act
	where
		opTherapie = 1 and patientStatus ne 'actief'
		or opTherapie = 0 and patientStatus ne 'inactief';
quit;



proc datasets lib = work nolist;
	modify rapport_d;
	format percent commax10.1;
quit;


