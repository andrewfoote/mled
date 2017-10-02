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


use $datdir/CTY_ED_LAYOFF, clear
do $prodir/preamble_cty.do
 
 drop _merge
merge m:1 fips using `czone'
	tab _merge


	xtset fips year
	gen shaw_CTE=aw_tot_CTE/aw_tot
	gen shaw_CON=aw_tot_CON/aw_tot
	gen shaw_HEA=aw_tot_HEA/aw_tot

	gen chaw_CTE=(aw_tot_CTE/aw_tot)-(l5.aw_tot_CTE/l5.aw_tot)
	gen chaw_CON=(aw_tot_CON/aw_tot)-(l5.aw_tot_CON/l5.aw_tot)
	gen chaw_HEA=(aw_tot_HEA/aw_tot)-(l5.aw_tot_HEA/l5.aw_tot)

*5-year changes	
	foreach y in 2010{
	preserve
	keep if year==`y'
	save $datdir/mapdata, replace
		foreach g in CTE HEA CON {	
			global mapva "chaw_`g'"
			global mapnam "map_chaw_`g'_`y'"
			global mapcol "BuRd"
			local clmeth "custom"			
			do "$prodir/regs/analy_countymaps_2.do"
			}
	restore	
}


*Year by Year
	foreach y in 2010{
	preserve
	keep if year==`y'
	save $datdir/mapdata, replace
		foreach g in CTE HEA CON {	
			global mapva "shaw_`g'"
			global mapnam "map_shaw_`g'_`y'"
			local clmeth "custom"
			global mapcol "Blues"
			do "$prodir/regs/analy_countymaps_2.do"
			}
	restore	
}


	


