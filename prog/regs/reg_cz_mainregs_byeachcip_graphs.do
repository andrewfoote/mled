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
set scheme s1color



use $datdir/cipcode_forgraphs.dta, clear 

foreach suff in 1t4 aa lt1y {
	gen b_tot_`suff' = (lay_b1`suff'+lay_b2`suff'+lay_b3`suff') 
	gen se_tot_`suff'=(lay_se1`suff'^2+lay_se2`suff'^2+lay_se3`suff'^2)^(1/2)
	gen sig_tot_`suff'=abs(b_tot_`suff'/se_tot_`suff')>1.96
}

rename (bAAAS bCertSmall seAAAS seCertSmall)(return_aa return_lt1y se_aa se_lt1y)
gen return_1t4 = (bCert1830 + bCert3060)/2
gen se_1t4=(bCert1830^2 + bCert3060^2)/2
foreach g in aa 1t4 lt1y{
	gen sig_ret_`g'=abs(return_`g'/se_`g')>1.96
	}


keep return_* b_tot* ns* top4 sig*
drop nsTOT

local x = 1 
foreach suff in 1t4 aa lt1y {
	rename return_`suff' return_`x'
	rename b_tot_`suff' b_tot_`x'
	rename sig_ret_`suff' sig_ret_`x'
	rename sig_tot_`suff' sig_tot_`x'
	rename ns`suff' ns`x'
	local x = `x' + 1 
}

reshape long return_ b_tot_ ns sig_tot_ sig_ret_, i(top4) j(newcat)

gen category = "1-4 Yr" if newcat == 1
	replace category = "AA" if newcat == 2
	replace category = "Less Than 1yr" if newcat == 3
	
	
keep if b_tot_ != 0 & return_ > -3 


*All
twoway (scatter b_tot return_ [weight = ns], msymbol(circle_hollow) ) (lfit b_tot return_ [weight=ns], lcolor(red)), legend(off) ytitle("Mass Layoff response (3-year cumulative)") xtitle("Returns to Program (log earnings)")
	graph export "$figdir/scatter_bycip_all.eps", replace
	reg b_tot return_[weight=ns], 
*Significant Returns
twoway (scatter b_tot return_ [weight = ns] if sig_ret==1, msymbol(circle_hollow) ) (lfit b_tot return_ [weight=ns]  if sig_ret==1, lcolor(red)), legend(off) ytitle("Mass Layoff response (3-year cumulative)") xtitle("Returns to Program (log earnings)")
	graph export "$figdir/scatter_bycip_sigret.eps", replace
	reg b_tot return_[weight=ns]  if sig_ret==1, 
*Significant Coeff
twoway (scatter b_tot return_ [weight = ns] if sig_tot==1, msymbol(circle_hollow) ) (lfit b_tot return_ [weight=ns]  if sig_tot==1, lcolor(red)), legend(off) ytitle("Mass Layoff response (3-year cumulative)") xtitle("Returns to Program (log earnings)")
	graph export "$figdir/scatter_bycip_sigtot.eps", replace
	reg b_tot return_[weight=ns]  if sig_tot==1, 
*Significant Coeff AND significant return
twoway (scatter b_tot return_ [weight = ns] if sig_tot==1 & sig_ret==1, msymbol(circle_hollow) ) (lfit b_tot return_ [weight=ns]  if sig_tot==1 & sig_ret==1, lcolor(red)), legend(off) ytitle("Mass Layoff response (3-year cumulative)") xtitle("Returns to Program (log earnings)")
	graph export "$figdir/scatter_bycip_sigrettot.eps", replace
	reg b_tot return_[weight=ns]  if sig_tot==1 & sig_ret==1, 


*

#delimit;
twoway (scatter b_tot return_  if newcat==1, msymbol(circle_hollow)  )
		(scatter b_tot return_  if newcat==2, msymbol(circle_hollow) )
		(scatter b_tot return_  if newcat==3, msymbol(circle_hollow) )
		 (lfit b_tot return_ [weight=ns], lcolor(red)),  ytitle("Mass Layoff response (3-year cumulative)") xtitle("Returns to Program (log earnings)")
		 legend(order(2 "AA/AS" 1 "1-4 Year"  3 "<1 Year") col(3));
	graph export "$figdir/scatter_bycip_all_bytype.eps", replace;
#delimit;
twoway (scatter b_tot return_  if newcat==1 & sig_ret==1, msymbol(circle_hollow)  )
		(scatter b_tot return_  if newcat==2 & sig_ret==1, msymbol(circle_hollow) )
		(scatter b_tot return_  if newcat==3  & sig_ret==1, msymbol(circle_hollow) )
		 (lfit b_tot return_ if   sig_ret==1 [weight=ns], lcolor(red)),  ytitle("Mass Layoff response (3-year cumulative)") xtitle("Returns to Program (log earnings)")
		 legend(order(2 "AA/AS" 1 "1-4 Year"  3 "<1 Year") col(3));
	graph export "$figdir/scatter_bycip_sigret_bytype.eps", replace;






