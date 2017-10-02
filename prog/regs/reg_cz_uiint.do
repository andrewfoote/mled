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


gen statefip=string(fips)
	replace statefip="0"+statefip if length(statefip)<5
	replace statefip=substr(statefip,1,2)
bysort czone state: egen boof=total(cty_pop)
bysort czone: egen maxpop=max(boof)

gen stateis=state if boof==maxpop

keep czone stateis 
keep if stateis!=""
duplicates drop
duplicates report czone 
rename stateis statefips
destring statefips, replace

tempfile states
save `states'



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

merge m:1 czone using `states', gen(mmm);
	drop mmm;



**************;
*CTE AND NON-CTE AWARDS;
gen aw_tot_ACA_47=aw_tot_47-aw_tot_CTE_47;
gen ln_aw_tot_ACA_47=ln(aw_tot_ACA_47);

global mainoutcomes tef_tot ffe_tot aw_tot aw_tot_CTE aw_tot_ACA;

xtset czone year;


#delimit cr
gen uiaca=.
replace uiaca=0   if statefip==1
replace uiaca=1   if statefip==2
replace uiaca=0   if statefip==5
replace uiaca=0   if statefip==4
replace uiaca=1   if statefip==6
replace uiaca=1   if statefip==8
replace uiaca=1   if statefip==9
replace uiaca=1   if statefip==10
replace uiaca=1   if statefip==11
replace uiaca=1   if statefip==12
replace uiaca=1   if statefip==13
replace uiaca=1   if statefip==15
replace uiaca=1   if statefip==16
replace uiaca=0   if statefip==17
replace uiaca=1   if statefip==18
replace uiaca=1   if statefip==19
replace uiaca=1   if statefip==20
replace uiaca=1   if statefip==21
replace uiaca=0   if statefip==22
replace uiaca=1   if statefip==23
replace uiaca=0   if statefip==24
replace uiaca=1   if statefip==25
replace uiaca=0   if statefip==26
replace uiaca=1   if statefip==27
replace uiaca=0   if statefip==28
replace uiaca=1   if statefip==29
replace uiaca=0   if statefip==30
replace uiaca=0   if statefip==31
replace uiaca=1   if statefip==32
replace uiaca=0   if statefip==33
replace uiaca=0   if statefip==34
replace uiaca=1   if statefip==35
replace uiaca=0   if statefip==36
replace uiaca=1   if statefip==37
replace uiaca=1   if statefip==38
replace uiaca=1   if statefip==39
replace uiaca=1   if statefip==40
replace uiaca=1   if statefip==41
replace uiaca=0   if statefip==42
replace uiaca=0   if statefip==44
replace uiaca=0   if statefip==45
replace uiaca=0   if statefip==46
replace uiaca=1   if statefip==47
replace uiaca=1   if statefip==48
replace uiaca=1   if statefip==49
replace uiaca=0   if statefip==50
replace uiaca=0   if statefip==51
replace uiaca=0   if statefip==53
replace uiaca=0   if statefip==54
replace uiaca=1   if statefip==55
replace uiaca=0   if statefip==56
#delimit; 

gen layoff_uiaca_t1= L.log_czlayoff*uiaca;
gen layoff_uiaca_t2=L2.log_czlayoff*uiaca;
gen layoff_uiaca_t3=L3.log_czlayoff*uiaca; 

				
local rhs_postvars "layoff_uiaca_t1 layoff_uiaca_t2 layoff_uiaca_t3";
	label var layoff_uiaca_t1 "Layoffs, t-1 x Approved ";
	label var layoff_uiaca_t2 "Layoffs, t-2 x Approved ";
	label var layoff_uiaca_t3 "Layoffs, t-3 x Approved ";

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
		eststo spec`sec'`outcome': areg ln_`outcome'_`sec' l1_log_czlayoff l2_log_czlayoff l3_log_czlayoff `rhs_postvars' cztr*  yearfe*  [weight=`weightvar'],   absorb(czone) cluster(`clustervar');
					sum `outcome'_`sec' if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
				};
				
				esttab * using "${tabdir}/lev/reg_reguiaca_`sec'_`type'.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(  `rhs_postvars'  )
				stat(ysu N ar2, labels("Y-Mean" "Observations" "Adj. R-sq") );
				eststo clear;
				};

