proc sql;
	create table pc_spec as 
	select 
		postcodeZiekenhuis, 		
		year(datumAanmelding) as jaar_aanmelding,
		specialisme,
		voorschrijver,
		count(*) as aantal
	from
		patienten
	group by 
		1,2,3,4;
quit;


options notes ;
