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


use $datdir/CTY_ED_LAYOFF, clear
do $prodir/preamble_cty.do
 
 drop _merge
merge m:1 fips using `czone'
	tab _merge

*Basic Regressions
#delimit;

local clustervar czone  ;
local type cty  ;
local weightvar total_pop ;

local rhscovar log_`type'layoff;


global mainoutcomes tef_tot ffe_tot aw_tot tef_tot_men ffe_tot_men  aw_aa aw_1t4 aw_lt1y ;


qui tab fips, gen(fipsfe);






drop if year==1995;
xtset fips year;

gen l1_log_ctylayoff=l.log_ctylayoff;
gen l2_log_ctylayoff=l2.log_ctylayoff;
gen l3_log_ctylayoff=l3.log_ctylayoff;
	label var l1_log_ctylayoff "Layoffs, t-1";
	label var l2_log_ctylayoff "Layoffs, t-2";
	label var l3_log_ctylayoff "Layoffs, t-3";

***********************************************;
*Create variables for how many FPs and CCs in county;
***********************************************;
gen hasCC=tef_tot_47>0 & tef_tot_47!=.;
gen hasFP=tef_tot_69>0 & tef_tot_69!=.;
gen has_both=hasCC==1 & hasFP==1;
gen has_onlyCC=hasCC==1 & hasFP==0;

bysort fips: egen numhasCC=total(hasCC);
bysort fips: egen numhasFP=total(hasFP);
bysort fips: egen numhasboth=total(has_both);
bysort fips: egen numhasonlyCC=total(has_onlyCC);
bysort fips: gen numyears=_N;


	gen hasCC_allyears=numhasCC==numyears;
	gen hasFP_allyears=numhasFP==numyears;
	gen hasbo_allyears=numhasboth==numyears;
	gen hasonlyCC_allyears=numhasonlyCC==numyears;
	egen fipsflag=tag(fips);
	sum has* numhas* if fipsflag;

*****************************************;
*Table with Main Spec, All Aggregate Variables;
*********************************************;
eststo clear;
foreach sec in 47 69{;
foreach outcome in  tef_tot ffe_tot aw_tot   { ;
	local x = 1 ;
		
				*eststo spec`sec'`outcome'1: areg ln_`outcome'_`sec' L.`rhscovar'  L2.`rhscovar' L3.`rhscovar' yearfe*  ctytre*   [weight=`weightvar'], absorb(fips) cluster(czone);
				*	estadd ysumm;		                                                                                    
				eststo spec`sec'`outcome'2: areg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'   yearfe*  ctytre*   [weight=`weightvar'] if hasbo_allyears==1, absorb(fips) cluster(czone);
					estadd ysumm;		                                                                                    
				eststo spec`sec'`outcome'3: areg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'   yearfe*  ctytre*  [weight=`weightvar'] if hasonlyCC_allyears, absorb(fips) cluster(czone);
					estadd ysumm;                                                                                           
				eststo spec`sec'`outcome'4: areg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'   yearfe*  ctytre*   [weight=`weightvar'] if hasFP_allyears, absorb(fips) cluster(czone);
					estadd ysumm;
				};
				esttab * using "${tabdir}/lev/reg_mutFP_`sec'_`type'.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'   )
				stat(ymean N ar2, labels("Y-Mean" "Observations" "Adj. R-sq") );
				eststo clear;
				
			} ;

