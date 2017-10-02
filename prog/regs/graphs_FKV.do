/*******************
This makes graphs of
distribution of results
*******************/
global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global prodir "$rootdir/prog"
global figdir "$rootdir/fig"
global tabdir "$rootdir/tab"
global logdir "$rootdir/log" 
#delimit ; 
use $datdir/outcomes_FKVtest.dta, clear ; 

/**************************************
Figure out which outcome to estimate this for
************************************/
local outcome "ffe_tot" ;
keep if outcome = "`outcome'" ;

sort iteration
local true_est1 = beta1[1] 
local true_est2 = beta2[1] 
local true_est3 = beta3[1] 
di "`true_est1'"


#delimit ; 

foreach lag in 1 2 3 { ; 
twoway (hist beta`lag' if iteration!=0)
	(kdensity beta`lag' if iteration!=0)
	(scatteri 0 `true_est' 15 `true_est', recast(line) lcolor(red) lwidth(thick) lpattern(dash)),
       saving("$graphdir/lag`lgag'_`outcome'_dist.gph", replace)
       xtitle("Coefficient")
       ytitle("Density")
      /* xline(`true_est',lstyle(foreground) lpattern(dash) lcolor(red))*/
       title("Distribution of Estimated Effect for Lag `lag', Outcome `outcome'")
       legend(off)
       ;

graph export "$outgraph/lag`lag'_`outcome'_dist.png", replace ;
} ;

preserve ; 
foreach lag in 1 2 3 { ; 
sum tstat`lag' if iteration == 0 ; 
local true_est`lag' = r(mean); 
keep if iteration !=0 ;

sort tstat_1990 ;

local lower_bound`lag' = tstat`lag'[25] ;
local upper_bound`lag' = tstat`lag'[975];

di "**************************";
di "RESULTS FROM BOOTSTRAP";
di "ESTIMATED T-STAT FOR LAG `lag':" %6.4f `true_est`lag'' ;
di "CONFIDENCE INTERVAL FOR LAG `lag':"
di "[" %6.4f `lower_bound`lag'' ", " %6.4f `upper_bound`lag'' "]" ;

} ;


restore ; 

foreach lag in 1 2 3 { ;
twoway (hist tstat`lag' if iteration!=0)
	(kdensity tstat`lag' if iteration!=0)
	(scatteri 0 `true_est`lag'' 2 `true_est`lag'', recast(line) lcolor(blue) lwidth(thick) lpattern(dash))
	(scatteri 0 `lower_bound`lag'' 2 `lower_bound', recast(line) lcolor(red) lwidth(thick) lpattern(dash))
	(scatteri 0 `upper_bound`lag'' 2 `upper_bound`lag'', recast(line) lcolor(red) lwidth(thick) lpattern(dash)),
       saving("$graphdir/tdist_lag_`lag'.gph", replace)
       xtitle("T-statstic")
       ytitle("Density")     
       title("Distribution of T-Statistics for Lag `lag'")
       legend(off)
       ;

graph export "$outgraph/tdist_lag_`lag'.png", replace ;

} ;
