proc sql;
	create table work.rapport_persistance_period as 
	select 
		put(datumAanmelding, yyq.) as periode,		
	case when stopreden = '83' then 1 else 0 end as overleden,
		count(*) as aantal,
		sum( case when missing(hci_stopdatum) then 1 else 0 end) as nog_op_therapie
	from hiz.stopdatums
	where datumAanmelding ge '01jan2012'd
	/* and stopreden ne '83' */
	group by 1,2;
quit;


/* leeftijd staffel op moment van AANMELDING !!! */

proc sql;
	create table work.rapport_persistance_final as 
	select ecpid, klant,
		put(datumAanmelding, yymmd.) as startmaand,
		leeftijd_staffel_startdatum2,	
		gebruik_periode,
		geslacht,
		indicatie,
		indicatieIndienOverig,
		specialisme,
		zone_afk
	from 
		hiz.stopdatums
	where
		'01jan2012'd le datumAanmelding le intnx('year', &rapportdatum, -1, 's')
		and stopreden ne '83'
	;
quit;


