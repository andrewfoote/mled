global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global prodir "$rootdir/prog"
global figdir "$rootdir/fig"
global tabdir "$rootdir/tab"
global logdir "$rootdir/log" 
global graphdir "/home/research/masslayoff/education/fig"
local figbacks "plotregion(fcolor(white)) graphregion(fcolor(white) lwidth(large)) bgcolor(white)"
set scheme s1color



*Create N's for each program in the first year.
use $datdir/CZ_ED_LAYOFF, clear
do $prodir/preamble_cz.do
collapse(sum) aw_* if year==1995
	keep *47
preserve
foreach g in TOT CTE CON HEA IT PUB FAM {
	keep *`g'_47
		foreach boop in tot aa 1t4 lt1y{
			rename aw_`boop' t`boop'
			}
	gen top="`g'"
	tempfile temp`g'
	save `temp`g''
	clear
	restore, preserve
	}
	restore
	use `tempTOT', clear
		foreach g in  CTE CON HEA IT PUB FAM {
			append using `temp`g''
			}
			gen category=.
			replace category=1 if top=="CON"
			replace category=2 if top=="HEA" 
			replace category=3 if top=="IT"  
			replace category=4 if top=="PUB" 
			replace category=5 if top=="FAM" 
			keep if category!=.
			tempfile tempns
			save `tempns'
			
			
			

#delimit ;
insheet using "$rawdir/mleffects.csv", clear; 
des ;
list in 1/30 ;
gen category = .  ;
	replace category = 1 if _n > 9 & _n <15 ;
	replace category = 2 if _n > 16 & _n < 22 ;
	replace category = 3 if _n > 23 & _n < 29 ;
	replace category = 4 if _n > 30 & _n < 36 ; 
	replace category = 5 if _n > 37 & _n < 43 ;
	
destring v4, gen(deg1) ignore("?") force;
destring v5, gen(deg2) ignore("?") force;
destring v6, gen(deg3) ignore("?") force;

/*
deg1 - aa/as
deg2 - 1-4 yr cert
deg3 - <1 yr cert
*/
des ;

drop if category == . ;
drop v* ;
list category deg* ;

forvalues i = 1/3 { ;
	bys category: egen tot_deg`i' = sum(deg`i') ;
} ;

collapse (first) tot_deg*, by(category) ;

reshape long tot_deg, i(category) j(degreelevel) ;
rename tot_deg mleffect ; 
list ;

tempfile mleffects;
save `mleffects', replace;

insheet using "$rawdir/edreturns.csv", clear;

gen category 	 = 1 if field == "Engineering/Industrial" ;
replace category = 2 if field == "Health" ;
replace category = 3 if field == "Information Technology"  ;
replace category = 4 if field == "Public/Protective Services" ;
replace category = 5 if field == "Family/Consumer Sciences" ;
list ;
gen degreelevel = 1 if degree == "AA/AS" ;
	replace degreelevel = 2 if degree == "30-60" | degree == "18-30" ;
	replace degreelevel = 3 if degree == "6-18" ;
	
bys category degreelevel: egen returns_all = mean(all); 
bys category degreelevel: egen returns_above30 = mean(above30); 
bys category degreelevel: egen returns_all_trends = mean(all_trends) ;
bys category degreelevel: egen returns_older30_trends = mean(older30_trends) ;


collapse (first) returns_*, by(category degreelevel) ;

list ;
keep if category != .   & degreelevel != . ;

tab category degreelevel; 
keep category degreelevel returns_above30 returns_all returns_all_trends returns_older30_trends ;
sort category degreelevel; 

tempfile edreturns; 
save `edreturns', replace ; 

use `mleffects', clear;

sort category degreelevel ;
merge 1:1 category degreelevel using `edreturns' ;

tab _merge ;
drop _merge ; 

	merge m:1 category using `tempns';
		gen numin1995=.;
			replace numin1995=taa if degreelevel==1;
			replace numin1995=t1t4 if degreelevel==2;

corr returns_all_trends mleffect [weight=numin];
local rho : di %4.3f r(rho);
twoway (scatter mleffect returns_all_trends  [weight=numin], msymbol(circle_hollow))||(lfit mleffect returns_all_trends  [weight=numin]),
	ytitle("Mass Layoff Response (3-year cumulative)") xtitle("Returns to Program (log earnings)") `figbacks' ylab(, nogrid)
	legend(off);
graph export "$graphdir/scatter_allwithcor.eps", replace ; 
dddd;
twoway (scatter mleffect returns_all_trends ),
	ytitle("ML Response") xtitle("Returns to Program")  `figbacks'
	legend(off) 
	title("Scatterplot of ML Response and Ed Returns");
	
graph export "$graphdir/scatter_all.eps", replace ; 
	
twoway (scatter mleffect returns_older30_trends ),
	ytitle("ML Response") xtitle("Returns to Program") 
	legend(off)   `figbacks'
	title("Scatterplot of ML Response and Ed Returns for ages 30+");
	
graph export "$graphdir/scatter_30p.eps", replace ; 

twoway (scatter  mleffect returns_all_trends )
		(lfit mleffect returns_all_trends ),
	ytitle("ML Response") xtitle("Returns to Program") 
	legend(off)   `figbacks'
	title("Scatterplot of ML Response and Ed Returns");
	
graph export "$graphdir/scatter_all_lfit.eps", replace ; 
	
twoway (scatter mleffect returns_older30_trends )
		(lfit mleffect returns_older30_trends ),
	ytitle("ML Response") xtitle("Returns to Program") 
	legend(off)   `figbacks'
	title("Scatterplot of ML Response and Ed Returns for ages 30+");
	
graph export "$graphdir/scatter_30p_lfit.eps", replace ; 	
	
export excel using "$rawdir/scatterplots.xls", replace ;

