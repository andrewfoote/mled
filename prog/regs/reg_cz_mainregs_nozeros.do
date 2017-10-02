/**********************
This do-file does logs on logs (in levels) regressions.

LAST EDITED: ADF 1/18/2016
***********************/

global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global prodir "$rootdir/prog"
global figdir "$rootdir/fig"
global tabdir "$rootdir/tab"
global logdir "$rootdir/log" 
set maxvar 32000
set matsize 11000



use "/home/research/masslayoff/rawdata/cw_cty_czone", clear

rename cty_fips fips 
sort fips 
tempfile czone
save `czone', replace


use $datdir/CZ_ED_LAYOFF, clear
do $prodir/preamble_cz.do
 
*Basic Regressions
#delimit;

local clustervar czone  ;
local type cz  ;
local weightvar total_pop ;

local rhscovar log_`type'layoff;


global mainoutcomes tef_tot ffe_tot  aw_tot aw_aa aw_1t4 aw_lt1y ;
qui tab czone, gen(czfe);
xtset czone year;

	gen l1_log_czlayoff=l.log_czlayoff;
	gen l2_log_czlayoff=l2.log_czlayoff;
	gen l3_log_czlayoff=l3.log_czlayoff;
	gen l4_log_czlayoff=l4.log_czlayoff;
	gen l5_log_czlayoff=l5.log_czlayoff;
	label var l1_log_czlayoff "Layoffs, t-1";
	label var l2_log_czlayoff "Layoffs, t-2";
	label var l3_log_czlayoff "Layoffs, t-3";	
	label var l4_log_czlayoff "Layoffs, t-4";	
	label var l5_log_czlayoff "Layoffs, t-5";	


*FLAG IF NO ENROLLMENT;
gen noenr=tef_tot==. | tef_tot==0;
		gen minyzero=year if noenr==1 & year>1995;
		bysort czone: egen miny=min(minyzero);
		bysort czone: egen numnoenr=total(noenr);
*MISSING LOG LAYOFFS;
	foreach g in  1 2 3 4 5{;
		gen l`g'_log_czlayoffnz=l`g'_log_czlayoff if l`g'_log_czlayoff!=0;
		};
;

*****************************************;
/*Incremental table with lags, just for enrollment;
*********************************************;
	foreach out in  tef_tot ffe_tot{;
	*FIRST WITH TRENDS;
		*All years, 0-logs included;
				eststo spec11: areg ln_`out'_47 l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff  cztre* yearfe*  [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
		*CZ's with nonzero enrollment in all years, 0-logs included;
				eststo spec12: areg ln_`out'_47 l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff  cztre* yearfe*  if numno<17 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
		*CZ's with nonzero enrollment in any year, 0-logs included;
				eststo spec13: areg ln_`out'_47 l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff  cztre* yearfe*  if numno==1 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
		*All years, 0-logs dropped;
				eststo spec14: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz  cztre* yearfe*  [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;					
		*CZ's with nonzero enrollment in all years, 0-logs dropped;
				eststo spec15: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz  cztre* yearfe*  if numno<17 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
		*CZ's with nonzero enrollment in any year, 0-logs dropped;
				eststo spec16: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz  cztre* yearfe*  if numno==1 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;									
									
	*NOW WITHOUT TRENDS;
		*All years, 0-logs included;
				eststo spec21: areg ln_`out'_47 l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff   yearfe*  [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
		*CZ's with nonzero enrollment in all years, 0-logs included;
				eststo spec22: areg ln_`out'_47 l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff   yearfe*  if numno<17 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
		*CZ's with nonzero enrollment in any year, 0-logs included;
				eststo spec23: areg ln_`out'_47 l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff   yearfe*  if numno==1 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
		*All years, 0-logs dropped;
				eststo spec24: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz   yearfe*  [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;					
		*CZ's with nonzero enrollment in all years, 0-logs dropped;
				eststo spec25: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz   yearfe*  if numno<17 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
		*CZ's with nonzero enrollment in any year, 0-logs dropped;
				eststo spec26: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz   yearfe*  if numno==1 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;									
									
																
									
									
				esttab spec1* using "${tabdir}/lev/reg_diagm_`type'_`out'_47tr.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  ) rename(l1_log_czlayoffnz l1_log_czlayoff l2_log_czlayoffnz l2_log_czlayoff l3_log_czlayoffnz l3_log_czlayoff )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-sq") );
				esttab spec2* using "${tabdir}/lev/reg_diagm_`type'_`out'_47notr.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  ) rename(l1_log_czlayoffnz l1_log_czlayoff l2_log_czlayoffnz l2_log_czlayoff l3_log_czlayoffnz l3_log_czlayoff )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-sq") );
				
				} ;	
				eststo clear;
	*/
	
*****************************************	;
	*With and Without Trends;
***************************************;
	foreach out in tef_tot ffe_tot  aw_tot aw_aa aw_1t4 aw_lt1y {;
					eststo `out'_tr: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz  cztre* yearfe*  if numno<17 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
					
					eststo `out'_nr: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz   yearfe*  if numno<17 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
					
				*Exclude 0s;
					eststo `out'_tr0: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz  cztre* yearfe*  if ln_`out'_47!=0 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;
					
					eststo `out'_nr0: areg ln_`out'_47 l1_log_czlayoffnz  l2_log_czlayoffnz l3_log_czlayoffnz   yearfe*    if ln_`out'_47!=0 [weight=`weightvar'],   absorb(czone) cluster(czone);
					sum `out'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `out'_47 if e(sample), by(year) ;					
					};
				
				esttab *_tr using "${tabdir}/lev/reg_diagm_`type'_alltr.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  ) rename(l1_log_czlayoffnz l1_log_czlayoff l2_log_czlayoffnz l2_log_czlayoff l3_log_czlayoffnz l3_log_czlayoff )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-sq") );
				
				esttab *_nr using "${tabdir}/lev/reg_diagm_`type'_allnotr.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  ) rename(l1_log_czlayoffnz l1_log_czlayoff l2_log_czlayoffnz l2_log_czlayoff l3_log_czlayoffnz l3_log_czlayoff )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-sq") );

				esttab *_tr0 using "${tabdir}/lev/reg_diagm_`type'_alltr0.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  ) rename(l1_log_czlayoffnz l1_log_czlayoff l2_log_czlayoffnz l2_log_czlayoff l3_log_czlayoffnz l3_log_czlayoff )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-sq") );
				
				esttab *_nr0 using "${tabdir}/lev/reg_diagm_`type'_allnotr0.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  ) rename(l1_log_czlayoffnz l1_log_czlayoff l2_log_czlayoffnz l2_log_czlayoff l3_log_czlayoffnz l3_log_czlayoff )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-sq") );

