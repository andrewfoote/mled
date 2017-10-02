/***********************************
This do-file checks for outliers.

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
global mainoutcomes tef_tot ffe_tot  aw_tot aw_aa aw_1t4 aw_lt1y ;
xtset czone year ;
foreach outcome in $mainoutcomes { ;
	gen change_`outcome' = `outcome' - L.`outcome' ; 
	gen pctchange_`outcome' = change_`outcome'/L.`outcome' ; 
	di "TABULATIONS FOR OUTCOME `outcome'" ; 
	/*
	bys year: egen max_`outcome' = max(`outcome'*(`outcome'!=.)) ;
	list czone year `outcome' if `outcome' == max_`outcome' ; */
	
	tabstat change_`outcome' if `outcome' > 0 , by(year) statistics(mean min p5 p25 p50 p75 p95 max) ; 
	tabstat pctchange_`outcome' if `outcome' > 0 [weight=total_pop], by(year) statistics(mean min p5 p25 p50 p75 p95 max) ; 
};

gen change_instspub = cz_insts_47 - L.cz_insts_47 ; 
tab year change_instspub, m ; 
tabstat change_instspub, by(year) statistics( min p5 p50 p95 max N) ;
tabstat change_instspub if change_instspub!=0, by(year) statistics( min p5 p50 p95 max N) ;
