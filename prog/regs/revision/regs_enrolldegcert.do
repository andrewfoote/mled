/***********************************
This do-file does the following things:

4 regressions: 

1. No controls
2. Fixed Effects
3. Demographics
4. Trends

***********************************/


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

/**************** CREATING DEMOG CHARACTERISTICS *******/
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
	
eststo clear;
foreach sec in  47 69 {;
	eststo clear ;
	local x = 1 ;
foreach outcome in $mainoutcomes  { ;
	sum ln_`outcome'_`sec' ;

		
	eststo a`x': areg ln_`outcome'_`sec' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe* 
		cztre* [weight=total_pop], absorb(czone) cluster(czone);
		sum `outcome'_`sec' if e(sample);
		local zz=r(mean);
		estadd scalar ysu=`zz';
		local x = `x' + 1 ; 
		
		lincom (l1_log_czlayoff +  l2_log_czlayoff +l3_log_czlayoff);
			local total_`outcome' = r(estimate);
			estadd	local total_beta = round(r(estimate),0.0001): a`x'  ;
			estadd	local total_se = round(r(se),0.0001): a`x'  ;
			estadd  local total_pval = string(tprob(r(df),(`total_beta'/`total_se')),"%5.4f"): a`x' ;
		

	};
	esttab using "${tabdir}/lev/enroll_deg_cert_`sec'.tex", replace se r2 star(* .10 ** .05 *** .01) 
		noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
		keep(l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff  )
		stat(total_beta total_se total_pval ysu N r2, labels("Total Effect" "(se)" "P-val" "Y-Mean" "Observations" "R-sq") );

		
}; 	
		
		