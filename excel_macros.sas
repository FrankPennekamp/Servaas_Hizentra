%macro obsnvars(ds);
   %global dset nvar_gl nobs_gl;
   %let dset=&ds;
   %let dsid = %sysfunc(open(&dset));
   %if &dsid %then
      %do;
         %let nobs_gl =%sysfunc(attrn(&dsid,NOBS));
         %let nvar_gl =%sysfunc(attrn(&dsid,NVARS));
         %let rc = %sysfunc(close(&dsid));
      %end;
   %else
      %put Open for data set &dset failed - %sysfunc(sysmsg());
%mend obsnvars;



%let kol_col = c ;
* hiermee kan, als je een DDE error krijgt in    ;
* excel_delete_rc of excel_format of excel_active_cell         ;
* de lokale instelling van aanroepen met k of c omzetten.      ;
* Op de Injesas machines moet                                  ;
* het een c zijn (en dat is dus de default), op de XP machines ;
* moet het een k zijn. Let op, dit ligt aan engelse versie van ;
* het OS. Je zou ook nog problemen kunnen hebben met engelse   ;
* versie van Excel, dan zouden bv alle filename statements ook ;
* een c moeten hebben waar nu een k staat.                     ;

/*---------------------------------------------------------*\
| automatische test of kol_col = c of k van toepassing is.  |
| je moet wel zorgen dat excel aanstaat, doet er niet toe   |
| welk spreadsheet verder                                   |
| voorbeeld gebruik:                                        |
| %excel_open                                               |
| %excel_test_kol_col                                       |
| %put kol_col = &kol_col ;                                 |
\----------------------------------------------------------*/
%put compiling macro excel_test_kol_col;
%macro excel_test_kol_col ;
   data _null_;
    computername = upcase("%sysget(computername)");
      put computername=;
      if computername =: 'INJESAS' or computername = 'TIL-SPDWH-04' 
                  then call symput ('kol_col','c');
                  else call symput ('kol_col','k');
      put 'computernaam = ' computername;
   run;
   %put var kol_col  =  &kol_col    ;
%mend excel_test_kol_col ;

* macro ook altijd opstarten zodat kol_col altijd goed staat;
%excel_test_kol_col ;

/* DEZE MACRO NIET WEGGOOIEN SVP... ALGEMEEN VOOR EEN ANDERE KEER NOG TE GEBRUIKEN
%macro excel_test_kol_col ;
  %global kol_col ;
  %let er_ab = %sysfunc(getoption ( errorabend ));
  %let er_ch = %sysfunc(getoption ( errorcheck ));

  %* de volgende stap kan een lelijke ER ROR : opleveren, die willen we niet detecteren ;
  %* met Q:\macros\alg_sas_scripts\check_log.sas  daarom log even omleiden              ;
  %ran_S_nm (ran_nam=excel_ran);
  %put Start van test van kol_col. Er kan hieronder een DDE fout staan, dat is OK. ;
  proc printto log="c:\&excel_ran..txt"; run; quit;

  options  noxwait noerrorabend errorcheck = normal ;
  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[select(""r1c1:r1c1"")]";
  run;
  %*put Error tgv van gebruik c voor colomn: &syserr;
  %if &syserr = 0 %then %let kol_col = c ;
                  %else %let kol_col = k ;
  options &er_ab errorcheck = &er_ch ;
  * einde omleiden log ;
  proc printto log=log; run; quit;
  %put Einde van test van kol_col. Er kan hierboven een DDE fout staan, dat is OK. ;
  %put kol_col = &kol_col ;
  x "del c:\&excel_ran..txt";  * de file opschonen waar tijdelijk naar geschreven werd;
%mend excel_test_kol_col ;
*/

/*---------------------------------------------------------*\
| start de applicatie Excel als die niet al gestart is      |
\----------------------------------------------------------*/
%put compiling macro excel_open;
/*
%macro excel_open;
  options  noxwait;
  filename sas2xl dde 'excel|system';
  data _null_;
    * length fid rc start stop time 8;
     fid=fopen('sas2xl','s');
     %* s_ystask is net als e_ndsas een statement die direct wordt uigevoerd als  ;
     %* de compiler hem ziet. Daarom, stop hem in een macrovar als van toepassing ;
     %* en voer die macrovar dan na de datastep uit.                              ;
     %* en dan toch 5 seconden wachten, proefondervindelijk ondervonden dat dat moet;
     if (fid le 0) then
            call symput ( 'stt', 'systask command "start excel" taskname=te; waitfor te;' );
       else call symput ( 'stt', ' ');
     rc=fclose(fid);
  run;
  &stt;
  %let slept = %sysfunc(sleep(10));
%mend excel_open ;
*/

/* Start excel applicatie op
  aanpassing: wacht niet meer een vaste 10 seconden, maar check zelf of/wanneer excel is opgestart.
*/
%macro excel_open;
  %let m_notes1 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;
  filename sas2xl dde 'excel|system';
   data _null_;
      length fid rc start stop time 8;
      fid=fopen('sas2xl','s');
      %*start excel als deze nog niet open staat.;
      if (fid le 0) then do;
            rc=system('start excel');
            start=datetime();
            %*Probeer maximaal 5 min of excel al opgestart is;
            stop=start+300;
            %*is excel al opgestart?;
            do while (fid le 0);
               fid=fopen('sas2xl','s');
               time=datetime();
               if (time ge stop) then leave;
            end;
            if fid le 0 then put 'E' 'RROR: Excel kon niet geopend worden.';
                        else put 'Excel geopend.';
      end;
      else put 'Excel is al open.';
      rc=fclose(fid);
   run;
   options &m_notes1;
%mend excel_open ;

/*---------------------------------------------------------*\
| open een workbook                                         |
| je kan ook dbase3 openen hiermee - pad/naam.dbf gebruiken |
\----------------------------------------------------------*/
%put compiling macro excel_open_spreadsheet;
%macro excel_open_spreadsheet( ex_f_nam );
  %let m_notes2 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[open(""&ex_f_nam"")]";
  run;

  options &m_notes2;
%mend excel_open_spreadsheet;

/*---------------------------------------------------------*\
| tja.. the name says it all                                |
| Positional parameters                                     |
| ws_nam = worksheet naam die wordt verwijdert              |
\----------------------------------------------------------*/
%put compiling macro excel_delete_worksheet;
%macro excel_delete_worksheet( ws_nam );
  %let m_notes3 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;
  %put EXCEL deleting &ws_nam;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.delete(""&ws_nam"")]";
  run;

  options &m_notes3;
%mend excel_delete_worksheet;

/*---------------------------------------------------------*\
| Excel workbook saven en closen                            |
| let op: excel blijft wel gewoon draaien                   |
| Positional parameters                                     |
| ex_f_nam = excel file naam (uitvoer), zet er .xls achter! |
| Named parameters:                                         |
| type_num = 1 = huidige versie van Excel,                  |
|            33= actieve Excel 4.0 worksheet,               |
|            35= gehele workbook in Excel 4 format,         |
|            2=SYLK (alleen actieve WS),                    |
|            24=CSV (alleen actieve WS)                     |
| close = als niet n dan closed hij de workbook (default)   |
| save  = als niet n dan saved hij het workbook (default)   |
| zie excel help file voor meer waarden                     |
\----------------------------------------------------------*/
%put compiling macro excel_save_and_close;
%macro excel_save_and_close( ex_f_nam , type_num = 1, close=Y, save=Y );
   %let m_notes4 = %sysfunc(getoption ( notes ));
   options xwait nonotes;
   %put excel_save_and_close &ex_f_nam;

   filename sas2xl dde 'excel|system';
   data _null_;
      file sas2xl;
      put '[error(false)]';
      %if %upcase(&save) ne N %then %do;
         put "[save.as(""&ex_f_nam"", &type_num)]";
      %end;
      %if %upcase(&close) ne N %then %do;
         put '[file.close(false)]';
      %end;
   run;
   filename sas2xl;

   options &m_notes4;
%mend excel_save_and_close ;

/*---------------------------------------------------------*\
| Excel geheel afsluiten zonder opslaan                     |
\----------------------------------------------------------*/
%put compiling macro excel_quit;
%macro excel_quit;
   %let m_notes5 = %sysfunc(getoption ( notes ));
   options noxwait nonotes;
   %put excel_quit;

   filename sas2xl dde 'excel|system';
   data _null_;
      file sas2xl;
      put '[error(false)]';
      put '[quit]';
   run;
   filename sas2xl;

   options &m_notes5;
%mend excel_quit ;

/*---------------------------------------------------------------------------*\
| excel_read                                                                  |
| Om een opgegeven range cellen uit een sheet te lezen in een SAS dataset.    |
| LET OP: bij sommige gevallen is de input string nog langer als 2048, dan    |
| moet deze macro worden aangepast.                                           |
|                                                                             |
| Je kan ook dbase lezen (mits niet over de limiet van aantal rows), maar     |
| je moet dan wel de file met .dbf eindigen.                                  |
|                                                                             |
| Positionele parameters:                                                     |
| wb_nam = workbook naam (met of zonder .xls of .xlt erachter)                |
| ws_nam = worksheet naam                                                     |
| first_row, first_col, last_row, last_col = evident                          |
| lib_nam, ds_nam = library en dataset waarin in te lezen gegevens komen      |
| vars = paren van kolomnaam en informat voor ds_nam, alles gescheiden door   |
|        spaties                                                              |
\----------------------------------------------------------------------------*/
%put compiling macro excel_read;
%macro excel_read( wb_nam, ws_nam, first_row, first_col, last_row, last_col
                 , lib_nam, ds_nam, vars , record_lengte = 2048);
   %let m_notes6 = %sysfunc(getoption ( notes ));
   options nonotes;

   %let i_vars = 1;
   %let i_suffix = 1;
   %do %while (%scan( &vars, &i_vars, ' ' ) ne );
         %let var_&i_suffix = %scan( &vars, &i_vars, ' ' ) ;
         %let i_vars = %eval( &i_vars + 1);
         %let frm_&i_suffix = %scan( &vars, &i_vars, ' ' ) ;
         %let no_vars = %eval( &i_suffix );
         %let i_vars = %eval( &i_vars + 1);
         %let i_suffix = %eval(&i_suffix + 1);
   %end; %* end loop over while ;

   %* als er al .xlt of .xls achter het workbook naam staat niet nog een keer .xls erachter plakken;
   data _null_;
     if not ( index( "&wb_nam", '.xlt' ) or 
              index( "&wb_nam", '.xls' ) or
              index( "&wb_nam", '.dbf' )
            ) then
         call symput( "wb_nam", left(trim("&wb_nam"))||'.xls' );
   run;

   filename ex_blok dde "excel|[&wb_nam]&ws_nam!r&first_row.&kol_col.&first_col:r&last_row.&kol_col.&last_col" ; 
   data &lib_nam..&ds_nam;
     infile ex_blok dlm='09'x notab dsd missover lrecl=&record_lengte ;
     informat %do iv = 1 %to &no_vars ; &&var_&iv &&frm_&iv  %end; ;
     input  %do iv = 1 %to &no_vars ; &&var_&iv %end; ;
   run;

   filename sas2xl;

   options &m_notes6;
%mend excel_read;

/*---------------------------------------------------------------------------*\
| excel_read_into_macro_var                                                   |
| Om een opgegeven range cellen uit een sheet te lezen in macro variabelen    |
|                                                                             |
| Positionele parameters:                                                     |
| wb_nam = workbook naam (met of zonder .xls of .xlt erachter)                |
| ws_nam = worksheet naam                                                     |
| first_row, first_col, = evident                                             |
|   uitlezen op row basis, dus van links naar rechts op zelfde rij            |
| lib_nam, ds_nam = library en dataset waarin in te lezen gegevens komen      |
| vars = paren van macrovarnamen en informat , alles gescheiden door          |
|        spaties                                                              |
\----------------------------------------------------------------------------*/
%put compiling macro excel_read_into_macro_var ;
%macro excel_read_into_macro_var( wb_nam, ws_nam, first_row, first_col, vars );
   %let m_notes7 = %sysfunc(getoption ( notes ));
   options nonotes;

   %let i_vars = 1;
   %let i_suffix = 1;
   %do %while (%scan( &vars, &i_vars, ' ' ) ne );
         %let var_&i_suffix = %scan( &vars, &i_vars, ' ' ) ;
         %let i_vars   = %eval( &i_vars + 1);
         %let frm_&i_suffix = %scan( &vars, &i_vars, ' ' ) ;
         %let no_vars  = %eval( &i_suffix );
         %let i_vars   = %eval( &i_vars + 1);
         %let i_suffix = %eval(&i_suffix + 1);
         %let last_col = %eval(&first_col+&no_vars-1);
   %end; %* end loop over while ;
   %do iv = 1 %to &no_vars ; %global &&var_&iv ;  %end;

   %* als er al .xlt of .xls achter het workbook naam staat niet nog een keer .xls erachter plakken;
   data _null_;
      if not( index( "&wb_nam" , '.xlt' ) or index( "&wb_nam", '.xls')) then
      call symput( "wb_nam", left(trim("&wb_nam"))||'.xls' );
   run;

   filename ex_blok dde "excel|[&wb_nam]&ws_nam!r&first_row.&kol_col.&first_col:r&first_row.&kol_col.&last_col" ;

   data _null_ ;
     infile ex_blok dlm='09'x notab dsd missover;
     informat %do iv = 1 %to &no_vars ; &&var_&iv &&frm_&iv  %end; ;
     input  %do iv = 1 %to &no_vars ; &&var_&iv %end; ;
     %do iv = 1 %to &no_vars ; call symput ("&&var_&iv", &&var_&iv ); %end;
   run;

   %do iv = 1 %to &no_vars ; %let &&var_&iv = &&&&&&var_&iv ; %end;  %* links uitlijnen, ja, ja 6 maal emps ;

   options &m_notes7;
%mend excel_read_into_macro_var ;

/*---------------------------------------------------------------------------*\
| excel_write_block                                                           |
| Om een opgegeven range cellen uit een SAS dataset te lezen en in Excel weg  |
| te schrijven.                                                               |
|                                                                             |
| Positionele parameters:                                                     |
| lib_nam, ds_nam = library en dataset waarin in te lezen gegevens komen      |
| vars = lijst met SAS variabelen. Als je _all_ gebruikt dan worden alle      |
|       variabelen in de SAS dataset ge-output.                               |
| first_row, first_col = eerste cel waar schrijven begint, breedte wordt      |
|       bepaald door aantal SAS variabelen, aantal rows door aantal rijen in  |
|       sas dataset                                                           |
| wb_nam = workbook naam                                                      |
| ws_nam = worksheet naam                                                     |
|                                                                             |
| Named parameters:                                                           |
| varnam = Y ==>  de namen van de SAS variabelen op 1e regel zetten           |
| label = Y ==> de labels van de SAS variabelen op de 1e regel zetten (of op  |
|       2e regel als varnam=Y ook al aanstaat)                                |
| label_first = als zowel varnam als label gezet zijn komt standaard varnam   |
|               eerst, als je dit wilt omdraaien zet dan label_first=Y        |
| allsort = als _all_ is gekozen voor vars dan worden de variabelen gesorteerd|
|       op naam bij wegschrijven, dus als je vars a,c,b hebt (in die volgorde |
|       in de dataset) dan wordt er a,b,c als volgorde in xls geschreven.     |
|       Met name handig als je vele 10-tallen kolommen in een dataset hebt.   |
| extra_sas_code = : SAS code die vlak voor het wegschrijven naar Excel wordt |
|       uitgevoerd. Met name handig als je binnen een macro loop meerdere     |
|       malen zelfde dataset wil gebruiken, maar met verschillende filters    |
| where = where conditie als je niet alle rijen uit dataset wil wegschrijven  |
| colour_key = list of variables by which the data is sorted en coloured.     |
| kleur = de om-en-om kleur, defualt = 35 = geel. 1=zwart (niet doen),        |
|         2=wit (ook niet doen), 3=licht rood, 4=licht groen, 5=donker blauw  |
|         6=geel, 7=roze, 8=cyan, 9=donker rood, bijna bruin,                 |
|         10=donker groen, 11=heeel donker blauw (niet doen), 12=groenig      |
|         13=paars, 14=groen/paars, 15=licht grijs (wel mooi), 16=donker grijs|
|         17=licht paars, 18=donker rood/paars, 19=licht geel (wel mooi)      |
|         20=licht blauw, 21=donker paars, 22=mooi licht rood,                |
|         23=opvallend blauw, 24=helder paars (wel mooi), 25=heel donker paars|
|         26=helder paars, 27=geel, 28=helder blauw, 29 tm 31 te donker       |
|         34=helder blauw, mooi, 35=Spark groen (mooi), 26=mooi licht geel    |
|         37=mooi licht helder blauw                                          |
|                                                                             |
| Aanpassing, label=y werkte niet bij lege labels, daarom aangepast zodat     |
|             bij lege labels de varnaam als label gebruikt wordt             |
|             EJS 20071030                                                    |
|             select label = select coalesce(label,name)                      |
\----------------------------------------------------------------------------*/
%put compiling macro excel_write_block;
%macro excel_write_block( lib_nam, ds_nam, vars, first_row, first_col, wb_nam, ws_nam
                        , varnam=N, label=N, allsort=N, extra_sas_code= , where=
                        , label_first=N, colour_key=, kleur=35                      
                        );
   %let m_notes8 = %sysfunc(getoption ( notes ));
   options nonotes;
   %put START excel_write_block &lib_nam..&ds_nam , &vars, naar &ws_nam , first_row=&first_row , first_col=&first_col ;

   %let i_vars = 1;
   %if %qlowcase(&vars) ne _all_ %then %do %while (%qscan( &vars, &i_vars ) ne );
         %let var_&i_vars = %qscan( &vars, &i_vars )   ;
         %let no_vars = &i_vars;
         %let i_vars = %eval( &i_vars + 1);
   %end; %* end loop over while, kan i_vars weer voor iets anders gebruiken ;

   %let n_rows=0;
     proc sql noprint;
   %if %qlowcase(&vars) eq _all_ %then %do;
         select nvar
         into   :no_vars
         from sashelp.vtable
         where libname = upcase("&lib_nam")
         and  upcase(memname) = upcase("&ds_nam")
         ;
   %end;
         select count(*)
         into  :n_rows
         from &lib_nam..&ds_nam
   %if %bquote(&where) ne %then %do;
         where  &where
   %end;
     ;
     quit;

   %let last_col = %eval( &first_col + &no_vars -1 );
   %let extra_rows = 0;
   %if %qlowcase(&label ) ne n %then %let extra_rows = %eval(&extra_rows + 1);
   %if %qlowcase(&varnam) ne n %then %let extra_rows = %eval(&extra_rows + 1);
   %let last_row = %eval( &first_row + &n_rows + &extra_rows - 1 ); %* extra rows voor label=Y en varnam=Y ;
   %let no_vars = &no_vars ; %* trucje om links uit te lijnen;

   %if %qlowcase(&vars) = _all_ %then %do;
     proc sql noprint;
        select name
        into :var_1 - :var_&no_vars
        from sashelp.vcolumn
        where libname = upcase("&lib_nam")
        and upcase(memname) = upcase("&ds_nam")
     %if %qlowcase(&allsort) ne n %then order by name ;
        ;
     quit;
   %end;

   %* 15-9-2011 een voor een de labels ophalen en niet in bulk (wat tot 15-9-2011 wel gebeurde) zodat de volgorde van de labels;
   %* overeenkomt met de volgorde van de variabelen.;
   %* 5-11-2011 Hoewel je zou denken dat in de vorige stap de case van de varnaam in de macrovars var_nr bewaard zouden blijven;
   %* blijkt dat niet het geval. Vandaar een upcase om de name en om de var_nr macrovar in de where clause.;
   %if %qlowcase(&label) ne n %then %do;
     proc sql noprint;
       %do iLoop9=1 %to &no_vars;
         select coalesce(label,name) into :label_&iLoop9
         from sashelp.vcolumn
         where libname       = upcase("&lib_nam")
         and upcase(memname) = upcase("&ds_nam")
         and upcase(name)    = upcase("&&var_&iLoop9");
         %let label_&iLoop9=&&label_&iLoop9; %* leading and lag zeros verwijderen;
       %end;
     quit;
   %end;

   %* als er een colour_key gezet is, dan sorteren op die key;
   %if &colour_key ne %then %do;
      %let col_last_var = %scan(&colour_key,-1);
      %srt( &lib_nam , &ds_nam, &colour_key );
      data ff_colour;
          set &lib_nam..&ds_nam
           %if %bquote(&where) ne %then %do;
               ( where = ( &where ))
           %end; ;
          by &colour_key;
          retain colour -1  colFirstRow;
          keep              colFirstRow colLastRow;

          if _N_ = 1 then rownr = &first_row + (upcase("&varnam") ne 'N') + (upcase("&label") ne 'N') -1;

          &extra_sas_code;

          rownr+1;

          if first.&col_last_var then do;
                   colour = colour * -1;
                   colFirstRow = rownr;
          end;
          if last.&col_last_var and colour = 1 then do;
                   colLastRow  = rownr;
                   output;
          end;
      run;
   %end;

   %* als er al .xlt of .xls achter het workbook naam staat niet nog een keer .xls erachter plakken;
   data _null_;
     if not( index( "&wb_nam" , '.xlt' ) or index( "&wb_nam", '.xls')) then
     call symput( "wb_nam", left(trim("&wb_nam"))||'.xls' );
   run;

   filename ex_blok
            dde
            "excel|[&wb_nam]&ws_nam.!r&first_row.&kol_col.&first_col:r&last_row.&kol_col.&last_col"
            notab
            lrecl=8192 ;

   options missing=''; %* geen puntjes voor missing numerieke values, maar blanks ;
   data _null_;
     set &lib_nam..&ds_nam
     %if %bquote(&where) ne %then %do;
        ( where = ( &where ))
     %end;
     ;
     file ex_blok ;

     %if %qlowcase(&label) ne n and %qlowcase(&label_first) ne n %then %do;
       if _N_ = 1 then put %do iv = 1 %to &no_vars ; "&&label_&iv" '09'x %end; ;
     %end;
     %if %qlowcase(&varnam) ne n %then %do;
       if _N_ = 1 then put %do iv = 1 %to &no_vars ; "&&var_&iv" '09'x %end; ;
     %end;
     %if %qlowcase(&label) ne n and %qlowcase(&label_first) = n %then %do;
       if _N_ = 1 then put %do iv = 1 %to &no_vars ; "&&label_&iv" '09'x %end; ;
     %end;

     %* verwijderen van CR  en LF ;
     %do iv = 1 %to &no_vars ;
          &&var_&iv = translate(&&var_&iv , '', '0D'x, '', '0A'x ) ;
     %end;
     &extra_sas_code ; ;
     %* wegschrijven naar excel spreadsheet ;
     put %do iv = 1 %to &no_vars ; &&var_&iv +(-1) '09'x  %end; ;
   run;

   %if &colour_key ne %then %do;
      data _null_;
          set ff_colour;
          call execute('%excel_format( %superq(ws_nam), ' || put(colFirstRow, 6.) || ', &first_col , ' 
                      ||  put(colLastRow, 6.) || ', &last_col, background_col= &kleur );');
      run;
   %end;
   options missing='.' &m_notes8;
%mend excel_write_block;

/*---------------------------------------------------------------------------*\
| excel_write_macro_vars                                                      |
| Om een opgegeven reeks van macro vars weg te schrijven                      |
|                                                                             |
| Positionele parameters:                                                     |
| vars   = reeks van macro vars gescheiden door spaties                       |
| first_row, first_col, = evident                                             |
| wb_nam = workbook naam (met of zonder .xls erachter)                        |
| ws_nam = worksheet naam                                                     |
| Named parameters:                                                           |
| down_right = is of hij naar beneden schrijft (down) of naar rechts toe      |
\----------------------------------------------------------------------------*/
%put compiling macro excel_write_macro_vars;
%macro excel_write_macro_vars( vars, first_row, first_col, wb_nam, ws_nam, down_right = down );
  %let m_notes9 = %sysfunc(getoption ( notes ));
  options nonotes;

  %let i_vars = 1;
  %do %while (%qscan( &vars, &i_vars ) ne );
         %let var_&i_vars =  &&%scan( &vars, &i_vars );
         %let no_vars = &i_vars;
         %let i_vars = %eval( &i_vars + 1);
   %end; %* end loop over while ;
   %if %qupcase(&down_right) = DOWN  %then %do;
      %let last_row = %eval( &first_row + &no_vars -1 );
      %let last_col = &first_col;
   %end;
   %else %do;
      %let last_row = &first_row ;
      %let last_col = %eval( &first_col + &no_vars -1 );
   %end;

   %* als er al .xlt of .xls achter het workbook naam staat niet nog een keer .xls erachter plakken;
   data _null_;
     if not( index( "&wb_nam" , '.xlt' ) or index( "&wb_nam", '.xls')) then
     call symput( "wb_nam", left(trim("&wb_nam"))||'.xls' );
   run;

   filename ex_blok dde "excel|[&wb_nam]&ws_nam.!r&first_row.&kol_col.&first_col:r&last_row.&kol_col.&last_col" notab;

   data _null_;
     file ex_blok ;
     put %do iv = 1 %to &no_vars ;
                "&&var_&iv"  %if %qupcase(&down_right) = DOWN %then / ; %else '09'X ;
         %end; ;
   run;
   options &m_notes9;
%mend excel_write_macro_vars;

/*---------------------------------------------------------------------------*\
| excel_write_fixed_text                                                      |
| Om stukken tekst in cellen weg te schrijven                                 |
|                                                                             |
| Positionele parameters:                                                     |
| teksten = alle teksten, gescheiden door sep (zie named parameters) achter   |
|           elkaar                                                            |
| first_row, first_col = evident                                              |
| wb_nam = workbook naam                                                      |
| wS_nam = worksheet naam                                                     |
|                                                                             |
| Named Parameters:                                                           |
| down_right = of je gaat vanaf de eerste cel naar beneden, of je gaat naar   |
|              rechts toe.                                                    |
| sep = teksten opknippen in kleinere teksten door sep te gebruiken.          |
|       default=spatie                                                        |
\----------------------------------------------------------------------------*/
%put compiling macro excel_write_fixed_text;
%macro excel_write_fixed_text ( teksten, first_row, first_col, wb_nam, ws_nam, down_right = down, sep=%str( ) );
   %let m_notes10 = %sysfunc(getoption ( notes ));
   options nonotes;

  %let i_vars = 1;
  %do %while (%qscan( &teksten, &i_vars, %str(&sep) ) ne );
         %let tekst_&i_vars =  %scan( &teksten, &i_vars, %str(&sep) );
         %let no_vars = &i_vars;
         %let i_vars = %eval( &i_vars + 1);
   %end; %* end loop over while ;
   %if %qupcase(&down_right) = DOWN  %then %do;
      %let last_row = %eval( &first_row + &no_vars -1 );
      %let last_col = &first_col;
   %end;
   %else %do;
      %let last_row = &first_row ;
      %let last_col = %eval( &first_col + &no_vars -1 );
   %end;

   %* als er al .xlt of .xls achter het workbook naam staat niet nog een keer .xls erachter plakken;
   data _null_;
     if not( index( "&wb_nam" , '.xlt' ) or index( "&wb_nam", '.xls')) then
     call symput( "wb_nam", left(trim("&wb_nam"))||'.xls' );
   run;

   filename ex_blok dde "excel|[&wb_nam]&ws_nam.!r&first_row.&kol_col.&first_col:r&last_row.&kol_col.&last_col" notab;

   data _null_;
     file ex_blok ;
     put %do iv = 1 %to &no_vars ;
                "&&tekst_&iv"  %if %qupcase(&down_right) = DOWN %then / ; %else '09'X ;
         %end; ;
   run;

   options &m_notes10;
%mend excel_write_fixed_text ;

/*---------------------------------------------------------------------------*\
| excel_add_formula                                                           |
| Zet een formule rondom een blok, met name nuttig voor sommatie              |
|                                                                             |
| Positionele parameters:                                                     |
| wb_nam = workbook naam (zonder .xls erachter!)                              |
| ws_nam = worksheet naam                                                     |
| first_row, first_col, last_row, last_col = evident                          |
|                                                                             |
| Named parameters:                                                           |
| form = formule. Default = som. Maar gemiddelde of max oid kan ook.          |
| in_rows = J/N. Default = J. Als J dan komt formule in alle rows             |
|                             in een vaste col.                               |
| in_cols = J/N. Default = J. Als J dan komt formule in alle cols             |
|                             in een vaste row.                               |
| subtotopt=  getal Default = 9       (sommeren)                              |
| Toegevoegd de formule Subtotaal, deze heeft een extra parameter die         |
|   bepaald wat er berkend wordt. Deze formule heeft als voordeel dat de      |
|   formule dynamisch herberekend wordt bij gebruik van autofilter.           |
| Above_below = of totalen boven het blok of onder het blok moeten worden     |
|   geschreven.                                                               |
|                                                                             |
| subtotopt (functie_getal)is een getal van 1 tot 11 (incl verborgen waarden) |
| of van 101 tot 111 (excl verborgen waarden) dat aangeeft welke functie      |
| moet worden gebruikt voor de subtotaalberekening in een lijst.              |
|                                                                             |
| Functie_getal   Functie                                                     |
|---------------------------                                                  |
|     1           GEMIDDELDE                                                  |
|     2           AANTAL                                                      |
|     3           AANTALARG                                                   |
|     4           MAX                                                         |
|     5           MIN                                                         |
|     6           PRODUCT                                                     |
|     7           STDEV                                                       |
|     8           STDEVP                                                      |
|     9           SOM                                                         |
|     10          VAR                                                         |
|     11          VARP                                                        |
|(inclusief verborgen waarden) onderstaand nummer,                            |
| anders + 100 voor (exclusief verborgen waarden)                             |
\----------------------------------------------------------------------------*/
%put compiling macro excel_add_formula;
%macro tr_c_nam (col_no, col_nam);
    %* vertalen van kolom nummers naar colom alphabet namen a-z, aa-az, ba-bz etc.;
    letters_voor = int ( (&col_no - 1 ) / 26 ); * aantal letters aan voorkant     ;
    letters_na   = mod ( (&col_no ) , 26 );     * aantal letters aan achterkant   ;
    if letters_na = 0 then letters_na =  26 ;
    %* de byte functie vertaalt een getal in een ASCII teken, 1+64=A, 2+64=B etc. ;
    if letters_voor > 0 then
           &col_nam = byte( letters_voor + 64 ) || byte( letters_na + 64 );
                        else
           &col_nam = ( byte( letters_na + 64 ));
%mend tr_c_nam;

%macro excel_add_formula ( wb_nam, ws_nam, first_row, first_col, last_row, last_col
                         , form=som, in_cols=J, in_rows=J , subtotopt=9
                         , above_below=below
                         );
  %let m_notes11 = %sysfunc(getoption ( notes ));
  options nonotes;

  %let no_row = %eval( &last_row - &first_row + 1 );
  %let no_col = %eval( &last_col - &first_col + 1 );
  %let wri_col = %eval( &last_col + 1 );
  %let wri_row = %eval( &last_row + 1 );
  %if %upcase(&above_below)=ABOVE %then %let wri_row = %eval( &first_row - 1 );

  %* als er al .xlt of .xls achter het workbook naam staat niet nog een keer .xls erachter plakken;
  data _null_;
    if not( index( "&wb_nam" , '.xlt' ) or index( "&wb_nam", '.xls')) then
    call symput( "wb_nam", left(trim("&wb_nam"))||'.xls' );
  run;

  %* eerst de rijen schrijven (dus in de laatste kolom+1) ;
  %if %qlowcase(&in_rows) ne n %then %do;
      filename ex_col dde
               "excel|[&wb_nam]&ws_nam!r&first_row.&kol_col.&wri_col.:r&last_row.&kol_col.&wri_col."
               notab lrecl=8192 ;

      data _null_   ;
        file ex_col ;
        %tr_c_nam( &first_col, first_col_nam );
        %tr_c_nam( &last_col , last_col_nam  );

        do i = &first_row to &last_row ;
            if lowcase("&form")="subtotaal" THEN row_tekst = compress( "=&form.(&subtotopt;" || first_col_nam || i || ":" || last_col_nam || i || ")" );
                                            ELSE row_tekst = compress( "=&form.(" || first_col_nam || i || ":" || last_col_nam || i || ")" );
            put row_tekst ;
        end;
      run;
      filename ex_col;
  %end;

  %* en dan nu de kolommen schrijven ( dus in de laatste row+1 ) ;
  %if %qlowcase(&in_cols) ne n %then %do;
    filename ex_row dde
             "excel|[&wb_nam]&ws_nam!r&wri_row.&kol_col.&first_col.:r&wri_row.&kol_col.&last_col."
             notab lrecl=8192 ;

    data _null_   ;
    file ex_row ;
      do i = &first_col to &last_col ;
          %tr_c_nam( i , col_nam );
          if lowcase("&form")="subtotaal" THEN col_tekst = compress( "=&form.(&subtotopt.;"  || col_nam || &first_row || ":" || col_nam || &last_row || ")" );
                                          ELSE col_tekst = compress( "=&form.(" || col_nam || &first_row || ":" || col_nam || &last_row || ")" );

          put col_tekst '09'x @ ;
      end;
    run;
    filename ex_row;
  %end;

  %* en als laatste alleen maar wegschrijven als het de formule SOM betreft ;
  %if %qlowcase(&in_cols) ne n and
      %qlowcase(&in_rows) ne n and
      %qlowcase(&form)=som %then %do;
                                     filename ex_punt dde
                                              "excel|[&wb_nam]&ws_nam!r&wri_row.&kol_col.&wri_col.:r&wri_row.&kol_col.&wri_col."
                                              notab lrecl=8192 ;

                                     data _null_   ;
                                        file ex_punt ;
                                        %tr_c_nam( &first_col   , first_col_nam );
                                        %tr_c_nam( &last_col    , last_col_nam  );
                                        tekst = compress( "=som(" || first_col_nam || &wri_row || ":" || last_col_nam || &wri_row || ")" );
                                        put tekst '09'x @ ;
                                     run;
                                     filename ex_punt;
                                %end;  %* en als laatste alleen maar wegschrijven als het de som betreft ;
  %* en als laatste alleen maar wegschrijven als het de formule SUBTOTAAL betreft ;
  %if %qlowcase(&in_cols) ne n and
      %qlowcase(&in_rows) ne n and
      %qlowcase(&form)=subtotaal %then %do;
                                     filename ex_punt dde
                                              "excel|[&wb_nam]&ws_nam!r&wri_row.&kol_col.&wri_col.:r&wri_row.&kol_col.&wri_col."
                                              notab lrecl=8192 ;

                                     data _null_   ;
                                        file ex_punt ;
                                        %tr_c_nam( &first_col   , first_col_nam );
                                        %tr_c_nam( &last_col    , last_col_nam  );
                                        tekst = compress( "=SUBTOTAAL(&subtotopt;"  || first_col_nam || &wri_row || ":" || last_col_nam || &wri_row || ")" );
                                        put tekst '09'x @ ;
                                     run;
                                     filename ex_punt;
                                %end;
  options &m_notes11;
%mend excel_add_formula;

/*----------------------------------------------------------------------------+
| excel_hide_worksheet                                                        |
| verbergt een worksheet                                                      |
| POSITIONAL PARAMETERS:                                                      |
| ws_nam: naam van worksheet in actieve workbook.                             |
| NAMED PARAMETERS:                                                           |
| very_hidden: TRUE dan komt tabblad ook niet meer voor in lijstje wat weer   |
|    zichtbaar gemaakt kan wordtn. FALSE is de default                        |
+----------------------------------------------------------------------------*/
%put compiling macro excel_hide_worksheet;
%macro excel_hide_worksheet(ws_nam, very_hidden=FALSE);
   %let m_notes12 = %sysfunc(getoption ( notes ));
   options noxwait nonotes;

    FILENAME sas2xl DDE 'excel|system';
    DATA _NULL_;
       FILE sas2xl;
       PUT "[WORKBOOK.HIDE(""&ws_nam"", ""&very_hidden"")]";
    RUN;

   options &m_notes12;
%mend excel_hide_worksheet ;

/*----------------------------------------------------------------------------+
| excel_unhide_worksheet                                                      |
| toont een al dan niet verborgen worksheet                                   |                                               |
| POSITIONAL PARAMETERS:                                                      |
| ws_nam: naam van worksheet in actieve workbook.                             |
+----------------------------------------------------------------------------*/
%put compiling macro excel_unhide_worksheet;
%macro excel_unhide_worksheet(ws_nam);
   %let m_notes13 = %sysfunc(getoption ( notes ));
   options noxwait nonotes;

    FILENAME sas2xl DDE 'excel|system';
    DATA _NULL_;
       FILE sas2xl;
       PUT "[WORKBOOK.UNHIDE(""&ws_nam"")]";
    RUN;

   options &m_notes13;
%mend excel_unhide_worksheet ;

/*---------------------------------------------------------------------------*\
| excel_delete_rc                                                             |
| gooit een of meerdere rij(en) of colom(men) weg en schuift de rest op       |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| fr, tto = 1e en laatste rij/kolom om weg te gooien. Default voor tto=fr.    |
|                                                                             |
| Named Parameters:                                                           |
| rc = col / row  = of kolom of rijen weg                                     |
|      default = col                                                          |
\----------------------------------------------------------------------------*/
%put compiling macro excel_delete_rc;
%macro excel_delete_rc( ws_nam , fr , tto ,rc=col );
  %let m_notes14 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  %if &tto = %then %let tto = &fr;
  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     %if %qlowcase(&rc)=col %then %do;
       put "[select(""r1&kol_col&fr.:r1&kol_col&tto."")]";
       put "[edit.delete(4)]";
     %end;
     %else %do;
       put "[select(""r&fr&kol_col.1:r&tto&kol_col.1"")]";
       put "[edit.delete(3)]";
     %end;
  run;

  options &m_notes14;
%mend excel_delete_rc ;

/*---------------------------------------------------------------------------*\
| excel_delete_block                                                          |
| gooit een block cellen weg en schuift de rest op                            |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| fr, tto = 1e en laatste rij/kolom om weg te gooien. Default voor tto=fr.    |
|                                                                             |
| Named Parameters:                                                           |
| rc = col / row  = of kolom of rijen weg                                     |
|      default = col                                                          |
\----------------------------------------------------------------------------*/
%put compiling macro excel_delete_block;
%macro excel_delete_block( ws_nam , from_row , from_col, to_row, to_col, shift=left );
  %let m_notes14a = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  %if %qlowcase(&shift)=left %then %let shift_num=1;
                             %else %let shift_num=2;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     put "[select(""r&from_row.&kol_col.&from_col.:r&to_row.&kol_col.&to_col."")]";
     put "[edit.delete(&shift_num)]";
  run;

  options &m_notes14a;
%mend excel_delete_block;

/*---------------------------------------------------------------------------*\
| excel_insert_rc                                                             |
| voegt een of meerdere rij(en) of colom(men) toe en schuift de rest op       |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| fr = rij of kolom waarVOOR de extra rij(en) / kolom(men) komen              |
| no_rc = aantal rijen/kolommen die worden toegevoegd. Default=1              |
|                                                                             |
| Named Parameters:                                                           |
| rc = col / row  = of kolom of rijen toevoegen                               |
|      default = col                                                          |
\----------------------------------------------------------------------------*/
%put compiling macro excel_insert_rc;
%macro excel_insert_rc( ws_nam, fr, no_rc, rc=col );
   %let m_notes15 = %sysfunc(getoption ( notes ));
   options noxwait nonotes;

   %if &no_rc= %then %let no_rc = 1 ;

   filename sas2xl dde 'excel|system';
   data _null_;
      file sas2xl;
      put '[error(false)]';
      put "[workbook.activate(""&ws_nam"")]";
      %if %qlowcase(&rc)=col %then %do;
         put "[select(""r1&kol_col&fr.:r1&kol_col&fr"")]";
         %do i_lp1 = 1 %to &no_rc;
           put "[insert(4)]";
         %end;
      %end;
      %else %do;
         put "[select(""r&fr&kol_col.1:r&fr&kol_col.1"")]";
         %do i_lp1 = 1 %to &no_rc;
           put "[insert(3)]";
         %end;
       %end;
   run;

   options &m_notes15;
%mend excel_insert_rc ;

/*---------------------------------------------------------------------------*\
| excel_format                                                                |
| formateer een blok cellen                                                   |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| from_row, from_col = definieert de uiterste top links bovenhoek van blok    |
| to_row, to_col     = definieert de uiterste bodem rechts onderhoek van blok |
|                                                                             |
| Named Parameters:                                                           |
| font en size = evident                                                      |
| bold, italic, underline, strikethrough, outline en shadow = true of false   |
|              False is de default                                            |
| color = 0 betekent automatic coloring, anders een kleur tussen de 1 en 56.  |
| numb om een numeriek format mee te geven. Meest populair zal zijn #0,00     |
|   echter, let op, daar zit een comma in en dat kan gezien worden als        |
|   scheidingsteken tussen parameters. Dus, geef mee als %str(#0,00)          |
| of numb=%bquote([$-413]d mmmm jjjj) om format op 1 februari 2006 te zetten  |
| 3 = rood, 4 = lichtgroen, 5 = blauw, 6 = geel, 7 = paars, 36 = lichtgeel    |
| 15=lichtgrijs                                                               |
| background_col=                                                             |
\----------------------------------------------------------------------------*/
%put compiling macro excel_format;
%macro excel_format( ws_nam , from_row , from_col, to_row, to_col,
                     font=, size=, bold=false, italic=false, underline=false,
                     strikethrough=false, color=0, outline=false, shadow=false,
                     numb=, background_col=
                   );
  %let m_notes16 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;
  %let ws_nam = %superq(ws_nam);

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     put "[select(""r&from_row&kol_col&from_col.:r&to_row&kol_col&to_col."")]";
     put "[format.font(""&font"",&size,&bold,&italic,&underline,&strikethrough,&color,&outline,&shadow)]";
     %if &numb ne %then %do;
        put "[format.number(""&numb"")]";
     %end;
     %if &background_col ne %then %do;
        put "[patterns(1, 0, &background_col )]";
     %end;
  run;

  options &m_notes16;
%mend excel_format ;

/*---------------------------------------------------------------------------*\
| excel_border                                                                |
| zet lijnen om cellen heen, geef die lijnen een kleurtje                     |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| from_row, from_col = definieert de uiterste top links bovenhoek van blok    |
| to_row, to_col     = definieert de uiterste bodem rechts onderhoek van blok |
|                                                                             |
| Named Parameters:                                                           |
| outline, left, right, top, bottom = 0 (geen, default), 1(Thin line),        |
|          2 (Medium line), 3 (Dashed line), 4 (Dotted line), 5 (Thick line)  |
|          6 (Double line), 7 (Hairline)                                      |
| shade=FALSE / TRUE, default = false, vlak van cel wordt gevuld (eigenlijk   |
|          niets met border te maken)                                         |
| outline_c, left_c, right_c, top_c, bottom_c de kleuren van de lijnen,       |
|          waarden van 0 (automatic, default) tm 56                           |
\----------------------------------------------------------------------------*/
%put compiling macro excel_border;
%macro excel_border( ws_nam , from_row , from_col, to_row, to_col
                   , outline=0, left=0, right=0, top=0, bottom=0
                   , shade=FALSE
                   , outline_c=0, left_c=0, right_c=0, top_c=0, bottom_c=0
                   );
  %let m_notes18 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     put "[select(""r&from_row&kol_col&from_col.:r&to_row&kol_col&to_col."")]";
     put "[border(&outline, &left, &right, &top, &bottom, &shade, &outline_c, &left_c, &right_c, &top_c, &bottom_c)]";
  run;

  options &m_notes18;
%mend excel_border ;

/*---------------------------------------------------------------------------*\
| excel_pattern                                                               |
| zet pattern van cellen en geef dit pattern een kleurtje                     |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| from_row, from_col = definieert de uiterste top links bovenhoek van blok    |
| to_row, to_col     = definieert de uiterste bodem rechts onderhoek van blok |
|                                                                             |
| Named Parameters:                                                           |
| pattern = waarden tussen 0 en 18, 0 is geen pattern, 1 = solid              |
| afore   = kleurnummer tussen 0 en 56 voor area foreground colors            |
| aback   = kleurnummer tussen 0 en 56 voor area background colors            |
| 3 = rood, 4 = lichtgroen, 5 = blauw, 6 = geel, 7 = paars, 36 = lichtgeel    |
| 15=lichtgrijs                                                               |
\----------------------------------------------------------------------------*/
%put compiling macro excel_pattern;
%macro excel_pattern( ws_nam , from_row , from_col, to_row, to_col
                    , pattern=0,afore=0,aback=0
                    );
  %let m_notes19 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     put "[select(""r&from_row&kol_col&from_col.:r&to_row&kol_col&to_col."")]";
     put "[patterns(&pattern,&afore,&aback,true)]";
  run;

  options &m_notes19;
%mend excel_pattern ;

/*---------------------------------------------------------------------------*\
| excel_column_width                                                          |
| Instellen van de breedte van excel kolommen                                 |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| from_col, to_col = definieert de kolom range waarover we het hebben         |
| type_width = H ==> hide the column                                          |
|              U ==> unhide the column                                        |
|              B ==> best fit                                                 |
|              getal ==> breedte "in units of characters of the font used"    |
| from_row, to_row = alleen van belang bij bepalen best fit, want alleen      |
|                    deze rijen doen daarin mee, mag leeg laten.              |
\----------------------------------------------------------------------------*/
%put compiling macro excel_column_width;
%macro excel_column_width ( ws_nam , from_col, to_col, type_width, from_row, to_row );
  %let m_notes20 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     %if &from_row = %then %do;
       put "[select(""&kol_col&from_col.:&kol_col&to_col."")]";
     %end;
     %else %do;
       put "[select(""R&from_row.&kol_col&from_col.:R&to_row.&kol_col&to_col."")]";
     %end;
     %if %qupcase(&type_width)=H %then %do;
       put "[column.width( , ,""FALSE"",1)]";
     %end;
     %else %if %qupcase(&type_width)=U %then %do;
       put "[column.width( , ,""FALSE"",2)]";
     %end;
     %else %if %qupcase(&type_width)=B %then %do;
       put "[column.width( , ,""FALSE"",3)]";
     %end;
     %else %do;
       put "[column.width(&type_width,,""FALSE"")]";
     %end;
  run;

  options &m_notes20;
%mend excel_column_width ;

/*---------------------------------------------------------------------------*\
| excel_zoom                                                                  |
| in en uitzoomen                                                             |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| zoom_factor = 1) percentage om view mee te wijzigen, tussen de 0 en 400.    |
|               2) als TRUE of leeg dan wordt de huidige selectie geheel      |
|                  uitgevuld.                                                 |
| Als je zoom_factor = TRUE of leeg laat dan worden de volgende 4 parameters  |
|   gebruikt om de selectie te bepalen (of 2 ervan als je alleen kolommen of  |
|  alleen rijen wil):                                                         |
| from_col = evident                                                          |
| to_col   = evident                                                          |
| from_row = evident                                                          |
| to_row   = evident                                                          |
|                                                                             |
| Named Parameters:                                                           |
| Geen                                                                        |
|                                                                             |
| Voorbeelden:                                                                |
| excel_zoom( blad1, 40 )  ==> 40% gebruikt                                   |
| excel_zoom( blad1, 40, 3, 10 )  ==> 40% gebruikt, de from_col en to_col     |
|                                     hebben geen invloed                     |
| excel_zoom( blad1, TRUE, 5, 10 ) ==> kolom 5 tm 10 worden gebruikt om de    |
|     zoomfactor te bepalen, dusdanig dat ze de breedte van scherm vullen.    |
| excel_zoom( blad1, , 5, 10 ) ==> zelfde als vorige.                         |
| excel_zoom( blad1, , , , 1, 10) ==> rows 1 tm 10 worden gebruikt om de      |
|     zoomfactor te bepalen, dusdanig dat ze de hoogte  van scherm vullen.    |
|                                                                             |
\----------------------------------------------------------------------------*/
%put compiling macro excel_zoom;
%macro excel_zoom( ws_nam , zoom_factor, from_col, to_col, from_row, to_row );
  %let m_notes21 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     %if %bquote(&zoom_factor) = or %bquote(&zoom_factor) = TRUE %then %do;
        %if %bquote(&from_col) ne and %bquote(&to_col) ne %then %do;
          %if %bquote(&from_row) ne and %bquote(&to_row) ne %then %do;
             put "[select(""R&from_row.&kol_col&from_col.:R&to_row.&kol_col&to_col."")]";
          %end;
          %else %do;
             put "[select(""&kol_col&from_col.:&kol_col&to_col."")]";
          %end;
        %end;
        %else %if %bquote(&from_row) ne  and %bquote(&to_row) ne %then %do;
             put "[select(""R&from_row.:R&to_row."")]";
        %end;
        put "[zoom]";
     %end;
     %else %do;
        put "[zoom( &zoom_factor )]";
     %end;
  run;

  options &m_notes21;
%mend excel_zoom ;

/*---------------------------------------------------------------------------*\
| excel_row_height                                                            |
| tja, wat zou deze nu doen?                                                  |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| from_row, to_row = definieert de row range waarover we het hebben           |
| type_height= H ==> hide the row                                             |
|              U ==> unhide the row                                           |
|              B ==> best fit                                                 |
|              getal ==> hoogte "in points"                                   |
| from_col, to_col = allen van belang bij bepalen best fit, want alleen       |
|                    deze kolommen doen daarin mee, mag leeg laten.           |
\----------------------------------------------------------------------------*/
%put compiling macro excel_row_height;
%macro excel_row_height ( ws_nam , from_row, to_row, type_height, from_col, to_col );
  %let m_notes22 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     %if &from_col = %then %do;
       put "[select(""R&from_row.:R&to_row."")]";
     %end;
     %else %do;
       put "[select(""R&from_row.&kol_col&from_col.:R&to_row.&kol_col&to_col."")]";
     %end;
     %if %qupcase(&type_height)=H %then %do;
       put "[row.height(,,,1)]";
     %end;
     %else %if %qupcase(&type_height)=U %then %do;
       put "[row.height(,,,2)]";
     %end;
     %else %if %qupcase(&type_height)=B %then %do;
       put "[row.height(,,,3)]";
     %end;
     %else %do;
       put "[row.height(&type_height,,""FALSE"")]";
     %end;
  run;

  options &m_notes22;
%mend excel_row_height ;

/*---------------------------------------------------------------------------*\
| excel_titels_blokkeren                                                      |
| tja, wat zou deze nu doen?                                                  |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| row_split, col_split = definieert het punt waar de split komt               |
|                                                                             |
| Named parameters:                                                           |
| split = TRUE (default), FALSE = titels blokkeren juist ongedaan maken       |
\----------------------------------------------------------------------------*/
%put compiling macro excel_titels_blokkeren;
%macro excel_titels_blokkeren ( ws_nam , row_split, col_split, split=TRUE );
  %let m_notes23 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  %if %qupcase(&split) ne FALSE %then %let split=TRUE;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     put "[freeze.panes(""&split"", &col_split , &row_split )]";
  run;

  options &m_notes23;
%mend excel_titels_blokkeren ;

/*---------------------------------------------------------------------------*\
| excel_align                                                                 |
| links, midden of rechts uitlijnen van cellen                                |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| from_row, from_col = definieert de uiterste top links bovenhoek van blok    |
| to_row, to_col     = definieert de uiterste bodem rechts onderhoek van blok |
| align              = L, C, R links, centre, rechts, default = links         |
| wraptext           = definieert de uitlijning , TRUE of FALSE               |
|                                                                             |
| Named Parameters:                                                           |
| geen                                                                        |
\----------------------------------------------------------------------------*/
%put compiling macro excel_align;
%macro excel_align( ws_nam , from_row , from_col, to_row, to_col, align, wraptext );
  %let m_notes24 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xl dde 'excel|system';
  %let al = 2;
  %if %qupcase(&align)=C %then %let al = 3;
  %if %qupcase(&align)=R %then %let al = 4;
  %if %qupcase("&wraptext") = "TRUE" or %qupcase("&wraptext") = "FALSE" %then %let al = &al , &wraptext;
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     put "[select(""r&from_row&kol_col&from_col.:r&to_row&kol_col&to_col."")]";
     put "[alignment(&al)]";
  run;

  options &m_notes24;
%mend excel_align ;

/*---------------------------------------------------------------------------*\
| excel_insert_ws                                                             |
| insert een worksheet                                                        |
|                                                                             |
| Positionele parameters:                                                     |
| wb_nam = workbooknaam                                                       |
\----------------------------------------------------------------------------*/
%put compiling macro excel_insert_ws;
%macro excel_insert_ws( wb_nam );
  %let m_notes25 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  %* als er al .xlt of .xls achter het workbook naam staat niet nog een keer .xls erachter plakken;
  data _null_;
     if not( index( "&wb_nam" , '.xlt' ) or index( "&wb_nam", '.xls')) then
     call symput( "wb_nam", left(trim("&wb_nam"))||'.xls' );
  run;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.next()]";
     put "[workbook.insert(1)]";
*     put "[workbook.move(""blad1"", ""&wb_nam"",1)]";
  run;

  options &m_notes25;
%mend excel_insert_ws ;

/*---------------------------------------------------------------------------*\
| excel_rename_ws                                                             |
| rename een worksheet                                                        |
| binnen een sas sessie wordt er een counter bijgehouden, rename_cc           |
| Als je binnen een sessie in meerdere workbooks sheets wil renamen dan       |
| moet je bij start nieuwe spreadsheet first = Y zetten                       |
|                                                                             |
| Positionele parameters:                                                     |
| wb_nam = workbooknaam                                                       |
| old_ws_nam = oude worksheetnaam                                             |
| new_ws_nam = nieuwe worksheetnaam                                           |
|                                                                             |
| Named parameters:                                                           |
| first = N/Y, als het de eerste ws is van een workbook die hernoemd wordt    |
| dan first=Y zetten, default is N. Let op, er wordt verwacht dat alle        |
| renames bij een workbook achter elkaar staan, dus niet door elkaar heen,    |
| dus de volgende aanroep is NIET OK.                                         |
|   %excel_rename_ws ( wb1, old1, new1, first=Y )                             |
|   %excel_rename_ws ( wb2, old2, new2, first=Y )                             |
|   %excel_rename_ws ( wb1, old3, new3, first=N )                             |
| maar de volgende wel                                                        |
|   %excel_rename_ws ( wb1, old1, new1, first=Y )                             |
|   %excel_rename_ws ( wb1, old3, new3, first=N )                             |
|   %excel_rename_ws ( wb2, old2, new2, first=Y )                             |
\----------------------------------------------------------------------------*/
%put compiling macro excel_rename_ws;
%macro excel_rename_ws ( wb_nam, old_ws_nam, new_ws_nam, first=N );
  %let m_notes26 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;
  %put excel_rename_ws van &old_ws_nam naar &new_ws_nam;


  %global rename_cc ;
  %if %qlowcase(&first) ne n or &rename_cc =
           %then %let rename_cc = 1 ;
           %else %let rename_cc = %eval( &rename_cc + 1 );

  filename sas2xl dde 'excel|system' ;

  data _null_;
     file sas2xl;
     put '[error(false)]';
     put '[workbook.next()]'   ; %* zeker weten dat je maar 1 worksheet hebt geselecteerd;
     put '[workbook.insert(3)]'; %* insert een macrosheet;
  run;

  filename xlmacro dde "excel|Macro&rename_cc.!r1&kol_col.1:r3&kol_col.1" notab lrecl=200;

  %* Omdat bij het hernoemen van de sheets SAS er soms zomaar meet stopt een aantal ;
  %* sleeps ingevoegd ;

  %let slept = %sysfunc(sleep(1));

  data _null_;

    file xlmacro;
    put '=werkmap.naam("' "&old_ws_nam" '";"' "&new_ws_nam" '")';
    put '=stoppen(waar)';
    put '!dde_flush';

    wachten=sleep(1);

    file sas2xl;
    put "[run(""Macro&rename_cc.!r1&kol_col.1"")]";
    put '[error(false)]';
    put "[workbook.delete(""Macro&rename_cc."")]";

    wachten=sleep(1);
  run;

  filename sas2xl;
  filename xlmacro;

  %let slept = %sysfunc(sleep(1));

  options &m_notes26;
%mend excel_rename_ws ;
/*---------------------------------------------------------------------------*\
| excel_active_cell                                                           |
| maak een bepaalde cel de actieve cel                                        |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| row_num = row nummer van de actieve cel, default = 1                        |
| col_num = kolom nummer van de actieve cel, default = 1                      |
|                                                                             |
| Named parameters:                                                           |
| geen                                                                        |
\----------------------------------------------------------------------------*/
%put compiling macro excel_active_cell;
%macro excel_active_cell( ws_nam, row_num, col_num );
   %let m_notes27 = %sysfunc(getoption ( notes ));
   options noxwait nonotes;

   %if &row_num = %then %let row_num = 1;
   %if &col_num = %then %let col_num = 1;
   FILENAME sas2xl DDE 'excel|system';
   DATA _NULL_;
      FILE sas2xl;
      put '[error(false)]';
      put "[workbook.activate(""&ws_nam"")]";
      put "[select(""r&row_num.&kol_col.&col_num."")]";
   RUN;
   options &m_notes27;
%mend excel_active_cell ;

/*---------------------------------------------------------------------------*\
| excel_copy_paste                                                            |
| copieer een range cellen, je mag over worksheets copieren.                  |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam (tabblad)                                                     |
| first_row last_row last_row last_col = definieer blok                       |
| row_to col_to = top links cel waar je naartoe copieert                      |
| ws_nam_to = als je deze invult, dan is dat de worksheet waar naar           |
|             gecopieerd wordt. Als leeg dan ws_nam_to = ws_nam.              |
|                                                                             |
| Named parameters:                                                           |
| geen                                                                        |
\----------------------------------------------------------------------------*/
%put compiling macro excel_copy_paste;
%macro excel_copy_paste ( ws_nam, first_row, first_col, last_row, last_col, row_to, col_to, ws_nam_to );
    %let m_notes28 = %sysfunc(getoption ( notes ));
    options nonotes;

    FILENAME sas2xl DDE 'excel|system';
    DATA _NULL_;
        FILE sas2xl;
        PUT "[workbook.activate(""&ws_nam"")]";
        PUT "[select(""r&first_row.&kol_col&first_col:r&last_row.&kol_col&last_col"")]";
        PUT "[copy]";
        %if &ws_nam_to ne  and &ws_nam_to ne &ws_nam %then %do;
           PUT "[workbook.activate(""&ws_nam_to"")]";
        %end;
        PUT "[select(""r&row_to.&kol_col&col_to"")]";
        PUT "[paste]";
    RUN;
   options &m_notes28;
%mend excel_copy_paste;

/*---------------------------------------------------------------------------*\
| excel_clear_block                                                           |
| een blok cellen schoonvegen                                                 |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| first_row, first_col, last_row, last_col definieren het blok dat wordt      |
| ge-cleared                                                                  |
|                                                                             |
\----------------------------------------------------------------------------*/
%put compiling macro excel_clear_block;
%macro excel_clear_block ( ws_nam, first_row, first_col, last_row, last_col );
    %let m_notes29 = %sysfunc(getoption ( notes ));
    options nonotes;

    FILENAME sas2xl DDE 'excel|system';
    DATA _NULL_;
       FILE sas2xl;
       PUT "[workbook.activate(""&ws_nam"")]";
       PUT "[select(""r&first_row.&kol_col&first_col:r&last_row.&kol_col&last_col"")]";
       PUT "[clear]";
    RUN;

    options &m_notes29;
%mend excel_clear_block;

/*---------------------------------------------------------------------------*\
| excel_autofilter                                                            |
| Zet autofiltering aan op een worksheet                                      |
|                                                                             |
| Positionele parameters:                                                     |
| ws_nam = worksheetnaam                                                      |
| rel_col = relatieve kolom tov start_col waar eventueel een filter komt      |
|           te staan. Default = 1.                                            |
| filt_crit1 = 1e filter conditie, bv >2                                      |
| ao = leeg (geen 2e filterconditie), and of or voor toevoeging 2e filter     |
|      conditie.                                                              |
| filt_crit2 = 2e filter conditie, bv <7                                      |
|                                                                             |
| Named Parameters:                                                           |
| start_row = Als blok data bv pas op row 15 begint, dan 15 gebruiken.        |
|             Default = 1                                                     |
| start_col = Als blok data bv pas in C kolom begint dan 3. Default = 1       |
| end_col = als je maar op een beperkt aantal kolommen wil filteren, dan hier |
|           aangeven. Default = 255.                                          |
|                                                                             |
| Voorbeelden:                                                                |
| Worksheet WS1 heeft labels in row 1 en data van A2 tm E5.                   |
| %excel_autofilter( WS1 )                                                    |
|  ==> Zet autofilters aan op alle kolommen.                                  |
| %excel_autofilter( WS1, 2, >25 )                                            |
| ==> Zet autofilters aan op alle kolommen, filter op B kolom op >25.         |
| %excel_autofilter( WS1, 2, >25, and, <700 )                                 |
| ==> Zet autofilters aan op alle kolommen, filter op B kolom op >25 en <700. |
| %excel_autofilter( WS1, 2, >25, and, <700, end_col=3 )                      |
| ==> Zet autofilters op kolommen A tm C, filter op B kolom op >25 en <700.   |
|                                                                             |
| Worksheet met naam WS1 heeft labels in D5 tm I5 en data in D6 tm I15.       |
| Excel gebruikt vaak letters voor kolommen, deze macro aanroep getallen.     |
|                                                                             |
| %excel_autofilter( WS1, 2, >25 , start_row=6, start_col=4 )                 |
|    => zet autofiltering aan op alle aanwezig kolommen. Activeer een filter  |
|       (>25) in kolom E (2e kolom relatief aan 4==> 5e kolom)                |
|                                                                             |
\----------------------------------------------------------------------------*/
%put compiling macro excel_autofilter;
%macro excel_autofilter( ws_nam, rel_col, filt_crit1 , ao , filt_crit2
                       , start_row=1, start_col=1, end_col=255 );
  %let m_notes30 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  %if &rel_col = %then %let rel_col = 1; %* filter wordt op start_col gezet;

  %* we zetten een z ervoor zodat and en or niet tot verwarring van de if leiden;
  %if z&ao ne zand and z&ao ne zor and z&ao ne z %then %do;
        %put ER%str()ROR: je moet and of or invullen als je meerdere condities wil;
        %let ao = ;
        %let filt_crit2=;
  %end;
  %let numao=;
  %if z&ao = zand %then %let numao = 1; %* tja, excel = 1 voor de and;
  %if z&ao = zor  %then %let numao = 2; %* tja, excel = 2 voor de or;
  %if &end_col < %eval( &start_col + &rel_col -1 ) %then %do;
        %put ER%str()ROR: end_col te klein: end_col=&end_col start_col=&start_col rel_col =&rel_col;
        %put End_col gezet naar start_col + rel_col - 1;
        %let end_col = %eval( &start_col + &rel_col -1 );
  %end;

  %if &end_col ne 255 %then %do;
    %excel_insert_rc( &ws_nam, %eval(&end_col+1) );
  %end;
  %if &start_col ne 1 %then %do;
    %excel_insert_rc( &ws_nam, &start_col );
    %let start_col = %eval( &start_col + 1 );
    %let end_col   = %eval( &end_col + 1 );
  %end;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     put "[select(""r&start_row.&kol_col.&start_col."")]";
     ;
     %if &filt_crit1 =  %then put "[filter( &rel_col )]";
     %else %if z&ao = z %then put "[filter( &rel_col , ""&filt_crit1"" )]";
                        %else put "[filter( &rel_col , ""&filt_crit1"", &numao, ""&filt_crit2"" )]";
     ;
  run;

  %if &start_col ne 1 %then %do;
    %let start_col = %eval( &start_col - 1 );
    %put sc &start_col;
    %excel_delete_rc( &ws_nam, &start_col );
  %end;
  %if &end_col ne 255 %then %do;
    %if &start_col eq 1 %then %do;
          %excel_delete_rc( &ws_nam, %eval(&end_col + 1) );
    %end;
    %else %do;
          %excel_delete_rc( &ws_nam, &end_col );
    %end;
  %end;

   options &m_notes30;
%mend excel_autofilter ;

* nog af te bouwen en te testen MWZ 24-3-2004 ;
%macro excel_copy_sheet ( sheet_from ) ;
   FILENAME sas2xl DDE 'excel|system';
   DATA _NULL_;
      FILE sas2xl;
      PUT "[workbook.copy(""&sheet_from"")]";
   RUN;
%mend excel_copy_sheet;

/*---------------------------------------------------------*\
| openen van Access-database                                |
| Positionele parameters:                                   |
| xs_f_nam = access-database: volledig pad en naam          |
| Op zich alleen nuttig als je DDE gebruikt, het is veel    |
| makkelijker om OLE DB te gebruiken, dus:                  |
| libname MSAccess1                                         |
|         oledb                                             |
|         provider="Microsoft.Jet.OLEDB.4.0"                |
|         properties=('data source'="Q:\etc\f1.mdb");       |
\----------------------------------------------------------*/
%put compiling macro access_open;
%macro access_open( xs_f_nam );
   %let m_notes31 = %sysfunc(getoption ( notes ));
   options noxwait nonotes;

   filename sas2xs dde 'msaccess|system';
   data _null_;
      length fid rc start stop time 8;
      fid=fopen('sas2xs','s');
      if (fid le 0) then do;
         rc=system("start msaccess ""&xs_f_nam""");
         start=datetime(); 
         stop=start+20;
         do while (fid le 0);
            fid=fopen('sas2xs','s');
            time=datetime();
            if (time ge stop) then fid=1;
         end;
      end;
      rc=fclose(fid);
   run;

  options &m_notes31;
%mend access_open ;

/*---------------------------------------------------------*\
| sluiten van Access                                        |
\----------------------------------------------------------*/
%put compiling macro access_close;
%macro access_close;
  %let m_notes32 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xs dde 'msaccess|system';
  data _null_;
     file sas2xs;
     *put '[error(false)]';
     *put '[file.close(false)]';
     put '[quit]';
  run;

  options &m_notes32 ;
%mend access_close ;

/*-------------------------------------------------------------------------------*\
| 1) als je Excel V2002 hebt (en dat hebben we op onze laptops) zorg dan dat      |
|    onder Extra, Macro, Beveiliging                                              |
|    a) tabblad betrouwbare bronnen beide vinkjes aanstaan en bij                 |
|    b) tabblad beveiligingsniveau op laag zetten (anders krijg je pop-up box     |
|    met vraag of je macros echt wil inschakelen, en dat wil je niet elke keer    |
|    doen!)                                                                       |
| 2) zorg zelf dat excel is afgesloten                                            |
| 3) Maak in SAS een file met extensie .BAS aan in een flat file. De naam van     |
|    deze macro MOET hetzelfde zijn als de naam van de file. Je kan dit het       |
|    afdwingen door het 1 keer in een macrovar te zetten, zie voorbeeld.          |
| 4) Roep excel_run_vba aan die zorgt dat                                         |
|    a) start Excel                                                               |
|    b) importeert de .BAS file en maakt er een Excel sub van                     |
|    c) voert de sub uit                                                          |
|    d) verwijdert de sub uit Excel                                               |
|    e) verwijder .BAS file uit DOS (default, zie hieronder)                      |
|                                                                                 |
| POSITIONAL PARAMETERS:                                                          |
| wbk_path: pad waar het te openen workbook staat, def = macrovar wbk_path_def    |
| wbk_nam : naam van het te openen workbook staat, def = macrovar wbk_nam_def     |
|           mag met of zonder .xls achter de naam                                 |
| vba_path: pad waar de .bas file staat          , def = macrovar vba_path_def    |
| vba_nam : naam van de .bas file                , def = macrovar vba_nam_def     |
|           mag met of zonder .bas achter de naam                                 |
|                                                                                 |
| LET OP: een korte vba_nam die eindigt met een getal (bv fi3 of ab2) gaat fout!  |
| advies: gebruik geen cijfers in de vba naam. 29-3-2004 MWZ                      |
|                                                                                 |
| NAMED PARAMETERS:                                                               |
| del_prog: Y/N, als niet N dan wordt het .BAS niet verwijderd, als N dan wordt   |
|           het wel verwijderd. Default = Y                                       |
| my_sleep: hoe lang SAS wacht zodat Excel goed opstart, default = 10 seconde     |
\--------------------------------------------------------------------------------*/
%put compiling macro excel_run_vba ;
%macro excel_run_vba ( wbk_path, wb_nam, vba_path, vba_pgm, del_prog=Y, my_sleep=10 );
     options xsync noxwait;

     x 'xcopy /D /E /C /Y q:\macros\persnlk_vba.xls c:\';

     %if %quote(&wbk_path)= %then %let wbk_path = &wbk_path_def ;
     %if %quote(&wb_nam)= %then %let wb_nam = &wb_nam_def ;
     %if %quote(&vba_path)= %then %let vba_path = &vba_path_def ;
     %if %quote(&vba_pgm)= %then %let vba_pgm  = &vba_pgm_def ;

     %* als er al .xlt of .xls achter het workbook naam staat niet nog een keer .xls erachter plakken;
     data _null_;
       if index( "&wb_nam" , '.xlt' ) or index( "&wb_nam", '.xls')  then do;
           len = max( index("&wb_nam", '.xls') , index("&wb_nam", '.xlt') ) ;
           call symput( "wb_nam_ex_xls", substr("&wb_nam", 1, len-1 ));
           call symput( "wb_nam_met_xls", "&wb_nam" );
       end;
       else do;
           call symput( "wb_nam_ex_xls", "&wb_nam" );
           call symput( "wb_nam_met_xls", left(trim("&wb_nam"))||'.xls' );
       end;
     run;

     %* staat er toch .bas achter vba file naam? Dan eraf halen ;
     data _null_;
       if index( upcase("&vba_pgm") , '.BAS' ) then do;
           len = index(upcase("&vba_pgm"), '.BAS');
           call symput( "vba_pgm", substr("&vba_pgm", 1, len-1 ));
       end;
     run;

     %* store variables in DOS environmental variables ;
     data _null_;
       file 'c:\exc_effe.bat';
       put "set WBK_NM=&wb_nam_ex_xls"  /
           "set VBA_PATH=&vba_path"     /
           "set VBA_PGM=&vba_pgm"       /
           'start excel'                ;
     run;

     data _null_;
       call system ( 'c:\exc_effe.bat' );
       x=sleep(&my_sleep);
     run;

     %excel_open_spreadsheet( &wbk_path\&wb_nam_met_xls );

     %excel_open_spreadsheet( c:\persnlk_vba.xls );

     filename sas2xl dde 'excel|system';
     data _null_;
        file sas2xl;
          put "[run(""Persnlk_vba.xls!Import_VBA"")]";
          put "[run(""&vba_pgm"")]";
          put "[run(""Persnlk_vba.xls!Del_a_module"")]";
     run;
     %* remove environmental settings file;
     x "del c:\exc_effe.bat";

     %* if requested, remove the VBA program from the directory structure ;
     %if %qupcase(&del_prog) ne N %then %do;
       x "del &vba_path\&vba_pgm..bas";
     %end;
%mend excel_run_vba;

/* voorbeeld programma
%let wbk_path = c:\temp; * pad waar Excel workbook template staat   ;
%let wb_nam   = mwz    ; * naam van workbook ZONDER .xls erachter   ;
%let vba_path = c:\temp; * pad waar we .BAS file gaan opslaan       ;
%let vba_pgm  = testje ; * naam van .BAS file                       ;

* maak VBA code in flat file c:\temp\testje.BAS ;
data _null_;
  file "&vba_path\&vba_pgm..bas";
  * let op, gebruik ALTIJD als eerste regel de volgende regel, maw         ;
  * de naam van de subroutine binnen excel moet hetzelfde zijn als de naam ;
  * van de flatfile                                                        ;
  put "Sub &vba_pgm()"/
      'Sheets("Blad2").Name = "bbb"'/
      'End Sub';
run;

options macrogen;
%excel_run_vba( &wbk_path, &wb_nam, &vba_path, &vba_pgm);

*** einde voorbeeld programma */


/* *** in Excel in de Persnlk.xls
Sub Import_VBA()

  Dim vba_path     As String
  Dim vba_pgm      As String
  Dim wbk_nm       As String
  Dim vba_filename As String

  vba_path = Environ("VBA_PATH")
  vba_pgm = Environ("VBA_PGM")
  wbk_nm = Environ("WBK_NM")
  vba_filename = vba_path & "\" & vba_pgm & ".bas"

  Workbooks(wbk_nm & ".xls").VBProject.VBComponents.Import vba_filename

End Sub

Sub del_a_module()
  Dim wbk_nm       As String

  wbk_nm = Environ("WBK_NM")

  With Workbooks(wbk_nm & ".xls").VBProject.VBComponents
        .Remove .Item("Module1")
  End With
End Sub
*/

/*----------------------------------------------------------------------------------------------*\
| excel_pagina_instelling                                                                        |
|    Macro om de paginainstellingen aan te passen                                                |
| PAGE.SETUP( head, foot, left, right, top, bot, hdng, grid                                      |
|            , h_cntr, v_cntr, orient, paper_size, scale, pg_num, pg_order                       |
|            , bw_cells, quality, head_margin, foot_margin, notes, draft );                      |
| Bij left, right, top en bot kunnen de marges worden ingesteld                                  |
|     , let op dat dit inches zijn;                                                              |
| Orient : 1 = Portrait  ;                                                                       |
|          2 = Landscape ;                                                                       |
| Papersize : 8 = A3 ;                                                                           |
|             9 = A4 ;                                                                           |
| scale : is a number representing the percentage to increase or decrease the size of the sheet. |
|         All scaling retains the aspect ratio of the original.                                  |
| To specify a percentage of reduction or enlargement, set scale to the percentage.              |
|  For worksheets and macros, you can specify the number of pages that the printout should be    |
|   scaled to fit. Set scale to a two-item horizontal array, with the first item equal to the    |
|   width and the second item equal to the height.                                               |
|   If no constraint is necessary in one direction, you can set the corresponding value to #N/A. |
|  Scale can also be a logical value. To fit the print area on a single page, set scale to TRUE. |
\-----------------------------------------------------------------------------------------------*/
%put compiling macro excel_pagina_instelling;
%macro excel_pagina_instelling ( ws_nam
                               , left_mrgn=0.75,right_mrgn=0.75,top_mrgn=1,bot_mrgn=1
                               , orient=1, papersize=9,scale=100 );
   %let m_notes33 = %sysfunc(getoption ( notes ));
   options nonotes;

   FILENAME sas2xl DDE 'excel|system';
   DATA _NULL_;
      FILE sas2xl;
      PUT "[workbook.activate(""&ws_nam"")]";
      PUT "[PAGE.SETUP(" "," ",&left_mrgn,&right_mrgn,&top_mrgn,&bot_mrgn,False,False,True,False,&orient,&papersize,&scale,1,1,False)]";
      PUT "[clear]";
   RUN;
   FILENAME sas2xl;

  options &m_notes33;
%mend excel_pagina_instelling;

/*----------------------------------------------------------------------------+
| excel_add_workbook                                                          |
| Maakt een nieuwe worksheet aan, ongelukkige benaming van macro, gebruik     |
| liever excel_insert_ws                                                      |
+----------------------------------------------------------------------------*/
%put compiling macro excel_add_workbook;
%macro excel_add_workbook();
  %let m_notes34 = %sysfunc(getoption ( notes ));
  options noxwait nonotes;

  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put "[WORKBOOK.INSERT(1)]";
  run;

  options &m_notes34;
  %put %sysfunc(getoption ( notes ));
%mend excel_add_workbook ;


***********************************************************************************
* Macro om een standaard excel overzicht aan te maken met autofilter
* Indien geen parematers zijn meegegven, dan wordt de laatste aangemaakte tabel gebruikt
* en c:\temp als directory voor het resultaat
* 
* POSITIONAL PARAMETERS:
* Geen
*
* NAMED PARAMETERS:
* invoer       = libname.tabel (libname optioneel)
* excelnaam    = naam exelbestand (zonder .xls erachter)
* exceluitdir  = directory voor excel uitvoer 
*
* Voorbeeld tabel2excel( invoer=work.ff, excelnaam=zz exceluitdit=c:\temp)
***********************************************************************************;
/*%put compiling tabel2excel;*/
/*%macro tabel2excel(invoer=, excelnaam=, exceluitdir=);*/
/*   %let m_notes35 = %sysfunc(getoption ( notes ));*/
/*   options nonotes;*/
/**/
/*   %if "&invoer."   = "" %then %let invoer=&syslast.;*/
/*   %let test=%scan(&invoer ,2);*/
/*   %IF ("&test."="") %then %LET invoer =work.&invoer.;*/
/*   %let inlib            = %scan(&invoer ,1);*/
/*   %let invoertabel      = %scan(&invoer ,2);*/
/*   %let exceltemplate=q:\macros\leeg;*/
/*   %if "&excelnaam."     = "" %then %let excelnaam=&invoertabel._&sysdate.;*/
/*   %if "&exceluitdir."   = "" %then %let exceluitdir= c:\temp;*/
/*   %*Fix eventuele traling \ ;*/
/*   %if "%substr(&exceluitdir.,%length(&exceluitdir.),1)" = "\" %then %let exceluitdir=%substr(&exceluitdir.,1,%eval(%length(&exceluitdir.)-1));*/
/*   %*Check aantal observaties in invoertabel;*/
/*   %telobs(&inlib..&invoertabel.);*/
/*   %IF &aantalobs.=0 %THEN %DO;*/
/*                              %put ---------------------------Macro tabel2excel---------------------------------- ;*/
/*                              %put Invoer dataset = &inlib..&invoertabel.  ;*/
/*                              %put Geen observaties gevonden, dus geen excelsheet!. ;*/
/*                              %put ------------------------------------------------------------------------------ ;*/
/*                              %*Verder niet verwerken;*/
/*                              %GOTO einde ;*/
/*                           %END;*/
/*   %excel_open;*/
/*   %excel_open_spreadsheet(%TRIM(&exceltemplate).xls);*/
/*   %excel_write_block ( &inlib. , &invoertabel., _all_ , 1, 1 , leeg , blad1 , label = Y );*/
/**/
/*   %obsnvars( &inlib..&invoertabel. );*/
/*   %excel_format(blad1 ,1,1,1,&nvar_gl. , bold=true);*/
/*   %*Zet autofilters aan op alle kolommen. ;*/
/*   %excel_autofilter( blad1) ;*/
/*   %*Blokkeer de kopregel;*/
/*   %excel_titels_blokkeren ( blad1, 1, 0, split=TRUE );*/
/*   %*maak de kopregel breedte gelijk aan de inhoud en kop;*/
/*   %excel_column_width ( blad1 , 1, &nvar_gl. , B );*/
/*   %*Zet cursor op startcel van werkblad ;*/
/*   %excel_active_cell( blad1, 1, 1 );*/
/*   %excel_save_and_close (%trim(&exceluitdir.)\%TRIM(&excelnaam).xls);*/
/*   %put ---------------------------Macro tabel2excel---------------------------------- ;*/
/*   %put Invoer dataset = &inlib..&invoertabel.  ;*/
/*   %put Excelsheet %trim(&exceluitdir.)\%TRIM(&excelnaam).xls ;*/
/*   %PUT OPTIES: invoer=, excelnaam=, exceluitdir=;*/
/*   %put ------------------------------------------------------------------------------ ;*/
/*   %Einde:*/
/**/
/*   options &m_notes35;*/
/*%mend tabel2excel ;*/

***********************************************************************************
* Macro om een standaard excel overzicht te maken van meedere sas tabellen 
* - met autofilter
* - namen van tabbladen wijzigen in namen van sas tabellen
*
* Indien geen parematers zijn meegegven, dan wordt de laatste aangemaakte tabel gebruikt
* en c:\temp als directory voor het resultaat
* 
* POSITIONAL PARAMETERS:
* Geen
*
* NAMED PARAMETERS:
* excelUitDir  = directory voor excel uitvoer  - default c:\temp
* excelNaam    = naam exelbestand (zonder .xls erachter) - default ff_sysdate
* invoer       = lijst van libname.tabel (libname optioneel, gescheiden door spateis) - default laatste dataset 
* tabBladNamen = lijst van namen van tabbladen, default zijn de namen (inclusief libnames) van de datasets, gescheiden door "sep"
* colour_key   = lijst met vars waarop gekleurd moet worden, gescheiden door de sep (zelfde sep als voor tabBladNamen)
* kleur        = om-en-om kleur, default=35
* autoFilter   = J/N, default is J (eigenlijk is alles wat niet n/N is gelijk aan J, want we testen op upcase=N
* sep          = character die de lijsten tabBaldNamen en colourKey opknipt, default is spatie
* exceltemplate=Q:\Ontwikkeling\SRB\TrafficManagement\leeg.xls - .xls met 20 tabbladen, verder niets.
*
* Voorbeelden
*   1 tabel naar 1 tabblad
* tabels2excel( exceluitdir=c:\temp, excelnaam=zz, invoer=work.ff)  
*   3 tabellen (ff, ff2, cyr.ff3) naar 3 tabblad (Effe, Eff2e, Effeee3)
* tabels2excel( exceluitdir=c:\temp, excelnaam=zz, invoer=work.ff ff2 cyr.ff3, tabbladnamen=Effe Effe2 Effeee3)
*   3 tabellen (ff, ff2, cyr.ff3) naar 3 tabblad. Omdat er spaties in de tabblad namen zit een andere separator (#) gebruiken.
* tabels2excel( exceluitdir=c:\temp, excelnaam=zz, sep=#
*             , invoer=work.ff ff2 cyr.ff3, tabbladnamen=Effe met spatie#Effe2 m s#Effeee3 meeet spa )
*   2 tabellen (ff, ff2) naar 2 tabblad. Kleur de tabbladen volgense de key "a b" voor ff en "x" voor ff2 waarbij a,b variabelen
*   zijn in ff en x een variabele in ff2, Kleur = 6 is hard geel.
* tabels2excel( exceluitdir=c:\temp, excelnaam=zz, sep=#
*             , invoer=work.ff ff2, tabbladnamen=Effe#Effe2
*             , colourKey=a b#x, kleur=6)
*
* include macros.sas
* incluse excel_macros.sas
* 
* data fff1 
*     fff2;
*  do i = 1 to 50;
*     a=round(i/5, 1.);
*     b=round(i/4, 1.);
*     output fff1;
*     a=round(i/8, 1.);
*     output fff2;
*  end;
* run;
*
*%tabels2excel( excelUitDir=c:\temp, excelNaam=ff_&sysdate
*             , invoer=fff1 fff2
*             , tabBladNamen=ff1#ff twee
*             , colour_key=a b#a
*             , kleur=6
*             , autoFilter=J
*             , sep=#
*             );
*
***********************************************************************************;
%put compiling macro tabels2excel;
%macro tabels2excel( excelUitDir=c:\temp, excelNaam=ff_&sysdate
                   , invoer=&syslast, tabBladNamen=
                   , colour_key=, kleur=35
                   , autoFilter=J, sep=%str( )
                   , exceltemplate=c:\temp\leeg.xls
                   );
   %let m_notes36 = %sysfunc(getoption ( notes ));
   options nonotes;

   %*Fix eventuele traling \ ;
   %if %substr(&exceluitdir,%length(&exceluitdir),1) = \ %then %let exceluitdir=%substr(&exceluitdir,1,%eval(%length(&exceluitdir)-1));
   %excel_open;
   %excel_open_spreadsheet(&exceltemplate);
   %local iblad tabBladNm;
   %let iblad = 1;
   %let mfirst=Y;  %* de eerste keer dat je tabblad andere naam geeft moet deze macrovar op Y staan;

   %do %while (%qscan( &invoer, &iblad, %str( ) ) ne );
         %let dsnam = %scan( &invoer, &iblad, %str( ) );
         %if %index(&dsnam, .) > 0 %then %do;
            %let inlib       = %qscan(&dsnam, 1, .);
            %let invoertabel = %qscan(&dsnam, 2, .);
         %end; 
         %else %do;
            %let inlib       = work;
            %let invoertabel = &dsnam;
         %end;

/*         %if &iblad > 20 %then %do;  %excel_insert_ws( leeg ); %end;*/


         %let tabBladNm = %sysfunc(strip(%qscan( &tabBladNamen, &iblad, %str(&sep))));
         %if &tabBladNm = %then %let tabBladNm=&dsnam;
         %put tabBladNm =***&tabBladNm***;

         %let colourK   = %sysfunc(strip(%qscan( &colour_key, &iblad, %str(&sep))));
         %if &colourK ne %then %let colourK = , colour_key=&colourK , kleur=&kleur;
         %put colourK =***&colourK***;

         %put Schrijven van inlib=&inlib invoertabel=&invoertabel;
         %obsnvars( &dsnam );
         %if &nobs_gl ne 0 %then %do;
   		    %excel_insert_ws( leeg );
            %excel_write_block( &inlib, &invoertabel, _all_ , 1, 1, leeg, Blad&iblad, label = Y &ColourK );
            %excel_format(Blad&iblad, 1, 1, 1, &nvar_gl , bold=true);
            %if %qupcase(&autoFilter) ne N %then %do; %excel_autofilter( Blad&iblad ); %end;
            %excel_titels_blokkeren( Blad&iblad, 1, 0, split=TRUE );
            %excel_column_width( Blad&iblad, 1, &nvar_gl, B );
         %end;
         %else %put Dataset &dsnam bestaat niet of is leeg;

         %excel_rename_ws( &exceltemplate, Blad&iblad, &tabBladNm, first=&mfirst );
         %let mfirst=N;
		/* Focus altijd maar op de eerste? */ 
		 %excel_active_cell( %sysfunc(strip(%qscan( &tabBladNamen, 1, %str(&sep)))) , 1, 1 );
         * %excel_active_cell( &tabBladNm, 2, 1 );

         %let iblad = %eval( &iblad + 1);
   %end; 

   %do iblad = &iblad %to 10 %by 1;
         %excel_delete_worksheet( Blad&iblad );
   %end;

   %* de focus op 1e tabblad zetten;
   %let tabBladNm = %sysfunc(strip(%qscan( &tabBladNamen, 1, %str(&sep))));
   %if &tabBladNm = %then %let tabBladNm=&dsnam;
   %excel_active_cell( &tabBladNm, 2, 1 );

   %excel_save_and_close (%trim(%left(&exceluitdir))\%trim(%left(&excelnaam)).xls);
   %put einde tabels2excel &excelUitDir\&excelnaam;

   options &m_notes36;
%mend tabels2excel ;

/*----------------------------------------------------------------------------+
| excel_empty_space                                                           |
| Als er alleen spaties (t/m 1 stuks) in een cel staan, dan verwijderen.      |
| Dat kan echt heel veel MB discspace opeten in grote, sparely populated      |
| spreadsheets.                                                               |
| POSITIONAL PARAMETERES:                                                     |
| ws_nam = naam van werkblad                                                  |
| first_row = 1e row waar cleanup begint, default=1                           |
| first_col = 1e kolom waar cleanup begint, default=1                         |
| last_row  = laatste row waar cleanup eindigd, default=10000                 |
| last_col  = laatste col waar cleanup eindigd, default=256                   |
| NAMED PARAMETER: none                                                       |
+----------------------------------------------------------------------------*/
%put compiling macro excel_empty_space;
%macro excel_empty_space ( ws_nam, first_row, first_col, last_row, last_col );
  %let m_notes37 = %sysfunc(getoption ( notes ));

  options nonotes;
  %if &first_row = %then %let first_row = 1;
  %if &first_col = %then %let first_col = 1;
  %if &last_row =  %then %let last_row  = 10000;
  %if &last_col =  %then %let last_col  = 256;

  options  noxwait;
  filename sas2xl dde 'excel|system';
  data _null_;
     file sas2xl;
     put '[error(false)]';
     put "[workbook.activate(""&ws_nam"")]";
     put "[select(""R&first_row.&kol_col.&first_col.:R&last_row.&kol_col.&last_col."")]";
     put '[formula.replace("          ","",1,,false,false)]';
     put '[formula.replace("         ","",1,,false,false)]';
     put '[formula.replace("        ","",1,,false,false)]';
     put '[formula.replace("       ","",1,,false,false)]';
     put '[formula.replace("      ","",1,,false,false)]';
     put '[formula.replace("     ","",1,,false,false)]';
     put '[formula.replace("    ","",1,,false,false)]';
     put '[formula.replace("   ","",1,,false,false)]';
     put '[formula.replace("  ","",1,,false,false)]';
     put '[formula.replace(" ","",1,,false,false)]';
  run;

  options &m_notes37;
%mend excel_empty_space;

%put end of compiling all excel_macros;
