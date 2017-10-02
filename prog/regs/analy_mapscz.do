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
local mapdir "$datdir/maps"
local finishedmap "$figdir"



rename cty_fips fips 
sort fips 
tempfile czone
save `czone', replace


use $datdir/CZ_ED_LAYOFF, clear
do $prodir/preamble_cz.do
 


 ***************************************************************
 *Set Up the Data
 ************************************************************
	*Create outcomes to maps
	xtset czone year
	
	gen sh2y=tef_tot_47/tef_tot
	gen shaw_CTE=aw_tot_CTE_47/aw_tot_47
	gen shaw_CON=aw_tot_CON_47/aw_tot_CTE_47
	gen shaw_HEA=aw_tot_HEA_47/aw_tot_CTE_47
	gen shaw_FAM=(aw_tot_FAM_47+aw_tot_PER_47)/aw_tot_CTE_47

	*gen chaw_CTE=(aw_tot_CTE/aw_tot)-(l5.aw_tot_CTE/l5.aw_tot)
	*gen chaw_CON=(aw_tot_CON/aw_tot)-(l5.aw_tot_CON/l5.aw_tot)
	*gen chaw_HEA=(aw_tot_HEA/aw_tot)-(l5.aw_tot_HEA/l5.aw_tot)

	*gen lchaw_CTE=(aw_tot_CTE/aw_tot)-(l10.aw_tot_CTE/l10.aw_tot)
	*gen lchaw_CON=(aw_tot_CON/aw_tot)-(l10.aw_tot_CON/l10.aw_tot)
	*gen lchaw_HEA=(aw_tot_HEA/aw_tot)-(l10.aw_tot_HEA/l10.aw_tot)
	
	gen sh_tef=tef_tot/total_pop
	gen ch5_tef=(tef_tot_47-l5.tef_tot_47)/l5.tef_tot_47
	
	
keep year czone  shaw*  sh_tef ch5_ sh2

	*Set up the data for mapping	
	rename czone cz
		merge m:1 cz using `mapdir'/cz_database_clean
		keep if _merge==3
		drop if inlist(state,"AK","HI")==1
		rename id _ID
	preserve

**********************************************
*Make Some Maps 
**********************************************	

		
	*Point-in-time Shares
		foreach g in sh_tef sh2y shaw_CTE shaw_CON shaw_HEA shaw_FAM{
		foreach y in 2000 2005 2010{
		keep if year==`y'
		spmap `g' using "`mapdir'/cz_coords_clean.dta", id(_ID) fcolor(Blues) clnumber(6) 
		graph export "`finishedmap'/`g'_`y'.eps", replace
		restore, preserve
		}
		}
		dddd
		
		*5 Year Changes	
	foreach g in chaw_CTE chaw_CON chaw_HEA ch5_tef{
		foreach y in 2005 2010{
		keep if year==`y'
		spmap `g' using "`mapdir'/cz_coords_clean.dta", id(_ID) fcolor(RdYlBu) `cloption' saving("`finishedmap'/chaw_`g'_`y'.gph", replace)
		graph export "`finishedmap'/`g'_`y'.eps", replace
		restore, preserve
		}
		}
			
		
	*10 Year Changes	
	foreach g in CTE CON HEA{
		foreach y in 2010{
		keep if year==`y'
		spmap lchaw_`g' using "`mapdir'/cz_coords_clean.dta", id(_ID) fcolor(RdYlBu) `cloption' saving("`finishedmap'/lchaw_`g'_`y'.gph", replace)
		graph export "`finishedmap'/lchaw_`g'_`y'.eps", replace
		restore, preserve
		}
		}
				
