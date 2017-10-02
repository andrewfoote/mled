/*******************************************************************************************
Program Name: build_ipeds
REad in IPEDS data on completions by college.
Author:MZG
Project:
**********/

global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global logdir "$rootdir/log"
global figdir "$rootdir/out/fig"
global tabdir "$rootdir/out/tab"
set maxvar 32000


/*INPUTS*/
	*ipeds_instchar: year-by-unitid sector info (created in build_ipeds_institution)
	*foote_schools_geocoded and hardcodes: link from unitid to fips
	*ipeds_awards: ipeds data on awards by gender and broad cip categories (created in build_ipeds_aws)
	*layoffs data:(built in main masslayoff folder)
		*final_masslayoff_data: at the county level 
		*finalmasslayoff_czone: at the cz level
	*ipeds_fallenr: fall enrollment data by age, part/fulltime, and gender (created in raw/ipeds_fallenr/readin)
		*NOTE: THIS dataset is still a little wacky.









*********************************************************************
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
			forvalues y=1/30{
			replace geocounty=f.geocounty if geocounty==. 
			replace geocounty=f2.geocounty if geocounty==.
			replace geocounty=f3.geocounty if geocounty==.
			}
			forvalues y=1/30{
			replace geocounty=l.geocounty if geocounty==.
			replace geocounty=l2.geocounty if geocounty==.			
			replace geocounty=l3.geocounty if geocounty==.			
			}

		keep unitid year city zip stabbr sector geocounty
		
		
	*NOW, IPEDS DATA
	*Merge on Ipeds data on awards (created in build_ipeds_aws)
		
		merge 1:1 unitid year using $datdir/ipeds_awards
			drop if _merge==2
			drop _merge
			drop aw_f_* aw_m_* aw_ba_*
	*Merge on IPEDS data on fall enrollment
		merge 1:1 unitid year using $datdir/fallenra_total_clean
		drop if _merge==2
		drop _merge
		renpfix ef tef
	*Merge on IPEDS data on fall freshmen enrollment
		merge 1:1 unitid year using $datdir/fallenra_freshman_clean
		drop if _merge==2
		drop _merge
		renpfix ef ffe
		
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

	*Create sensitivy check outcome data based on number of missing years of data
		*Always included
				gen has_anyoutcome=aw_tot!=. & tef_tot!=. & ffe_tot!=. & year>1995
				bysort unitid: egen totalhas_anyoutcome=total(has_anyoutcome)
				gen flag_alwayshas=totalhas==17
			*Not missing when nonmissing on either side
				xtset
				gen sandwich1=has_anyoutcome==0 & f.has_anyoutcome==1 & l.has_anyoutcome==1
				bysort unitid: egen flag_sandwich1=total(sandwich1)
				gen flag_nosandwich1=flag_sandwich1==0
			*Not missing when nonmissing on either side at 2-year intervals
				xtset
				gen sandwich2=has_anyoutcome==0 & (f.has_anyoutcome==1|f2.has_anyoutcome==1) & (l.has_anyoutcome==1 | l2.has_anyoutcome==1)
				bysort unitid: egen flag_sandwich2=total(sandwich2)
				gen flag_nosandwich2=flag_sandwich2==0
			*Existed in 1996 (first year of data)
				gen ext_1996=has_anyoutcome==1 if year==1996
				bysort unitid: egen flag_in1996=total(ext_1996)
				replace flag_in1996=flag_in1996>0
			
			foreach v of varlist aw_tot aw_lt1y aw_1t4 aw_aa ffe_tot tef_tot{
				gen `v'_always=`v' if flag_alwayshas==1
				gen `v'_nosand1=`v' if flag_nosandwich1==1
				gen `v'_nosand2=`v' if flag_nosandwich2==1
				gen `v'_in1996=`v' if flag_in1996==1
				}
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
foreach outcome of varlist  insts aw_* tef* ffe* {
	di "`outcome'"
	bys fips year: egen cty_`outcome' = sum(`outcome')
	
	bys czone year: egen cz_`outcome' = sum(`outcome')
	
			*Public CC's
			bys fips year: egen cty_`outcome'_47 = sum(`outcome'*(sector==4|sector==7))
			bys czone year: egen cz_`outcome'_47 = sum(`outcome'*(sector==4|sector==7))
			*Private FP CC's
			bys fips year: egen cty_`outcome'_69 = sum(`outcome'*(sector==6|sector==9)) 
			bys czone year: egen cz_`outcome'_69 = sum(`outcome'*(sector==6|sector==9))	
			*2-year sector
			bys fips year: egen cty_`outcome'_4769 = sum(`outcome'*(sector==4|sector==7|sector==6|sector==9)) 
			bys czone year: egen cz_`outcome'_4769 = sum(`outcome'*(sector==4|sector==7|sector==6|sector==9))	
			
} 


bys fips year: egen cty_instcount = count(unitid) 
bys czone year: egen cz_instcount = count(unitid)

tempfile czones 
save `czones', replace  


collapse (first) cty_*, by(fips year) /* this creates a cz-year dataset of enrollment, awards, etc */

tab year
* foreach outcome in aw_tot aw_lt1y aw_aa aw_1t4 { 
		* rename cty_`outcome' `outcome' 
	* foreach field in CTE IT CON PUB HEA BUS FAM EDU PER { 
		* rename cty_`outcome'_`field' `outcome'_`field'
	* } 
* } 

foreach outcome of varlist  cty_tef_* cty_ffe_* cty_aw_* { 
	local newname = subinstr("`outcome'","cty_","",1) 
	rename `outcome' `newname'
} 

sort fips year

des, full
save $datdir/COUNTY_EDUCATION_DATA.dta, replace

sum 

use `czones', clear

collapse (first) cz_*, by(czone year) /* this creates a cz-year dataset of enrollment, awards, etc */

foreach outcome of varlist cz_aw_* cz_insts cz_tef_* cz_ffe_*{ 
	local newname = subinstr("`outcome'","cz_","",1) 
	rename `outcome' `newname'
} 

sort czone year 
save $datdir/CZ_EDUCATION_DATA.dta, replace

tab year, m 

sum

end 

		dddd
* HERE, I WILL CALCULATE THE OUTCOME VARIABLES AND THEN COLLAPSE TO A CTY YEAR PANEL, AND A CZ-YEAR PANEL
* ALSO ON TO - DO LIST IS DO A COUNTY YEAR PANEL WITH ADJACENT COUNTY LAYOFFS AS WELL
	*just keep some layoff data
	cd /home/research/masslayoff/data
	use FINAL_MASSLAYOFF_DATA, clear
		keep fips year total_ext lau* cty* total_pop
		tempfile templay
		save `templay'

	*Just keep some CZ data
	use FINALMASSLAYOFFS_CZONE
		keep czone year total_ext lau* total_pop
			renpfix total cz_total
			renpfix lau cz_lau
			tempfile tempcz
			save `tempcz'
		restore
	*Merge on county-level mass layoffs
		merge m:1 fips year using `templay'			
	*Merge on CZ level mass layoffs
		drop _merge
		merge m:1 czone year using `tempcz'
	
	*Drop Territories
	save $datdir/MASSLAYOFF_EDUCATION_DATA, replace
	
log close 