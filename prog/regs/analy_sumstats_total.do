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
global figdir "$rootdir/fig"
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
			forvalues y=1/20{
			replace geocounty=f.geocounty if geocounty==. & year<1997
			}
			forvalues y=1/20{
			replace geocounty=l.geocounty if geocounty==.
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

			
			
			
			
*****************************************************
*Aggregate Time Series
*****************************************************			
	preserve
	foreach g in ffe_tot tef_tot aw_tot aw_tot_CTE aw_tot_HEA aw_tot_IT aw_tot_CON aw_aa aw_1t4 aw_lt1y{
		gen c4_`g'=`g'*(sector<4 & sector>0)
		gen c2_`g'=`g'*(inlist(sector,4,7,6,9)==1)
		gen c2pr_`g'=`g'*(inlist(sector,6,9)==1)
		gen c2pu_`g'=`g'*(inlist(sector,4,7)==1)
		}
	collapse(sum) ffe_tot tef_tot aw_tot aw_aa aw_ba aw_1t4 aw_lt1y c2* c4* , by(year)
		foreach var of varlist ffe* tef* aw_* c*{
			replace `var'=`var'/100000
			}
		keep if year>1995 & year<2012
		#delimit;
		twoway (scatteri 20 2001.1 20 2001.9, bcolor(gs13) recast(area) ) 
				(scatteri 20 2007.9 20 2009.5, bcolor(gs13) recast(area) )
				(scatter c4_ffe_tot c2pr_ffe_tot c2pu_ffe_tot year, connect(l l l) lcolor(gs10 gs6 black) mcolor(gs10 gs6 black) lpattern(solid dash shortdash) msymbol(triangle circle square)), graphregion(color(white)) bgcolor(white) ylab(, nogrid)
				legend(order(3 "4-Year" 5 "2-Year Public" 4 "2-Year For-Profit" 1 "Recession"))
				ytitle("First-Time Fall Enrollment (100,000)");
			graph export "$figdir/ffe_byyear.eps", replace;
			graph export "$figdir/ffe_byyear.pdf", replace;

		twoway (scatteri 105 2001.1 105 2001.9, bcolor(gs13) recast(area) ) 
				(scatteri 105 2007.9 105 2009.5, bcolor(gs13) recast(area) )
				(scatter c4_tef_tot c2pr_tef_tot c2pu_tef_tot year, connect(l l l) lcolor(black black black) mcolor(black black black) lpattern(solid dash shortdash)), graphregion(color(white)) bgcolor(white) ylab(, nogrid)
				legend(order(3 "4-Year" 5 "2-Year Public" 4 "2-Year For-Profit" 1 "Recession"))
				ytitle("First-Time Fall Enrollment (100,000)");
			graph export "$figdir/tef_byyear.eps", replace;

		twoway (scatteri 20 2001.1 20 2001.9, bcolor(gs13) recast(area) ) 
				(scatteri 20 2007.9 20 2009.5, bcolor(gs13) recast(area) )
				(scatter aw_aa aw_ba aw_1t4 aw_lt1y year, connect(l l l l) lcolor(black black black black ) mcolor(black black black black) lpattern(solid solid solid solid) msymbol(O T S X)), graphregion(color(white)) bgcolor(white) ylab(, nogrid)
				legend(order(3 "BA/BS" 4 "AA/AS" 5 "1-4 Year Cert." 6 "<1 Year Cert"  1 "Recession"))
				ytitle("Degrees and Certificates (100,000)");
			graph export "$figdir/aw_byyear.eps", replace;

			
		foreach g in CON IT HEA CTE{;
			gen s`g'=c2_aw_tot_`g'/c2_aw_tot;
			};
			
		twoway (scatteri 1 2001.1 1 2001.9, bcolor(gs13) recast(area) ) 
				(scatteri 1 2007.9 1 2009.5, bcolor(gs13) recast(area) )
				(scatter sCTE sCON sIT sHEA  year, connect(l l l l) lcolor(black black black black ) mcolor(black black black black) lpattern(solid solid solid solid) msymbol(O T S X)), graphregion(color(white)) bgcolor(white) ylab(, nogrid)
				legend(order(3 "CTE" 4 "Construction/Manufac." 5 "IT" 6 "Health"  1 "Recession"))
				ytitle("Share of 2-Year Public Degrees and Certificates");
			graph export "$figdir/saw_byyear.eps", replace;

			
			
		twoway (scatteri 6 2001.1 6 2001.9, bcolor(gs13) recast(area) ) 
				(scatteri 6 2007.9 6 2009.5, bcolor(gs13) recast(area) )
				(scatter c2pu_aw_aa c2pu_aw_1t4 c2pu_aw_lt1 c2pr_aw_aa c2pr_aw_1t4 c2pr_aw_lt1 year, connect(l l l l l l ) lcolor(black black black red red red  ) mcolor(black black black red red red ) msymbol(O T S Oh Th Sh)), graphregion(color(white)) bgcolor(white)  ylab(, nogrid)
				legend(order( 3 "Public AA/AS" 4 "Public 1-4 Year " 5 "Public <1 Year " 6 "Public AA/AS" 7 "Public 1-4 Year " 8 "Public <1 Year " 1 "Recessions") col(3))
				ytitle("Degrees and Certificates (100,000)");
			graph export "$figdir/aw_byyear_prpu.eps", replace;			


			foreach g in CON IT HEA CTE{;
			gen spr_aw_tot_`g'=c2pr_aw_tot_`g'/c2pr_aw_tot;
			gen spu_aw_tot_`g'=c2pu_aw_tot_`g'/c2pu_aw_tot;
			};			
				
		twoway (scatteri 1 2001.1 1 2001.9, bcolor(gs13) recast(area) ) 
				(scatteri 1 2007.9 1 2009.5, bcolor(gs13) recast(area) )
				(scatter spu_aw_tot_CTE spr_aw_tot_CTE  year, connect(l l l l l l ) lcolor(black black black red red red  ) mcolor(black black black red red red ) msymbol(O T S Oh Th Sh)), graphregion(color(white)) bgcolor(white)
				legend(order( 3 "Public 2-Year " 4 "Private 2-Year" 1 "Recessions") col(3))
				yscale(r(0(0.2)1)) ylabel(0(0.2)1, nogrid)
				ytitle("CTE Share of all Degrees and Certificates");				
			graph export "$figdir/aw_byyear_prpus.eps", replace;			
				
	restore	

			
*****************************************************
*Aggregate Time Series
*****************************************************			
		gen one=1
		gen one_fp=one*(sector==6|sector==9)