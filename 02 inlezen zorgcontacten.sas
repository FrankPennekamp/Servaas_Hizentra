 /**********************************************************************
 *   PRODUCT:   SAS
 *   VERSION:   9.2
 *   CREATOR:   External File Interface
 *   DATE:      11JAN14
 *   DESC:      Generated SAS Datastep Code
 *   TEMPLATE SOURCE:  (None Specified.)
 ***********************************************************************/

data HIZ.zorgcontacten                            ;
	infile "&inputData.\hizentra_contacten.csv" delimiter = ';' MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat ECPID best32. ;
	informat typeContact $1. ;
	informat _datumContact anydtdtm.;

	format ECPID best12. ;
	format typeContact $1. ;
	format datumContact date9. ;
	input
		ECPID
		typeContact 
		_datumContact $
	;
	datumcontact = datepart(_datumcontact);
	drop _d: ;
run;
