global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global prodir "$rootdir/prog"
global figdir "$rootdir/fig"
global tabdir "$rootdir/tab"
global logdir "$rootdir/log" 
set maxvar 32000
set matsize 11000
#delimit ; 



global mainoutcomes  aw_lt1y ;

insheet using "$rawdir/clusters_bootstrap_jtw1990.csv" ; 
 des ;
 sort fips ; 
 tempfile bootcz ; 
 save `bootcz', replace; 

use "/home/research/masslayoff/rawdata/cw_cty_czone", clear ;

rename cty_fips fips  ;
sort fips  ; 
tempfile czone ;
save `czone', replace;


use $datdir/CTY_ED_LAYOFF, clear;


 des;
 
 /***************************************
 This is going to be done in three steps
 1. Do main regressions, store results
 2. Do regression with replicated CZs, store results
 (both of these stored as iterations -1 and 0)
 3. loop over other clusters in bootcz, store results
 ******************************************/
foreach mainoutcome in  $mainoutcomes {;
	tempfile postregs_`mainoutcome' ;
	postfile regs_`mainoutcome' iteration beta_lag1 se_lag1 						tstat_lag1
                                  beta_lag2 se_lag2 	tstat_lag2
								  beta_lag3 se_lag3	tstat_lag3
			using `postregs_`mainoutcome'', replace ;
 } ; 
 drop _merge;
 /* STEP 1: Do main regressions with real CZs */
 sort fips ;
 merge m:1 fips using `czone' ;
 tab _merge ;
 drop if _merge == 2 ; 
 drop _merge ;
 
 do county_merge_FKV.do ; 
 
 do preamble_cz_FKV.do ;
 
 
*Basic Regressions
#delimit;

local clustervar czone  ;
local weightvar total_pop ;

local rhscovar log_czlayoff;


qui tab czone, gen(czfe);
qui tab year, gen(yearfe);
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

*****************************************;
*Table with Main Spec, All Aggregate Variables;
*********************************************;
foreach sec in  47 {;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
			qui	reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe*  czfe*   cztre*   [weight=total_pop] , cluster(czone);

				
				foreach lag in 1 2 3 { ;
					local beta`lag' = _b[l`lag'_log_czlayoff];
					local se`lag' = _se[l`lag'_log_czlayoff] ;
					local tstat`lag' = `beta`lag''/`se`lag'' ;
				}; 

	post regs_`outcome' (-1) (`beta1') (`se1') (`tstat1')
                                (`beta2') (`se2') (`tstat2')
                                (`beta3') (`se3') (`tstat3') ;
					
	} ;
} ; 


/************************
/*STEP 2: ESTIMATE USING REPLICATES CZONES */
***********************/
use $datdir/CTY_ED_LAYOFF, clear;
drop _merge;
 sort fips ;
 merge m:1 fips using `bootcz', keepusing(clustername) ;
 tab _merge ;
 drop if _merge == 2 ; 
 drop _merge ;
 
 egen czone = group(clustername) ;
 
 do $prodir/regs/county_merge_FKV.do ; 
 
 do $prodir/regs/preamble_cz_FKV.do ;
 *Basic Regressions
#delimit;

local clustervar czone  ;
local weightvar total_pop ;

local rhscovar log_czlayoff;


qui tab czone, gen(czfe);
qui tab year, gen(yearfe);
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
 foreach sec in  47 {;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
			qui	reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe*  czfe*   cztre*   [weight=total_pop] , cluster(czone);

				
				foreach lag in 1 2 3 { ;
					local beta`lag' = _b[l`lag'_log_czlayoff];
					local se`lag' = _se[l`lag'_log_czlayoff] ;
					local tstat`lag' = `beta`lag''/`se`lag'' ;
				}; 

	post regs_`outcome' (0) (`beta1') (`se1') (`tstat1')
                                (`beta2') (`se2') (`tstat2')
                                (`beta3') (`se3') (`tstat3') ;
					
	} ;
} ; 


/***********************************
STEP 3: LOOP OF 1000 other commuting zones
***********************************/
forvalues iteration = 1/1000 { ;/* beginning of loop */
di "ITERATION IS `iteration'";
use $datdir/CTY_ED_LAYOFF, clear;
	drop _merge;
	 sort fips ;
	 merge m:1 fips using `bootcz', keepusing(clustername_`iteration') ;
	 tab _merge ;
	 drop if _merge == 2 ; 
	 drop _merge ;
	 
	 egen czone = group(clustername_`iteration') ;
	 
	 do county_merge_FKV.do ; 
	 
	do preamble_cz_FKV.do ;
	 
qui tab czone, gen(czfe);
qui tab year, gen(yearfe);
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
	 
	 foreach sec in  47 {;
	foreach outcome in $mainoutcomes  { ;
		local x = 1 ;
			
					qui reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe*  czfe*   cztre*   [weight=total_pop] , cluster(czone);

					
					foreach lag in 1 2 3 { ;
						local beta`lag' = _b[l`lag'_log_czlayoff];
						local se`lag' = _se[l`lag'_log_czlayoff] ;
						local tstat`lag' = `beta`lag''/`se`lag'' ;
					}; 

		post regs_`outcome' (`iteration') (`beta1') (`se1') (`tstat1')
									(`beta2') (`se2') (`tstat2')
									(`beta3') (`se3') (`tstat3') ;
						
		} ;
	} ; 


} ; /* END OF ITERATION LOOP */


foreach outcome in $mainoutcomes  { ;
	postclose regs_`outcome' ;
} ;
 
 /* putting them all together */
foreach outcome in $mainoutcomes {;
	use `postregs_`outcome'', clear ; 
	gen outcome = "`outcome'" ;
	tempfile postregs_`outcome';
	save `postregs_`outcome'', replace ;
	di " SAVED POST REG FOR OUTCOME `outcome'" ;
};

clear;
foreach outcome in $mainoutcomes { ;
	append using `postregs_`outcome'' ;
};

save $datdir/outcomes_FKVtest_14.dta, replace ; 

