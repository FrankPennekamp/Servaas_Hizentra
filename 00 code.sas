libname hiz 'C:\projecten\Hizentra\data';


title;

proc sort data = hiz.patienten;
	by ecpid;
quit;

proc sort data = hiz.stoppers;
	by ecpid;
quit;

proc sort data = hiz.zorgcontacten;
	by ecpid;
quit;

/* Check dit bij een nieuwe oplevering !! */
proc sql;
	create table geslacht_geboorte as 
	select distinct ecpid, geslacht, geboortedatum, count(*) as aantal
	from 
		hiz.patienten
	group by 2,3
	having aantal > 1
	order by 3,2
	;
quit;
