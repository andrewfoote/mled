/*******************************************************************************************
Program Name: county_adjacency
Purpose: Counting the number of layoffs in adjacent counties 
[original] Location:/home/research/masslayoffs/dofiles
Author:ADF
Date:9/13/2013
Project: Mass Layoffs and Labor Market Adjustments
Taken from this project for the Mass Layoffs and Education Project
***********************************************************************************************/

clear all
set more off 
cap log close 
set mem 800m 
set matsize 2000 
set maxvar 10000
set matsize 10000

global logdir "/home/research/masslayoff/education/log" 
global eddata "/home/research/masslayoff/education/data" 
global dodir "/home/research/masslayoff/dofiles/creation_dofiles"
global datadir "/home/research/masslayoff/data" 
global rawdatadir "/home/research/masslayoff/rawdata" 
global resultsdir "/home/research/masslayoff/results" 

log using "${logdir}/county_adjacency_newdata.log", replace


use "${datadir}/layoffs_ext.dta", clear 

gen stfip = floor(fips/1000) 

drop if fips - (stfip*1000) == 999 
drop if stfip == 2 | stfip == 15 | stfip == 11 | stfip>56

tab year

sort fips year 

keep fips year total_ext
rename fips adj

tempfile layoffsadj
save `layoffsadj', replace

use "${datadir}/layoffs_migration_extdata.dta", clear 
keep if year>=1995
keep fips year lau_LF
rename fips adj
sort adj year
tempfile laborforce
save `laborforce', replace

insheet using "${rawdatadir}/county_adjacency.txt", clear

rename v2 fips
rename v4 adj
drop v*
replace fips = fips[_n-1] if fips == .
gen adjacent = 1

do "${dodir}/county_recodes.do"

rename fips fips2
rename adj fips

do "${dodir}/county_recodes.do"
rename fips adj 
rename fips2 fips

collapse (first) adjacent, by(fips adj)
drop adjacent

drop if fips>56999
drop if adj>56999

tab adj if fips == ., m
tab fips if adj == ., m

expand 16
bys fips adj: gen year = 1994 + _n
tab year
****** ADDED***********
gen stfip = floor(fips/1000) 

drop if fips - (stfip*1000) == 999 
drop if stfip == 2 | stfip == 15 | stfip == 11 | stfip>56
****** ADDED***********

sort adj year
merge adj year using `layoffsadj'

tab _merge
tab year _merge
tab adj if _merge == 2, m
drop if _merge == 2 /* dropping two alaska counties and one virginia cty */
drop _merge

sort adj year
merge adj year using `laborforce'

tab _merge
tab year _merge
tab adj if _merge == 2, m
tab adj if _merge == 1, m
drop if _merge == 2 /* dropping two alaska counties and one virginia cty */
drop _merge

bys fips year: egen double adjacent_layoffs_ext = sum(total_ext*(fips!=adj))
bys fips year: egen double adjacent_LF = sum(lau_LF*(fips!=adj))

list in 1/10

collapse (first) adjacent_layoffs_ext adjacent_LF, by(fips year)
sum, d

label variable adjacent_layoffs_ext "Layoffs in Adjacent Counties"
label variable adjacent_LF "Labor Force in Adjacent Counties"
label variable fips "County"
label variable year "Year"

sort fips year

tempfile adjlay
save $eddata/adjacent_masslayoffs.dta, replace

codebook adjacent_layoffs_ext 
sum adjacent_layoffs_ext,d 

log close 
