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
des ;
/*************************
Create residuals 
*************************/

global mainoutcomes tef_tot ffe_tot  aw_tot aw_aa aw_1t4 aw_lt1y ;

foreach outcome in $mainoutcomes { ; 
	areg ln_`outcome' i.year,absorb(czone) ; 
	predict resid_ln_`outcome', residuals  ;
}; 

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

tempfile trendresults ;
tempfile postout ;


foreach outcome in $mainoutcomes { ; 
postfile `trendresults' czone beta se tstat df using `post_out', replace; 
	foreach czone in `czones'  { ; 
		areg resid_ln_`outcome' year if czone == `czone', r ;
			local tstat = abs(_b[year]/_se[year]) ;
			post `trendresults' (`czone') (_b[year]) (_se[year]) (`tstat') (r(df)) ;
	} ; 
postclose `trendresults' ;

use `post_out', clear ;
di "***************************************";
di "**** OUTCOME: `outcome' ***************" ;
sum tstat,d ;
di "***************************************" ; 
save $datadir/postfile_`outcome'.dta, replace ; 
} ;

end