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


global mainoutcomes tef_tot ffe_tot   aw_tot aw_aa aw_1t4 aw_lt1y ;


qui tab fips, gen(fipsfe);







xtset fips year;

gen l1_log_ctylayoff=l.log_ctylayoff;
gen l2_log_ctylayoff=l2.log_ctylayoff;
gen l3_log_ctylayoff=l3.log_ctylayoff;
	label var l1_log_ctylayoff "Layoffs, t-1";
	label var l2_log_ctylayoff "Layoffs, t-2";
	label var l3_log_ctylayoff "Layoffs, t-3";

*****************************************;
*Incremental table with lags, just for enrollment;
*********************************************;
/*
foreach sec in 47 69{;
foreach outcome in tef_tot  { ;
	eststo clear ;
	local x = 1 ;
	
	
				eststo spec1: areg ln_`outcome'_`sec' l1_`rhscovar'   yearfe*  [weight=`weightvar'],   absorb(fips) cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				eststo spec2: areg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' yearfe*  [weight=`weightvar'],   absorb(fips) cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				eststo spec3: areg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar' yearfe*  [weight=`weightvar'],   absorb(fips) cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				eststo spec5: areg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar' yearfe*   ctytre*   [weight=`weightvar'], absorb(fips) cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				esttab using "${tabdir}/lev/reg_incregmain_`sec'_`type'_`outcome'.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_`rhscovar' l2_`rhscovar' l3_`rhscovar'  )
				stat(ysu N ar2, labels("Y-Mean" "Observations" "Adj. R-sq") );
				} ;		
				
			} ;

*/
*****************************************;
*Table with Main Spec, All Aggregate Variables;
*********************************************;
gen deletemelau=46000;
eststo clear;
foreach sec in 47 69{;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
				eststo spec`sec'`outcome': reg ln_`outcome'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'  yearfe*  fipsfe* ctytre*   [weight=`weightvar'],  cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
						local b1=_b[l1_`rhscovar']/100;
						local b2=_b[l2_`rhscovar']/100;
						local b3=_b[l3_`rhscovar']/100;						
						local gg=`zz'*(`b1'+(`b2')*(1+`b1')+`b3'*(1+`b2')*(1+`b1'));
						estadd scalar eff=`gg';
					qui sum deletemelau if e(sample);
					estadd scalar lay1=r(mean)*.01;	
				};
				
				esttab * using "${tabdir}/lev/reg_mainregagg_`sec'_`type'.tex", replace se(a2) b(a2) ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar' )
				stat(ysu  N ar2, labels("Y-Mean"  "Observations" "Adj. R-sq") );
				eststo clear;
				
			} ;

******************************************************************;
*Table with Main Spec, College-Program Variables
***************************************************************;

eststo clear;
local rhscovar log_`type'layoff;
			foreach field in TOT CTE IT CON PUB HEA BUS FAM EDU PER { ;
			foreach sec in 47 69{;
			foreach outcome in ln_aw_tot ln_aw_aa ln_aw_lt1y ln_aw_1t4{ ;

				eststo spec`sec'`outcome': reg `outcome'_`field'_`sec' l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'  yearfe* fipsfe* ctytre* [weight=`weightvar'],    cluster(`clustervar');
					};
					};
				esttab spec47* spec69* using "${tabdir}/lev/reg_mainregawa_`field'_`type'.tex", replace se(a2) b(a2)  star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_`rhscovar'  l2_`rhscovar' l3_`rhscovar'   );
				eststo clear;
		};

