/**********************
This do-file does logs on logs (in levels) regressions.

LAST EDITED: ADF 1/18/2016
***********************/

global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global prodir "$rootdir/prog"
global figdir "$rootdir/fig/revision"
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


global mainoutcomes tef_tot ffe_tot tef_tot_men ffe_tot_men aw_tot aw_aa aw_1t4 aw_lt1y ;
qui tab czone, gen(czfe);






xtset czone year;


gen l1_log_czlayoff=l.log_czlayoff;
gen l2_log_czlayoff=l2.log_czlayoff;
gen l3_log_czlayoff=l3.log_czlayoff;
gen d_log_czlayoff=d.log_czlayoff;

foreach g in 0 1 2 3 4 5 6 7 8 9 10{;
	foreach outcome in $mainoutcomes{;
		foreach sec in 47 69{;
			gen df`g'_`outcome'_`sec'=f`g'.ln_`outcome'_`sec'-l.ln_`outcome'_`sec';
			};
			};
			};
			
			
			
			

*****************************************;
*Run one regression for each lag
*********************************************;

	foreach outcome in $mainoutcomes{;
		foreach sec in 47 69{;
			mat `outcome'`sec'=.,.,.;
				foreach g in 0 1 2 3 4 5 6 7 {;
					areg df`g'_`outcome'_`sec' d_`rhscovar' yearfe* [weight=`weightvar'], absorb(czone) cluster(czone);
						local b=_b[d_`rhscovar'];
						local s=_se[d_`rhscovar'];
						local gg=`g'-1;
						mat aaa=`gg',`b',`s';
						mat `outcome'`sec'=`outcome'`sec'\aaa;
						};
						};
						};
	
	*Plot these things;
	foreach outcome in $mainoutcomes{;
		foreach sec in 47 69{;
			clear;
			svmat `outcome'`sec';
				drop if `outcome'`sec'1==.;
				rename `outcome'`sec'1 y;
				rename `outcome'`sec'2 b;
				gen up=b+1.96*`outcome'`sec'3;
				gen lo=b-1.96*`outcome'`sec'3;
				keep y b up lo;
			scatter b up lo y, connect(l l l) ytitle("Cumulated Response") xtitle("Years Since Shock") 
					lpattern(solid dash dash) msymbol(o none none) lcolor(black black black) mcolor(black) legend(off) yline(0, lcolor(gs6)) graphregion(color(white)) bgcolor(white)
					yscale(r(-.04(.02).04)) ylabel(-.04(.02).04, nogrid) xscale(r(-1(1)6)) xlabel(-1(1)6);
				graph export "$figdir/cumresp_cz_`outcome'`sec'.png", replace;
				};
				};
				};
				
				
				
				
	
	
	