%macro nodub(ds, id);
proc sql;
	create table _nodub as 
	select *, count(*) as aantal
	from &ds
	group by &id
	having calculated aantal > 1
	order by &id;
quit;
%mend nodub;


%macro advies_naar_freq_per_dag;
	select (toedieningsadvies);
		when ( '1.00 keer per 7.00 dagen') freq_per_dag = 1/7;
		when ( '0.00 keer per 7.00 dagen') freq_per_dag = 0/7;
		when ( '2.00 keer per 15.00 dagen') freq_per_dag = 2/15;
		when ( '1.00 keer per 3.00 dagen') freq_per_dag = 1/3;
		when ( '2.00 keer per 3.00 dagen') freq_per_dag = 2/3;
		when ( '2.00 keer per 7.00 dagen') freq_per_dag = 2/7;
		when ( '4.00 keer per 3.00 dagen') freq_per_dag = 4/3;
		when ( '1.00 keer per 8.00 dagen') freq_per_dag = 1/8;
		when ( '1.00 keer per 21.00 dagen') freq_per_dag = 1/21;
		when ( '1.00 keer per 14.00 dagen') freq_per_dag = 1/14;
		when ( '1.00 keer per 15.00 dagen') freq_per_dag = 1/15;
		when ( '1.00 keer per 1.00 dagen') freq_per_dag = 1/1;
		when ( '1.00 keer per 30.40 dagen') freq_per_dag = 1/30;
		when ( '1.00 keer per 10.00 dagen') freq_per_dag = 1/10;
		when ( '0.70 keer per 7.00 dagen') freq_per_dag = 1/10;
		when ( '4.00 keer per 7.00 dagen') freq_per_dag = 4/7;
		when ( 'NULL', '' ) freq_per_dag = .;
		otherwise do;
			put "ERROR: XXXXXX->" toedieningsadvies "<-XXXXX" _n_ =;
		end;
	end;
%mend advies_naar_freq_per_dag;

%macro leeftijd_naar_staffel(leeftijdvar);
	if 0 le &leeftijdvar le 3 then leeftijd_staffel  = 'lft 00 - 03';
	else if 4 le &leeftijdvar le 6 then leeftijd_staffel  = 'lft 04 - 06';
	else if 7 le &leeftijdvar le 12 then leeftijd_staffel  = 'lft 07 - 12';
	else if 13 le &leeftijdvar le 17 then leeftijd_staffel  = 'lft 13 - 17';
	else if 18 le &leeftijdvar le 25 then leeftijd_staffel  = 'lft 18 - 25';
	else if 26 le &leeftijdvar le 59 then leeftijd_staffel  = 'lft 26 - 65';
	else if 60 le &leeftijdvar then leeftijd_staffel  = 'lft 66 - 99';
	else leeftijd_staffel = 'lft onbekend';
%mend leeftijd_naar_staffel;
