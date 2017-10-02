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


global mainoutcomes tef_tot ffe_tot aw_tot aw_aa aw_1t4 aw_lt1y ;
qui tab czone, gen(czfe);






xtset czone year;


*********************************************;
*Pre and Post Recession (2007) variables;
**********************************************;

gen post_rece=year>=2007;

gen layoff_postrece_t1= L.log_czlayoff*post_rece;
gen layoff_postrece_t2=L2.log_czlayoff*post_rece;
gen layoff_postrece_t3=L3.log_czlayoff*post_rece; 

				
local rhs_postvars "layoff_postrece_t1 layoff_postrece_t2 layoff_postrece_t3";
	label var layoff_postrece_t1 "Layoffs, t-1xPost-2007";
	label var layoff_postrece_t2 "Layoffs, t-2xPost-2007";
	label var layoff_postrece_t3 "Layoffs, t-3xPost-2007";

	gen l1_log_czlayoff=l.log_czlayoff;
	gen l2_log_czlayoff=l2.log_czlayoff;
	gen l3_log_czlayoff=l3.log_czlayoff;
	label var l1_log_czlayoff "Layoffs, t-1";
	label var l2_log_czlayoff "Layoffs, t-2";
	label var l3_log_czlayoff "Layoffs, t-3";	
	local rhscovar log_`type'layoff;
local adjrhscovar log_adjctylayoff;

*****************************************;
*Table with Main Spec, All Aggregate Variables;
*********************************************;
eststo clear;
eststo clear;
foreach sec in  47 {;
foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		eststo spec`sec'`outcome': reg ln_`outcome'_`sec' l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff `rhs_postvars' cztr*  czfe* yearfe*  [weight=`weightvar'],   cluster(`clustervar');
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				};
				
				esttab * using "${tabdir}/lev/reg_regprepost_`sec'_`type'.tex", replace se(a2) b(a2) ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  `rhs_postvars'  )
				stat(ysu N r2, labels("Y-Mean" "Observations" "R-sq") );
				eststo clear;
				};


******************************************************************;
*Table with Main Spec, College-Program Variables;
***************************************************************;

eststo clear;
local rhscovar log_`type'layoff;
			foreach sec in  47 {;
			foreach outcome in ln_aw_tot ln_aw_aa ln_aw_lt1y ln_aw_1t4{ ;
			foreach field in TOT CTE CON HEA IT PUB FAM { ;
				eststo spec`sec'`outcome'`field': reg `outcome'_`field'_`sec' l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff `rhs_postvars' cztr* czfe*   yearfe*  [weight=`weightvar'], cluster(`clustervar');
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					};

				esttab  using "${tabdir}/lev/reg_prepost_f`outcome'_`type'.tex", replace se(a2) b(a2)  star(* .10 ** .05 *** .01) 
					noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
					stat(N , labels("Observations" ))
					keep(l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff  `rhs_postvars'  );
				esttab  using "${tabdir}/lev/reg_prepost_f`outcome'_`type'_justint.tex", replace se  star(* .10 ** .05 *** .01) 
					noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
					stat(N , labels("Observations" ))keep(`rhs_postvars'  );				
				eststo clear;
					};
					};

