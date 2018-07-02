 /**********************************************************************
 *   PRODUCT:   SAS
 *   VERSION:   9.2
 *   CREATOR:   External File Interface
 *   DATE:      11JAN14
 *   DESC:      Generated SAS Datastep Code
 *   TEMPLATE SOURCE:  (None Specified.)
 ***********************************************************************/
data HIZ.stoppers                                 ;

	infile "&inputData.\hizentra_stoppers.csv" delimiter = ';' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat ECPID best32. ;
	informat Stopdatum yymmdd10. ;
	informat Stopreden $2. ;
	informat Stopreden_details $277. ;
	format ECPID best12. ;
	format Stopdatum yymmdd10. ;
	format Stopreden $2. ;
	format Stopreden_details $277. ;
	input
	        ECPID
	        Stopdatum
	        Stopreden $
	        Stopreden_details $
	;

	if ecpid = 52562 and missing(stopdatum) then stopdatum = '01jan2016'd;
	if ecpid = 52905 and missing(stopdatum) then stopdatum = '30jun2016'd;
	if ecpid = 53393 and missing(stopdatum) then stopdatum = '01may2015'd;  /* SB 2017/04/11 */ 
	if ecpid = 157834 and missing(stopdatum) then stopdatum = '01nov2016'd; /* SB 2017/04/11 */ 
	if ecpid = 163825 and missing(stopdatum) then stopdatum = '01mar2017'd; /* SB 2017/04/11 */ 
	if ecpid = 53398 and missing(stopdatum) then stopdatum = '15sep2013'd; /* SB 2017/04/11 */ 
	if ecpid = 159387 and missing(stopdatum) then stopdatum = '01jan2013'd; /* SB 2017/04/11 */ 
run;

/*
data stoppers2;
	infile datalines missover;

	informat ECPID 6. ;
	informat Stopdatum ddmmyy10. ;
	informat Stopreden $2. ;

	format ECPID best12. ;
	format Stopdatum yymmdd10. ;
	format Stopreden $2. ;

	input
	        @1 ECPID
	        @8 Stopdatum
	        Stopreden $
	       
	;
cards;
50823	27-11-2017	21
50992	13-7-2017	47
52707	9-11-2017	47
52729	26-10-2017	47
54542	27-7-2017	21
59447	9-11-2017	41
59463	3-11-2017	47
65129	26-9-2017	14
65652	28-11-2017	47
68229	22-9-2017	47
144766	11-10-2017	47
150142	18-8-2017	41
150766	15-8-2017	41
153075	15-11-2017	47
163825	31-7-2017	47
165494	26-9-2017	41
182545	11-10-2017	21
186936	22-8-2017	15
194487	25-8-2017	33
199973	29-12-2017	21
200165	16-8-2017	61
200167	25-8-2017	47
200168	31-7-2017	61
202996	7-8-2017	15
203737	25-9-2017	48
204596	22-8-2017	48
214459	28-9-2017	48
217319	8-11-2017	33
225204	29-11-2017	21
228947	18-12-2017	61
;;;
run;

proc freq data=hiz.stoppers noprint;
	tables stopreden / out=freq_stopreden;
quit;
*/
