
proc sql;
	create table rits as 
/*	select distinct patienten_toebehoren.ecpid, patienten_toebehoren.klant, patienten_toebehoren.land from patienten_toebehoren*/
/*	union */
	select distinct patienten_pompen.ecpid, patienten_pompen.klant, patienten_pompen.land from patienten_pompen
	union 
	select distinct patienten.ecpid from hiz.patienten;
quit;


data rits;
	set rits;
	by ecpid klant;
	if last.ecpid;
run;

data update_marieke (where = (ecpid>0));
	infile datalines dlm = '09'x ;
	length ecpid 8 klant $ 6;
	input ecpid 6. klant $;
	datalines ;
49501	K33505
50658	K35130
51082	K33881
51192	K29780
52001	K33445
52023	K33856
52027	K33736
52156	K33907
52157	K32736
52158	K33848
52819	K37327
55240	K33723
55394	K39175
55508	K37098
58557	K40453
58557	K40453
65138	K47636
65233	K47638
69284	K51284
69841	K53010
73434	K56092
74779	K56917
75938	K57637
76111	K57723
76336	K57897
76337	K57896
76344	K57894
76877	K58191
77289	K58309
77346	K58443
139508	K59621
139641	K49982
139640	K59894
142502	K60654
142505	K60653
143230	K60808
143878	K61107
144872	K61442
144963	K61367
145471	K61564
145590	K61714
146038	K63845
148144	K64137
149266	K63716
149267	K63717
149274	K63799
150140	K63162
150765	K63440
151371	K63739
150140	K63162
150765	K63440
151349	K64309
151970	K63741
152720	K63880
152721	K63881
153042	K62316
157235	K65722
157334	K65795
-1		BATCH
165901	K68505
168658	K69048
168671	K68571
168975	K69659
169237	K69528
169889	K69460
159387	K37098
139641	K49982
151864	K64527
165901	K68505
168671	K68571
162222	K67126
163411	K67504
74327	K56626
151772	K63745
171110	K58635
172253	K70484
172996	K70649
172998	K70650
176966	K71421
177616	K71761
139641	K49982
179534	K71984
182376	K73182
183375	NOPOMP
183568	K73373
185866	K73852
151971	K63677
190865	K74709
186035	K74237
186981	K74325
188338	K76198
189587	K75175
189589	K75436
190865	K74709
194487	K75233
195466	K75686
201393	K78174
213814	K78408
214206	K78406
214613	K78202
214614	K78207
/* Toegevoegd 20180116 */
175216	K72952
214459	K76117
217534	K78598
218742	K79004
220885	K79039
227948	K79845
58719	K80476
/* Toegevoegd 20180410 */
182533	K73106
199257	K75677
233808	K81211
/* Toegevoegd 20180704 */
157700	K66189
245949	K83457
245950	K83388
247107	K83462
253843	K84880
245038	K83162
;;;
run;
/*
	52028	K33849
	54722	K38116
	54784	K33843
	55239	K32077
	151131	K64136
	216423	K78421
	217311	K78599
	217532	K80730
	221381	K79384
	225189	K80754
	225510	K79987
	225814	K80941
	225842	K80097
	226703	K79912
	228132	K80237
	228224	K80480
	228538	K80233
	228904	K80647
	229928	K80644
	230578	K80737
	69981	K52869
	155571	K64586
	167557	K68839
	183335	K73051
	188868	K74673
	212396	K78418

;;;
run;
*/



/*
Verwijderde koppelingen 
* 2017-07-06
55239	K32077
54784	K33843
52028	K33849
54722	K38116
69981	K52869  Nederland 
155571	K64586	Nederland
167557	K68839	Nederland
190643	K59898
151131	K64136
188868	K74673
199908	K76117
199973	K76206
194498	K76203
189581	K76201

* 2018 01 16
69981	K52869
155571	K64586
167557	K68839
188868	K74673
212396	K78418
183335	K73051
* 2018 07 04
249776	K84011
*/






proc sort data=update_marieke nodup;
	by ecpid;
quit;

/* Haal de landen er bij */
proc sql;
	create table update_marieke_land as 
	select distinct
		update_marieke.*,
		pompdata.land
	from
		update_marieke left join hiz.pompdata 
			on update_marieke.klant = pompdata.klant
/*	union*/
/*	select distinct*/
/*		update_marieke.*,*/
/*		toebehorendata.land*/
/*	from*/
/*		update_marieke inner join hiz.toebehorendata */
/*			on update_marieke.klant = toebehorendata.klant*/
;
quit;	

proc sql;
	delete from rits 
	where ecpid in (select distinct ecpid from update_marieke_land);
	delete from rits 
	where klant in (select distinct klant from update_marieke_land);
quit;

proc append base = rits new = update_marieke_land force;
quit;



%let klant_delete = ('K37089', 'K40602', 'K58787', 'K61396', 'K63760', 'K65595', 'K49982');
%let epcid_delete = (51889, 145503, 138578, 55508, 139641, 162131);



proc sql;
	delete from rits where klant = 'K42774' and ecpid = 59057;
	delete from rits where ecpid in &epcid_delete;
	delete from rits where klant in &klant_delete ;
quit;


proc sql;
	create table niet_gekoppeld as
	select distinct
		ecpid
	from
		rits
	where missing(klant);
quit;

proc sql;
	create table niet_gekoppeld_export as
	select distinct
		p.*
	from
		work.patienten p
	where
		ecpid in (select distinct ecpid from niet_gekoppeld);
quit;


proc sort data=rits; 
	by klant; 
quit;


%nodub(rits, ecpid);


proc sql;
	update rits 
	set land = 'Belgie'
	where ecpid in (55239, 54784, 52028, 54722, 171110, 151131, 172253, 176966, 177616, 231769,
				    234953, 237281, 237282, 237283,241652, 243268, 244084 )
	;

	update rits
	set land = 'Nederland'
	where ecpid in (69981, 155571, 167557)
	;

	update rits 
	set land = 'Luxemburg'
	where ecpid in (224274);

quit;

proc sql;
	create table unieke_pompen 
	as select distinct klant 
	from hiz.pompdata order by 1;
quit;


proc sql;
	create table klant_marieke_zonder_pomp as select * from rits 
	where klant not in (select distinct klant from unieke_pompen)
		and klant not in &klant_delete
	order by ecpid;

	create table pomp_zonder_klant as 
	select klant 
	from unieke_pompen 
	where klant not in (select distinct klant from rits)
		and klant not in &klant_delete;

	create table mooie_koppeling as 
	select distinct 
		* 
	from rits 
	where klant in (select distinct klant from unieke_pompen) and ecpid in 
		(select distinct ecpid from unieke_patienten);
quit;

%nodub(mooie_koppeling, ecpid); * 0;
%nodub(mooie_koppeling, klant); * 0;

