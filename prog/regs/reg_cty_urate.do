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


cd /home/research/masslayoff/data 
	use FINAL_MASSLAYOFF_DATA, clear 
	keep fips year lau*
	gen urate=lau_emp/(lau_emp+lau_unemp)
	gen lnlauunemp=ln(lau_unemp)
	tempfile tempu
	save `tempu'

use $datdir/CTY_ED_LAYOFF, clear
do $prodir/preamble_cty.do
 
 drop _merge
merge m:1 fips using `czone'
	tab _merge
drop _merge
merge 1:1 fips year using `tempu'
	tab _merge
	
*Basic Regressions
#delimit;

local clustervar czone  ;
local type cty  ;
local weightvar total_pop ;


global mainoutcomes tef_tot ffe_tot tef_tot_men ffe_tot_men aw_tot aw_aa aw_1t4 aw_lt1y ;


qui tab fips, gen(fipsfe);







xtset fips year;

gen l1_urate=l.urate;
gen l2_urate=l2.urate;
gen l3_urate=l3.urate;
	label var l1_urate "Unemp. Rate, t-1";
	label var l2_urate "Unemp. Rate, t-2";
	label var l3_urate "Unemp. Rate, t-3";
gen l1_lnlauunemp= l.lnlauunemp;
gen l2_lnlauunemp=l2.lnlauunemp;
gen l3_lnlauunemp=l3.lnlauunemp;
	label var l1_lnlauunemp "log(Unemployed), t-1";
	label var l2_lnlauunemp "log(Unemployed), t-2";
	label var l3_lnlauunemp "log(Unemployed), t-3";


*****************************************;
*Table with Unemployment Rate on RHS;
*********************************************;
gen deletemelau=46000;
eststo clear;
local rhscovar urate;
foreach sec in 47 {;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
		eststo spec`sec'`outcome': areg ln_`outcome'_`sec' l1_`rhscovar'    yearfe*   ctytre*   [weight=`weightvar'], absorb(fips) cluster(czone);

		eststo tspec`sec'`outcome': areg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'  yearfe*   ctytre*   [weight=`weightvar'], absorb(fips) cluster(czone);

				};
				
				esttab s* using "${tabdir}/lev/reg_urate1_`sec'_`type'.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_`rhscovar'   )
				stat(N ar2, labels( "Observations" "Adj. R-sq") );
				
				esttab t* using "${tabdir}/lev/reg_urate3_`sec'_`type'.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar' )
				stat(N ar2, labels( "Observations" "Adj. R-sq") );
				eststo clear;
				
			} ;
			
			


*****************************************;
*Table with log(#Unemployed) on RHS;
*********************************************;
eststo clear;
local rhscovar lnlauunemp;
foreach sec in 47 {;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
		eststo spec`sec'`outcome': areg ln_`outcome'_`sec' l1_`rhscovar'    yearfe*   ctytre*  [weight=`weightvar'], absorb(fips) cluster(czone);

		eststo tspec`sec'`outcome': areg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'  yearfe*   ctytre*   [weight=`weightvar'], absorb(fips) cluster(czone);

				};
				
				esttab s* using "${tabdir}/lev/reg_logunemp1_`sec'_`type'.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_`rhscovar'  )
				stat(N ar2, labels( "Observations" "Adj. R-sq") );
				
				esttab t* using "${tabdir}/lev/reg_logunemp3_`sec'_`type'.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar' )
				stat(N ar2, labels( "Observations" "Adj. R-sq") );
				eststo clear;
				
			} ;
			
