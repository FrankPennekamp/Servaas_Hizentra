
data _null_;
	datum = date();
	tijd = time();
	x = put(datum, yymmddn8.);
	y = translate(put(tijd, hhmm.), '_', ':');
	z = strip(x) || '_' || strip(y);
	call symput('today', z);
run;

%put &today;

/* Eerste instantie de fouten */
/*%tabels2excel(*/
/*	excelUitDir=&excelUitDir.,*/
/*	excelNaam=hizentra_&today._uitzoekers,*/
/*	invoer=work.pomp_zonder_klant work.klant_marieke_zonder_pomp work.niet_gekoppeld_export,*/
/*	sep=#,*/
/*	tabBladNamen=Pomp zonder klant#Klant zonder pomp#Niet gekoppeld details,*/
/*	autofilter=N, */
/*	exceltemplate=&codeRoot\leeg.xls*/
/*);*/


/* Dan de oplevering */
%tabels2excel(
	excelUitDir=&excelUitDir.,
	excelNaam=hizentra_&today._uitzoekers,
	invoer=
		work.klant_marieke_zonder_pomp 
		work.niet_gekoppeld_export 
		work.pomp_zonder_klant
		work.Rapport_d_export
		,
	sep=#,
	tabBladNamen=
		Klant zonder pomp#Niet gekoppeld details#Pomp zonder klant#Actief of inactief,
	autofilter=N, 
	exceltemplate=&codeRoot\leeg.xls
);

