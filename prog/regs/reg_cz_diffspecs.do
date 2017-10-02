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

use "/home/research/masslayoff/data/FINALMASSLAYOFFS_CZONE", clear
keep czone year lau*
duplicates drop
tempfile lau
save `lau'

use "/home/research/masslayoff/rawdata/cw_cty_czone", clear

rename cty_fips fips 
sort fips 
tempfile czone
save `czone', replace


use $datdir/CZ_ED_LAYOFF, clear
do $prodir/preamble_cz.do
 
  merge 1:1 year czone using `lau', gen(mergelau)
 drop mergelau
 
*Basic Regressions
#delimit;

des, full	 ; 

/********* CREATING DEMOGRAPHIC CHARACTERISTICS *********/
gen share_0_19 = (total_age_0_9_pop + total_age_10_19_pop)/total_pop ;

foreach age in 0_18 18_29 30_44 45_54 55p {;
gen share_`age' = total_age_`age'_pop / total_pop ;
local agegroups "`agegroups' share_`age'" ;

};

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

	gen l1_czlayoff=l.total_ext;
	gen l2_czlayoff=l2.total_ext;
	gen l3_czlayoff=l3.total_ext;
	label var l1_czlayoff "Layoffs, t-1";
	label var l2_czlayoff "Layoffs, t-2";
	label var l3_czlayoff "Layoffs, t-3";	
	

*****************************************;
*Table with Main Spec, Levels on levels;
*********************************************;
foreach sec in  47 69{;
eststo clear;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
				eststo spec`sec'`outcome': areg `outcome'_`sec' l1_czlayoff  l2_czlayoff l3_czlayoff yearfe*   cztre* `agegroups'    [weight=`weightvar'], absorb(czone) cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				};
				esttab * using "${tabdir}/lev/reg_levlev_`sec'_`type'_wdemog.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_czlayoff  l2_czlayoff l3_czlayoff )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-Sq") );
				eststo clear;
					
			} ;
			
			

*****************************************;
*Table with Main Spec, Levels on shares;
*********************************************;
			
	gen total_ext_share = total_ext/L.lau_LF ;
	
	gen l1_czlayoff_share=l.total_ext_share;
	gen l2_czlayoff_share=l2.total_ext_share;
	gen l3_czlayoff_share=l3.total_ext_share;

	
foreach sec in  47 69{;
eststo clear;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
				eststo spec`sec'`outcome': areg `outcome'_`sec' l1_czlayoff_share  l2_czlayoff_share l3_czlayoff_share yearfe*   cztre* `agegroups'    [weight=`weightvar'], absorb(czone) cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				};
				esttab * using "${tabdir}/lev/reg_levsh_`sec'_`type'_wdemog.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep( l1_czlayoff_share  l2_czlayoff_share l3_czlayoff_share )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-Sq") );
				eststo clear;
					
			} ;


	
foreach sec in  47 69{;
eststo clear;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
				eststo spec`sec'`outcome': areg `outcome'_`sec'_share l1_czlayoff_share  l2_czlayoff_share l3_czlayoff_share yearfe*   cztre* `agegroups'    [weight=`weightvar'], absorb(czone) cluster(czone);
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				};
				esttab * using "${tabdir}/lev/reg_shsh_`sec'_`type'_wdemog.tex", replace se ar2 r2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep( l1_czlayoff_share  l2_czlayoff_share l3_czlayoff_share )
				stat(ysu N ar2 r2, labels("Y-Mean" "Observations" "Adj. R-sq" "R-Sq") );
				eststo clear;
					
			} ;	
			
*/
******************************************************************;
*Table with Main Spec, College-Program Variables
***************************************************************;

