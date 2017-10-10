/***********************************
This do-file residualizes enrollment 
and degree outcomes,
and then graphs them for a select number of CZs

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

#delimit ; 
keep if year>=1996;
/*************************
Create residuals 
*************************/

global mainoutcomes  ffe_tot   ;
gen sample = 0 ; 
foreach outcome in $mainoutcomes { ; 
	areg ln_`outcome' i.year,absorb(czone) ; 
		replace sample = 1 if e(sample) ;
	predict resid_ln_`outcome', residuals  ;
}; 
tab sample; 
keep if sample ==1 ;
list year if czone == 4301 ; 	
levelsof czone, local(czones) ; 

forvalues ii = 1/10  { ;
	local czone = real(word("`czones'",`ii'));
	di "HERE" ;
	di "graphing residuals for czone : `czone'" ;
	twoway (connected resid_ln_ffe_tot year if czone == `czone' ) 
	        /*(connected resid_ln_aw_tot year if czone == `czone',yaxis(2) )*/,
			 ;
			
			graph export "$figdir/pred_`outcome'_`czone'.pdf", replace; 
} ;

tempname trendresults ;
tempfile post_out ;

di "`czones'" ;
di "$mainoutcomes"  ;
foreach czone in `czones' { ; 
	qui tab year if czone == `czone' ;
	drop if r(r) < 2 & czone == `czone' ; 
};

levelsof czone, local(czones) ;

foreach outcome in $mainoutcomes { ; 

postfile trends_`outcome' czone beta se tstat df totalpop using `post_out', replace;
di "HERE" ; 
	foreach czone in `czones'  { ; 
		di "czone: `czone'" ; 
		sum year if czone == 1 ;
		 capture noisily reg resid_ln_`outcome' year if czone == `czone', r ;
			local beta = _b[year];
			local se = _se[year];
			local tstat = `beta'/`se' ;
			local tstat_abs = abs(`tstat') ;
			local df = r(df) ;
			sum total_pop if czone == `czone' ;
			local pop = r(mean) ;
			post trends_`outcome' (`czone') (`beta') (`se') (`tstat_abs') (`df') (`pop')  ;
		} ;	
	 
postclose trends_`outcome' ;
di "closed" ; 
di "opening" ;
use `post_out', clear ;
di "***************************************";
di "**** OUTCOME: `outcome' ***************" ;
sum tstat,d ;
sum tstat [weight=totalpop], d; 
sum beta, d ;
centile tstat, centile(5(5)95);
di "***************************************" ; 
save "$datdir/postfile_`outcome'.dta", replace ; 
} ;

end