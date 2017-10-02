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
	
	gen region=.
replace region=1 if statefip=="09"
replace region=1 if statefip=="34"
replace region=1 if statefip=="23"
replace region=1 if statefip=="36"
replace region=1 if statefip=="25"
replace region=1 if statefip=="42"
replace region=1 if statefip=="33"
replace region=1 if statefip=="44"
replace region=1 if statefip=="50"

replace region=2 if statefip=="17"
replace region=2 if statefip=="19"
replace region=2 if statefip=="18"
replace region=2 if statefip=="20"
replace region=2 if statefip=="26"
replace region=2 if statefip=="27"
replace region=2 if statefip=="39"
replace region=2 if statefip=="29"
replace region=2 if statefip=="55"
replace region=2 if statefip=="31"
replace region=2 if statefip=="38"
replace region=2 if statefip=="46"

replace region=3 if statefip=="10"
replace region=3 if statefip=="01"
replace region=3 if statefip=="11"
replace region=3 if statefip=="21"
replace region=3 if statefip=="12"
replace region=3 if statefip=="28"
replace region=3 if statefip=="13"
replace region=3 if statefip=="47"
replace region=3 if statefip=="24"
replace region=3 if statefip=="37"
replace region=3 if statefip=="45"
replace region=3 if statefip=="51"
replace region=3 if statefip=="54"
replace region=3 if statefip=="05"
replace region=3 if statefip=="22"
replace region=3 if statefip=="40"
replace region=3 if statefip=="48"
 
replace region=4 if statefip=="04"
replace region=4 if statefip=="02"
replace region=4 if statefip=="08"
replace region=4 if statefip=="06"
replace region=4 if statefip=="16"
replace region=4 if statefip=="15"
replace region=4 if statefip=="30"
replace region=4 if statefip=="41"
replace region=4 if statefip=="32"
replace region=4 if statefip=="53"
replace region=4 if statefip=="35"
replace region=4 if statefip=="49"
replace region=4 if statefip=="56"

bysort czone state: egen boof=total(cty_pop)
bysort czone: egen maxpop=max(boof)

gen stateis=state if boof==maxpop

keep czone stateis region
keep if stateis!=""
duplicates drop
duplicates report czone region
rename stateis statefip
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


global mainoutcomes tef_tot ffe_tot  aw_tot aw_aa aw_1t4 aw_lt1y ;
qui tab czone, gen(czfe);

merge m:1 czone using `states', gen(mmm);
	drop mmm;




xtset czone year;



global mainoutcomes tef_tot aw_tot_PUB aw_aa_PUB aw_lt1y_PUB aw_1t4_PUB;
*****************************************;
*Table with Main Spec, All Aggregate Variables;
*********************************************;
eststo clear;
foreach sec in  1 2 3 4 {;

foreach outcome in $mainoutcomes  { ;
	local x = 1 ;
		
				eststo spec47`outcome': areg ln_`outcome'_47 L.`rhscovar'  L2.`rhscovar' L3.`rhscovar' yearfe*   cztre*   if region==`sec' [weight=`weightvar'], absorb(czone) cluster(czone);
					sum `outcome'_47 if e(sample);
					local zz=r(mean);
					estadd scalar ysu=`zz';
					mat b=e(b);
						mat b=b[1..1,1..3];
					mat v=vecdiag(e(V));
						mat v=v[1..1,1..3];
						mat g`outcome'`sec'=b',v';
				};
				esttab * using "${tabdir}/lev/reg_mainregagg_r`sec'_`type'_.tex", replace se ar2 star(* .10 ** .05 *** .01) 
				noconstant nomtitles noobs nogaps noline nonumbers compress label  prehead(" ") posthead(" ") prefoot(" ") postfoot(" ") 
				keep(L.`rhscovar' L2.`rhscovar' L3.`rhscovar'  )
				stat(ysu N ar2, labels("Y-Mean" "Observations" "Adj. R-sq") );
				eststo clear;
				
			} ;

*Plot them;
#delimit cr
foreach outcome in $mainoutcomes  { 
	mat a=g`outcome'1, g`outcome'2,g`outcome'3,g`outcome'4
	clear
	svmat a
	
	foreach g in 1 2 3 4{
		local i=`g'+1
		rename a`g' b`g'
		gen u`g'=b`g'+2*(a`i'^0.5)
		gen l`g'=b`g'-2*(a`i'^0.5)
		}
	gen n=_n
	
	scatter *1 *2 *3 *4 n, connect(l l l l l l l l l l l l) msymbol(O  none none X none none  T  none none Oh  none none) mcolor(red red red blue blue blue green green green black black black)
		graph export "${tabdir}/lev/reg_`outcome'_region.eps", replace
	
	}
	
	
	
			
			
			