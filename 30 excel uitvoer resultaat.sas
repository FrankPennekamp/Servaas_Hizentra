
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
	excelNaam=hizentra_&today.,
	invoer=
		work.stoppers_dit_kwartaal
		work.Rapport_a 
		work.Rapport_amin_2
		work.Rapport_b 
		work.Rapport_c
		work.Rapport_d
		work.Rapport_d_export
		work.Rapport_b_deel2
		work.Rapport_c_deel_2
		work.Rapport_persistance_period
		work.Rapport_persistance_final
		,
	sep=#,
	tabBladNamen=
		Nabellen#a#a zonder GIJS COUCKE#b#c#d#d export#b deel 2#c deel 2#persistence tabel a#persistence tabel b,
	autofilter=N, 
	exceltemplate=&codeRoot\leeg.xls
);

