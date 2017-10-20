/*******************************************************************************************
Program Name: educ_layoff_merge

Merges layoff and education data

Author:ADF
DATE: 01/26/2016
**********/
clear
global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global logdir "$rootdir/log"
global figdir "$rootdir/out/fig"
global tabdir "$rootdir/out/tab"
set maxvar 32000

#delimit ; 


/******************************
FIRST THE COUNTY DATA
******************************/

use $datdir/cty_layoffs.dta, clear ;

sort fips year ;
merge 1:1 fips year using $datdir/COUNTY_EDUCATION_DATA.dta ;

tab _merge ;
tab year _merge ;
drop if _merge == 2 ;
sum ;

save $datdir/CTY_ED_LAYOFF.dta, replace ; 

use $datdir/cz_layoffs.dta, clear ;

sort czone year ;
merge 1:1 czone year using $datdir/CZ_EDUCATION_DATA.dta ; 

tab _merge ; 
tab year _merge ;
drop if _merge == 2 ;

sum ; 

save $datdir/CZ_ED_LAYOFF.dta, replace ;

log close ;
