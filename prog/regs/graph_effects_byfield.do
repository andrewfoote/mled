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

#delimit ;
use "$datdir/EFFECTS_BY_FIELD.dta", clear ; 

keep if level == "ln_aw_tot" ; 
 sort response ; 
graph bar response, over(program_name)
	 ytitle("Degree Effect")
	;
	
	graph export $figdir/total_byprogram.pdf, replace ;