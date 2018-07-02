data hiz.stopredenen;
infile datalines dlm = '09'x missover; 
length stopreden $ 2 omschrijving $ 50;
input stopreden  @4 omschrijving ;
put stopreden;
datalines;
0	maak een keuze
10	array(adverse events
11	medicatie heeft geen effect
12	medicatie heeft onvoldoende effect
13	medicatie heeft ongewenst effect: bijwerkingen
14	geen/onvoldoende effect
15	bijwerkingen/interacties
16	transplantatie/medische ingreep
20	switch
21	overstap naar andere medicatie/therapie
22	overstap op generiek medicijn
23	overstap op parallel medicijn
30	sociale omstandigheden
31	reden 31: ‘psychische belasting te zwaar’
32	ondersteunende begeleiding ontoereikend
33	zorg niet meer via Eurocept
40	therapie
41	arts stopt therapie - einde voorgeschreven kuur/behandeling
42	therapeutisch effect ongunstig door interacties
43	therapeutisch effect ongewenst door contra-indicaties
44	arts stopt therapie - digitale stopmelding
45	arts stopt therapie - stopmelding via email/fax/brief
46	arts stopt therapie - telefonische stopmelding
47	arts stopt therapie - aanvraag vervalt
48	ongeldige aanmelding
60	patient
61	patient start niet
62	patient stopt deelname - patient vertrekt naar buitenland
63	patient stopt deelname - patient gaat zelf spuiten
80	overlijden
81	overlijden indicatie-gerelateerd
82	overlijden niet indicatie-gerelateerd
83	overlijden
90	overig
91	overig
92	tijdelijke stop (specificeer reden en vermoedelijke herstartdatum)
99	onbekend
;;;
run;

proc sort; 
	by stopreden;
quit;
