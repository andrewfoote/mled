global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global prodir "$rootdir/prog"
global figdir "$rootdir/fig"
global tabdir "$rootdir/tab"
global logdir "$rootdir/log" 

use $datdir/ipeds_instchar, clear
sort unitid year 
merge 1:1 unitid year using $datdir/fallenra_freshman_clean
		drop if _merge==2
		drop _merge
		renpfix ef ffe
des 
#delimit ; 
keep if year>=1996 ; 
sort unitid year ;
xtset unitid year ;
tab year ; 
gen missing_previousyear = (year[_n] != year[_n-1]+1 & year > 1996 & year< 2015) ;

tab missing_previousyear ; 

bys unitid: egen missing_year = max(missing_previousyear) ;

tab missing_year ;

list unitid year countycd ffe_tot if missing_year == 1; 