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

ddd;

*****************************************;
*Incremental table with lags, just for enrollment;
*********************************************;
foreach outcome in ffe_tot  { ;
foreach sec in  47 69{;
	
	
				eststo spec1`sec': reg ln_`outcome'_`sec' l1_log_czlayoff  czfe* cztre* yearfe*  [weight=`weightvar'],    cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				eststo spec2`sec': reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff  czfe*  cztre* yearfe*  [weight=`weightvar'],    cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				eststo spec3`sec': reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff  czfe*  cztre* yearfe*  [weight=`weightvar'],    cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					tabstat `outcome'_`sec' if e(sample), by(year) ;
				eststo spec4`sec': reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff l4_log_czlayoff  czfe*   cztre* yearfe*  [weight=`weightvar'],    cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				eststo spec5`sec': reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff l4_log_czlayoff  czfe* l5_log_czlayoff  cztre* yearfe*  [weight=`weightvar'],    cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				eststo spec6`sec': reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff  czfe* yearfe*     [weight=`weightvar'],  cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					
									
				esttab using "${tabdir}/lev/reg_incregmain_`type'_`outcome'_`sec'.tex", replace se(a2) b(a2)  r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff l4_log_czlayoff l5_log_czlayoff  )
				stat(ysu N  r2, labels("Y-Mean" "Observations"  "R-sq") );
				} ;	
				eststo clear;
				
			} ;

*****************************************;
*Table with Main Spec, All Aggregate Variables;
*********************************************;
eststo clear;
foreach sec in  47 69{;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
				eststo spec`sec'`outcome': reg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe*  czfe*   cztre*   [weight=`weightvar'],  cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				};
				esttab * using "${tabdir}/lev/reg_mainregagg_`sec'_`type'.tex", replace se(a2) b(a2)  r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  )
				stat(ysu N  r2, labels("Y-Mean" "Observations"  "R-Sq") );
				eststo clear;
					
			} ;
*/
******************************************************************;
*Table with Main Spec, College-Program Variables
***************************************************************;

eststo clear;
local rhscovar log_`type'layoff;
			foreach sec in 4769 47 69{;
			foreach outcome in ln_aw_tot ln_aw_aa ln_aw_lt1y ln_aw_1t4{ ;
				eststo clear;
				foreach field in TOT CTE CON HEA IT PUB FAM { ;
				eststo spec`sec'`outcome'`field': reg `outcome'_`field'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe*  czfe* cztre* [weight=`weightvar'],    cluster(`clustervar');
				
				sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					};

				esttab  using "${tabdir}/lev/reg_mainregawa_`outcome'_`sec'_`type'.tex", replace se(a2) b(a2)  r2  star(* .10 ** .05 *** .01) 
				stat(N r2, labels("Observations" "R-Sq"))
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  )
				stat(ysu N  r2, labels("Y-Mean" "Observations"  "R-Sq") );
				eststo clear;
		};
		};
