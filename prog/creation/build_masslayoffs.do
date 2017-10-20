/*******************************************************************************************
Program Name: build_masslayoffs

Prep the masslayoffs data for merging 
with IPEDS collapsed data

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

log using "$logdir/build_masslayoffs.log", replace
#delimit ; 

cd /home/research/masslayoff/data ;
	use FINAL_MASSLAYOFF_DATA, clear ;
		*keep fips year total_ext lau* cty* total_pop
		drop if fips >= 2000 & fips <=2999 ;
		drop if fips >= 51900 & fips <=51999 ;
		
		des, full ;
		
		
	keep fips year total_age_*_pop total_pop total_under30_ext total_age3044_ext total_age4554_ext total_age55p_ext  total_male_pop total_female_pop total_black_pop total_white_pop
					total_ext adjacent_layoffs_ext ctytrend* lau_LF;
	sum ;
	tab year, gen(yearfe) ;		
		
	save $datdir/cty_layoffs.dta, replace ;
	gen cty_fips = fips ;
	sort cty_fips ;
	replace cty_fips = 12025 if cty_fips == 12086 ;
	/* we need to fix VA independent cities */
	merge m:1 cty_fips using "/home/research/masslayoff/rawdata/cw_cty_czone" ;
	
	tab _merge ;
	tab fips _merge if _merge != 3 ;
	drop if _merge != 3 ;
	
	collapse (sum) total_age_*_pop total_pop total_under30_ext total_age3044_ext total_age4554_ext total_age55p_ext lau_LF
	total_male_pop total_female_pop total_black_pop total_white_pop
					total_ext, by(czone year) ;
					
	sum;					
					
	qui tab czone, gen(cz_fe) ;
	
	levelsof czone, local(czones) ;
	gen t=year-1996  ;

	tab year, gen(yearfe) ;

	foreach j in `czones' { ;
		gen cztrend`j'=(czone == `j' )*t ;
	} ;
		
	save $datdir/cz_layoffs.dta, replace ;
		
		
log close ;
