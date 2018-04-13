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
tempfile graphfile ;
	postfile programgraph str3 program_name str10 level response stderr using `graphfile', replace;
	
	
	
eststo clear;
local rhscovar log_`type'layoff;
foreach sec in 47 {;
	foreach outcome in ln_aw_tot ln_aw_aa ln_aw_lt1y ln_aw_1t4{ ;
		foreach field in TOT CTE CON HEA IT PUB FAM { ;
		eststo spec`sec'`outcome'`field': reg `outcome'_`field'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe*  czfe* cztre* [weight=`weightvar'],    cluster(`clustervar');
		lincom l1_log_czlayoff+l2_log_czlayoff+ l3_log_czlayoff ;
			local estimate = r(estimate) ;
			local se 	= r(se) ;
			post programgraph ("`field'") ("`outcome'") (`estimate') (`se');
		};
	};
};
postclose programgraph; 

use `graphfile', clear ;

list ; 
*keep if level == "ln_aw_tot" ;

save "$datdir/EFFECTS_BY_FIELD.dta", replace;






