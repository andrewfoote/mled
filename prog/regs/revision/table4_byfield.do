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

eststo clear;
local rhscovar log_`type'layoff;

/* demographics */

gen share_0_19 = (total_age_0_9_pop + total_age_10_19_pop)/total_pop ;

foreach age in 0_18 18_29 30_44 45_54 55p {;
gen share_`age' = total_age_`age'_pop / total_pop ;
local agegroups "`agegroups' share_`age'" ;

};

foreach race in white black { ; 
	gen share_`race' = total_`race'_pop/total_pop ; 
};

gen share_male = total_male_pop/total_pop; 

local demographics `agegroups' `raceshare' share_male ;


foreach outcome in aw_tot aw_aa aw_lt1y aw_1t4{ ;
	eststo clear;
	foreach field in TOT CTE CON HEA IT PUB FAM { ;
		local lhs ln_`outcome'_nosand1_`field'_47 ;
		local lhs_sum `outcome'_nosand1_`field'_47 ;
		
		eststo spec`sec'`outcome'`field': reg `lhs' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe*  czfe* cztre* `agegroups
		[weight=`weightvar'],    cluster(`clustervar');
	
		sum `lhs_sum' if e(sample);
		local zz=r(mean);
		estadd scalar ysu=`zz';
	};

	esttab  using "${tabdir}/revision/table4_`outcome'.tex", replace se(a2) b(a2)  r2  star(* .10 ** .05 *** .01) 
	stat(N r2, labels("Observations" "R-Sq"))
	noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
	keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  )
	stat(ysu N  r2, labels("Y-Mean" "Observations"  "R-Sq") );

};

	
	
	
	
	