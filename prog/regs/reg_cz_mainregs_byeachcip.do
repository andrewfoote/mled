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



**********************************************************************
*This dofile just repeats the main parts of build_ipeds_ctycz but only for completions by CIP code
******************************************************************************************

/*use $datdir/TOPTABLE_LOOKUP, clear
	keep cip_code
	duplicates drop
	gen one=1
	tempfile tempcips
	save `tempcips'
use $datdir/ipeds_awards_precollapse, clear
	gen cip_code=cipcode
	merge m:1 cip_code using `tempcips'
	*only CIP codes that match TOP codes
	keep if _merge==3 
	levelsof cipcode, local(cip)
	foreach v of local cip{
		foreach g in aw_tot aw_lt1y aw_aa aw_1t4{
			gen z`g'`v'=`g'*(cipcode==`v')
			}
			}
	collapse(sum) zaw_*, by(unitid year)
	tempfile tempcipsz
	save `tempcipsz'
	
	
	
	save $datdir/awsunitid_bycip, replace*/
	clear




/*********************************************************************
*Read in Geocoded data from Dave Carlson @ Census
*********************************************************************
insheet using $rawdir/foote_schools_geocoded_20160107_with_years.csv, clear
		drop if inlist(orig_st,"AS","FM","GU","MH","MP","PR","PW","VI")==1
gen year=orig_year
gen unitid=orig_unitid
save $datdir/ipeds_geocoded, replace
keep unitid year usfip confidence
rename usfip geocounty
tempfile tempgeo

save `tempgeo'


/*****************************
Read in hardcoded geographies.
******************************/

insheet using $rawdir/hardcodes_1.csv, clear 
	drop if inlist(orig_st,"AS","FM","GU","MH","MP","PR","PW","VI")==1
keep unitid year fips 
rename fips usfips 
sort unitid year
tempfile hardcodes 
save `hardcodes', replace


*Read in Jim's geocodes
use $datdir/ipeds_geocode_done, clear
keep unitid year countyfips
	rename countyfips changeme_countyfips
	duplicates drop
	tempfile tempjim
	save `tempjim'


*********************************************
* Merge everytinhg together
*********************************************
	use $datdir/ipeds_instchar, clear
	
	*FIRST, GEOCODES
	*Merge on first batch of geocodes		
		merge 1:1 unitid year using `tempgeo'
		drop _merge
	* MERGE IN HARDCODED GEOCODES 	
		merge 1:1 unitid year using `hardcodes'
		replace geocounty = usfips if _merge == 3
		drop _merge 
	*Merge in Jim's geocodes
		merge 1:1 unitid year using `tempjim'
			replace geocounty=changeme_county if changeme!=.		
	*Assign previous year's county if didn't move
			sort unitid year
			xtset unitid year
			forvalues y=1/20{
			replace geocounty=f.geocounty if geocounty==. & year<1997
			}
			forvalues y=1/20{
			replace geocounty=l.geocounty if geocounty==.
			}

		keep unitid year city zip stabbr sector geocounty
		merge 1:1 unitid year using $datdir/awsunitid_bycip
			drop if _merge==2
			drop _merge

	*Merge on cz identifiers
		rename geocounty fips
		replace fips = 12025 if fips == 12086
		gen cty_fips = fips
		sort cty_fips
		merge m:1 cty_fips using "/home/research/masslayoff/rawdata/cw_cty_czone"
			tab _merge
			tab year _merge
			replace fips = 12086 if cty_fips == 12025
			*keep if _merge==3/*some florida counties are weirdly not merging on*/
			drop _merge

	*save $datdir/ipeds_full_merged, replace
/******************************
value sector
0= 'Administrative Unit' 
1='Public 4-year or above'
2='Private nonprofit 4-year or above'
3='Private for-profit 4-year or above'
4='Public 2-Year'
5='Private nonprofit 2-year'
6='Private for-profit 2-year'
7='Public less-than-2-year'
8='Private nonprofit less-than-2-year'
9='Private for-profit less-than-2-year'

******************************/		
		
qui tab fips 
di r(r) 
gen insts=1
foreach outcome of varlist  insts zaw_*  {
	di "`outcome'"

			*Public CC's
			*bys fips year: egen cty_`outcome'_47 = sum(`outcome'*(sector==4|sector==7))
			bys czone year: egen cz_`outcome'_47 = sum(`outcome'*(sector==4|sector==7))
			*Private FP CC's
			*bys fips year: egen cty_`outcome'_69 = sum(`outcome'*(sector==6|sector==9)) 
			*bys czone year: egen cz_`outcome'_69 = sum(`outcome'*(sector==6|sector==9))	
			*2-year sector
			*bys fips year: egen cty_`outcome'_4769 = sum(`outcome'*(sector==4|sector==7|sector==6|sector==9)) 
			*bys czone year: egen cz_`outcome'_4769 = sum(`outcome'*(sector==4|sector==7|sector==6|sector==9))	
			
} 


bys fips year: egen cty_instcount = count(unitid) 
bys czone year: egen cz_instcount = count(unitid)
egen ggg=group(czone year)
egen taggg=tag(ggg)
	keep if taggg==1
	keep czone year cz_*
	
foreach outcome of varlist cz_zaw_* cz_insts{ 
	local newname = subinstr("`outcome'","cz_","",1) 
	rename `outcome' `newname'
} 

sort czone year 

drop if year>2011

*create logs

foreach out of varlist  zaw_* { 
	qui gen ln_`out'=ln(`out')
	*qui replace ln_`out'=0 if ln_`out'==. 
} 

*Save it here;
	save $datdir/awscip_bycz, replace
*/	

	
	*Merge it to Layoffs data;
#delimit;
use $datdir/cz_layoffs.dta, clear ;

sort czone year ;
merge 1:1 czone year using $datdir/awscip_bycz.dta ; 

tab _merge ; 
tab year _merge ;
drop if _merge == 2 ;


gen log_czlayoff = log(total_ext)  ;
	replace log_czlayoff = 0 if total_ext == 0  ;
	
label variable log_czlayoff  "Log(Layoff Count)"   ;
*replace log_czlayoff=log_czlayoff/100;




****************************************************************;
*Do CIP renames based on CIP00-Cip10 crosswalk;
do $prodir/regs/build_ciprenames;
;
**************************************************************;
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
;

******************************************************************;
*Table with Main Spec, College-Program Variables
***************************************************************;
/*preserve;
clear;
set obs 1;
gen spec="";
gen b=.;
gen se=.;
gen n=.;
save $datdir/cipcode_results, replace;

restore;
eststo clear;
local rhscovar log_`type'layoff;
			foreach outcome of varlist ln_z*{ ;
				preserve;
				di "`outcome'";
				qui areg `outcome' l1_log_czlayoff  l2_log_czlayoff l3_log_czlayoff yearfe* cztre* [weight=`weightvar'],   absorb(czone) cluster(`clustervar');
					local b1=_b[l1_log_czlayoff];
					local b2=_b[l2_log_czlayoff];
					local b3=_b[l3_log_czlayoff];
					local se1=_se[l1_log_czlayoff];
					local se2=_se[l2_log_czlayoff];
					local se3=_se[l3_log_czlayoff];
					qui sum `outcome' if year==1995;
						local n=exp(r(mean));
					clear;
					set obs 1;
					gen spec="`outcome'";
					gen b1=`b1';
					gen b2=`b2';
					gen b3=`b3';
					gen se1=`se1';
					gen se2=`se2';
					gen se3=`se3';
					gen n=`n';
					append using $datdir/cipcode_results;
					save $datdir/cipcode_results, replace;
					restore;
					};

		};
		};
*/
*******************************************************************************
*Get the N's		;

		#delimit cr
		clear
		
		

set obs 1
gen ns=.
tempfile tempns
save `tempns'
use $datdir/awscip_bycz, clear
*Do CIP renames based on CIP00-Cip10 crosswalk;
do $prodir/regs/build_ciprenames

collapse(sum) zaw*, by(year)
preserve
foreach g of varlist zaw*{
bysort year: egen trash=mean(`g')
qui sum trash
local n=r(mean)
clear
set obs 1
gen ns=`n'
gen spec="`g'"
append using `tempns'
save `tempns', replace
restore, preserve
}
	
use `tempns', clear
gen type="TOT" if regexm(spec,"tot")==1
replace type="1t4" if regexm(spec,"1t4")==1
replace type="lt1y" if regexm(spec,"lt1y")==1
replace type="aa" if regexm(spec,"aa")==1

replace spec=subinstr(spec,"1t4","",.)
replace spec=subinstr(spec,"lt1y","",.)
replace spec=subinstr(spec,"tot","",.)			
replace spec=subinstr(spec,"aa","",.)
gen cip=substr(spec,5,10)
replace cip=subinstr(cip,"_47","",.)
destring cip, gen(cip_code)
keep ns cip_code type
tempfile tempns1
save `tempns1', replace
***************************************************************
*Merge everything together				
				
use $datdir/cipcode_results, clear

gen type="TOT" if regexm(spec,"tot")==1
replace type="1t4" if regexm(spec,"1t4")==1
replace type="lt1y" if regexm(spec,"lt1y")==1
replace type="aa" if regexm(spec,"aa")==1

replace spec=subinstr(spec,"1t4","",.)
replace spec=subinstr(spec,"lt1y","",.)
replace spec=subinstr(spec,"tot","",.)			
replace spec=subinstr(spec,"aa","",.)
gen cip=substr(spec,8,10)
replace cip=subinstr(cip,"_47","",.)
destring cip, gen(cip_code)
drop n
merge 1:m type cip_code using `tempns1'
drop _merge
joinby cip_code using $datdir/TOPTABLE_LOOKUP, unmatched(both)
keep if _merge==3
collapse(mean) b1 b2 b3 se1 se2 se3 (sum) n, by(top4_code type)
tostring top4, replace
replace top4="0"+top4 if length(top4)<6
replace top4=substr(top4,1,4)
rename top4 top4
renpfix b lay_b
renpfix se lay_se
reshape wide lay_b1 lay_b2 lay_b3 lay_se1 lay_se2 lay_se3 n, i(top4) j(type) string

tempfile tempccc
save `tempccc'

use $datdir/returns_top4s, clear
keep if cont=="Fullfull" | cont=="_Fullfull"
drop cont
reshape wide b se, i(top4) j(type) string
merge 1:m top4 using `tempccc'
save $datdir/cipcode_forgraphs, replace

*******************************************
*Scatterplots
*******************************************
*/
use $datdir/cipcode_forgraphs.dta, clear 

foreach suff in 1t4 aa lt1y {
	gen b_tot_`suff' = (lay_b1`suff'+lay_b2`suff'+lay_b3`suff') 
	gen se_tot_`suff'=(lay_se1`suff'^2+lay_se2`suff'^2+lay_se3`suff'^2)^(1/2)
	gen sig_tot_`suff'=abs(b_tot_`suff'/se_tot_`suff')>1.96
}

rename (bAAAS bCertSmall seAAAS seCertSmall)(return_aa return_lt1y se_aa se_lt1y)
gen return_1t4 = (bCert1830 + bCert3060)/2
gen se_1t4=(bCert1830^2 + bCert3060^2)/2
foreach g in aa 1t4 lt1y{
	gen sig_ret_`g'=abs(return_`g'/se_`g')>1.96
	}


keep return_* b_tot* ns* top4 sig*
drop nsTOT

local x = 1 
foreach suff in 1t4 aa lt1y {
	rename return_`suff' return_`x'
	rename b_tot_`suff' b_tot_`x'
	rename sig_ret_`suff' sig_ret_`x'
	rename sig_tot_`suff' sig_tot_`x'
	rename ns`suff' ns`x'
	local x = `x' + 1 
}

reshape long return_ b_tot_ ns sig_tot_ sig_ret_, i(top4) j(newcat)

gen category = "1-4 Yr" if newcat == 1
	replace category = "AA" if newcat == 2
	replace category = "Less Than 1yr" if newcat == 3
	
	
keep if b_tot_ != 0 & return_ > -3 


*All
twoway (scatter b_tot_ return_  [weight = ns], msymbol(circle_hollow) ) (lfit b_tot_ return_  [weight=ns], lcolor(red))
	graph export "$figdir/scatter_bycip_all.eps", replace
	reg b_tot_ return_ [weight=ns], r
*Significant Returns
twoway (scatter b_tot_ return_  [weight = ns] if sig_ret==1, msymbol(circle_hollow) ) (lfit b_tot_ return_  [weight=ns]  if sig_ret==1, lcolor(red))
	graph export "$figdir/scatter_bycip_sigret.eps", replace
	reg b_tot_ return_ [weight=ns]  if sig_ret==1, r
*Significant Coeff
twoway (scatter b_tot_ return_  [weight = ns] if sig_tot==1, msymbol(circle_hollow) ) (lfit b_tot_ return_  [weight=ns]  if sig_tot==1, lcolor(red))
	graph export "$figdir/scatter_bycip_sigtot.eps", replace
	reg b_tot_ return_ [weight=ns]  if sig_tot==1, r
*Significant Coeff AND significant return
twoway (scatter b_tot_ return_  [weight = ns] if sig_tot==1 & sig_ret==1, msymbol(circle_hollow) ) (lfit b_tot_ return_  [weight=ns]  if sig_tot==1 & sig_ret==1, lcolor(red))
	graph export "$figdir/scatter_bycip_sigrettot.eps", replace
	reg b_tot_ return_ [weight=ns]  if sig_tot==1 & sig_ret==1, r


*


#delimit;
twoway (scatter b_tot_ return_  [weight = ns] if newcat==1, msymbol(circle_hollow)  )
		(scatter b_tot_ return_  [weight = ns] if newcat==2, msymbol(circle_hollow) )
		(scatter b_tot_ return_  [weight = ns] if newcat==3, msymbol(circle_hollow) )
		 (lfit b_tot_ return_  [weight=ns], lcolor(red)), 
		 legend(order(2 "AA/AS" 1 "1-4 Year"  3 "<1 Year"));
	graph export "$figdir/scatter_bycip_all_bytype.eps", replace;





