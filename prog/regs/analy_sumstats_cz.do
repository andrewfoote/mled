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
local theusual "replace noconstant nomtitles noobs nogaps  noline nonumbers compress label "


use "/home/research/masslayoff/rawdata/cw_cty_czone", clear

rename cty_fips fips 
sort fips 
tempfile czone
save `czone', replace

use "/home/research/masslayoff/data/FINALMASSLAYOFFS_CZONE", clear
keep czone year lau*
duplicates drop
tempfile lau
save `lau'

 

use $datdir/CZ_ED_LAYOFF, clear
do $prodir/preamble_cz.do
 merge 1:1 year czone using `lau', gen(mergelau)
 drop mergelau
 
 
 gen total_ext_shareLF=total_ext/lau_LF
 gen urate=(lau_LF-lau_emp)/lau_LF
 gen sh_1=total_ext_shareLF>0.01
 gen sh_3=total_ext_shareLF>0.03
 gen sh_5=total_ext_shareLF>0.05
 gen noinsts=cz_insts_47==0 & cz_insts_69==0
 gen workage=total_age_19_44+total_age_45_59
 gen no_fouryear=cz_insts_47+cz_insts_6==cz_instc
 foreach g of varlist total_age* total_pop workage{
	replace `g'=`g'/1000
	}
 
 
label var total_ext           "Workers in Mass Layoffs"
label var total_ext_share     "Workers in Mass Layoffs as Share of Labor Force"
label var sh_1                "Layoffs $>$ 1\% of Labor Force"
label var sh_5                "Layoffs $>$ 5\% of Labor Force"
label var urate               "Unemployment Rate"
label var total_pop           "Population (1000s) "
label var total_age_18_29     "Population Age 18-29 (1000s) "
label var total_age_30_44     "Population Age 30-44 (1000s) "
label var total_age_45_54     "Population Age 45-54 (1000s) "
label var workage			  "Population Age 18-60 (1000s) "
label var cz_insts_47         "Community Colleges"
label var cz_insts_69         "For-Profit 2-year Colleges"
label var noinsts             "No 2-Year Institutions in CZ"
label var no_fouryear		  "Only 2-Year Institutions in CZ"
label var tef_tot_47          "Community College Fall Enrollment"
label var tef_tot_69          "For-Profit Fall Enrollment"
label var ffe_tot_47          "First-time Freshmen, Community College"
label var ffe_tot_69          "First-time Freshmen, For-Profits"
label var aw_aa               "Associate's Degrees"
label var aw_1t4              "1-4 Year Certificates"
label var aw_lt1y             "$<$ 1 Year Certificates"
label var shaw_tot_CTE        "Share of Awards in CTE"
label var shaw_tot_CON        "Share of Awards in Construction/Manufacturing"
label var shaw_tot_HEA        "Share of Awards in Health"
label var shaw_tot_IT         "Share of Awards in Information Technology"
label var shaw_tot_PUB        "Share of Awards in Public/Protective Services"
 
#delimit cr
*preserve
rename cz_instcount cz_insts
global eds "cz_insts_47 cz_insts_69 tef_tot_47 tef_tot_69 noinsts no_fouryear    aw_aa aw_1t4 aw_lt1y shaw_tot_CTE shaw_tot_CON shaw_tot_HEA  shaw_tot_IT shaw_tot_PUB"
 
eststo a1: estpost tabstat total_ext total_ext_share sh_1 sh_5 urate total_pop workage $eds , s(mean sd) col(stat)
*eststo a2: estpost tabstat total_ext total_ext_share sh_1 sh_5 urate total_pop workage $eds if year<2007, s(mean sd) col(stat)
*eststo a3: estpost tabstat total_ext total_ext_share sh_1 sh_5 urate total_pop workage $eds if year>2006, s(mean sd) col(stat)
esttab using "${tabdir}/lev/table_sumstats.tex", main(mean a3) aux(sd a3) `theusual' prehead(" ") prefoot(" ") posthead(" ") postfoot(" ")
fff
	