/*******************
This makes graphs of
distribution of results
*******************/
set scheme s1color
local figbacks "plotregion(fcolor(white)) graphregion(fcolor(white))  bgcolor(white)"
local theusual "nomtitles nonotes noobs nonumbers nolines nogaps label prehead(" ") posthead(" ") prefoot(" ") postfoot(" ")"

global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global prodir "$rootdir/prog"
global figdir "$rootdir/fig"
global tabdir "$rootdir/tab"
global logdir "$rootdir/log" 
#delimit ; 
use $datdir/outcomes_FKVtest2.dta, clear ; 

/**************************************
Figure out which outcome to estimate this for;
************************************/
local outcome "ffe_tot" ;
keep if outcome == "`outcome'" ;

sort iteration;
local true_est1 = beta_lag1[1] ;
local true_est2 = beta_lag2[1] ;
local true_est3 = beta_lag3[1] ;
di "`true_est1'";


#delimit ; 

foreach lag in 1 2 3 { ; 
twoway /*(hist beta_lag`lag' if iteration!=0)*/
	(kdensity beta_lag`lag' if iteration!=0)
	/*(scatteri  200 `true_est'  `true_est' 200, recast(line) lcolor(red) lwidth(thick) lpattern(dash))*/,
       xtitle("Coefficient")
       ytitle("Density")
	   `figbacks'
       xline(`true_est`lag'',lstyle(foreground) lpattern(dash) lcolor(red))
       legend(off)
       ;

graph export "$tabdir/lag`lag'_`outcome'_dist.eps", replace ;
} ;

foreach lag in 1 2 3 { ; 
preserve ; 

sum tstat_lag`lag' if iteration == 0 ; 
di r(mean);
local true_est`lag' = r(mean); 
keep if iteration !=0 ;
di `true_est`lag'';
*sort tstat_1990 ;

local lower_bound`lag' = tstat_lag`lag'[25] ;
local upper_bound`lag' = tstat_lag`lag'[975];
restore ; 

} ;

foreach lag in 1 2 3 { ;
twoway 
	(kdensity tstat_lag`lag' if iteration!=0),
     xline(`true_est`lag'', lpattern(solid) lcolor(blue))
	      xline(`lower_bound`lag'', lpattern(solid) lcolor(red))
		       xline(`upper_bound`lag'', lpattern(solid) lcolor(red))
       xtitle("T-statistic")
       ytitle("Density")     
       
       legend(off)
       ;

graph export "$tabdir/tdist_lag_`lag'.eps", replace ;

} ;
