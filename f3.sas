%let root=c:\projecten\hizentra;

%let codeRoot = &root.\code;
%let inputData = &root.\input\20180702;
%let excelUitDir= &root.\output;
%let op_therapie_min_datum = '01jul2018'd;  * dag na kwartaal einde ?? ;
%let rapportdatum = '30jun2018'd;  /* laatste dag van het kwartaal */

/* test */
%put &op_therapie_min_datum;

%let stopdatum_uitloop_periode = 30;

proc datasets lib = work kill nolist;
quit;


%include "&codeRoot.\macros.sas"; 
%include "&codeRoot.\excel_macros.sas";

%include "&codeRoot.\00 code.sas"; 

/* Inlezen data */
%include "&codeRoot.\01 inlezen patienten.sas"; 
%include "&codeRoot.\02 inlezen zorgcontacten.sas";
%include "&codeRoot.\03 inlezen stopredenen.sas";
%include "&codeRoot.\05 inlezen pompdata.sas"; 
%include "&codeRoot.\06 inlezen stoppers.sas"; 

/* Koppelen data */
%include "&codeRoot.\07 patienten_pompen.sas"; 
%include "&codeRoot.\08 rits.sas"; 

/* Business rules */
%include "&codeRoot.\09 voorschrijvers verwijderen.sas"; 
%include "&codeRoot.\10 stopdata bepalen.sas"; 

/* Rapporten */ 
%include "&codeRoot.\11 rapport_a.sas"; 
%include "&codeRoot.\12 rapport_b.sas"; 
%include "&codeRoot.\13 rapport_c.sas"; 
%include "&codeRoot.\14 rapport_d actieven.sas";

/* Persistence */
%include "&codeRoot.\15 persistance.sas";

/* Tabje met stoppers in dit kwartaal tbv nabellen */
%include "&codeRoot.\20 stoppers in dit kwartaal.sas"; 

/* Wegschrijven naar Excel */
* %include "&codeRoot.\20 excel uitvoer uitzoekers.sas"; 

/* Wegschrijven naar Excel */
%include "&codeRoot.\30 excel uitvoer resultaat.sas"; 
