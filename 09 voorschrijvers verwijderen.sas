data hiz.voorschrijvers_exclude;
	infile datalines;
	input voorschrijver $char29.;
datalines;
Koenraad
Coucke
;;;
run;

proc freq data=hiz.patienten noprint;
	tables voorschrijver / out=freq_voorschrijvers;
quit;
