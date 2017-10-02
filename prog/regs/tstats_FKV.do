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
use $datdir/outcomes_FKVtest2.dta, clear ; 
des;
/**************************************
Figure out which outcome to estimate this for
************************************/

foreach outcome in ffe_tot tef_tot { ;
use $datdir/outcomes_FKVtest2.dta, clear ; 

	
	keep if outcome == "`outcome'" ;
	

	/* getting the outputs */
	foreach lag in 1 2 3 { ;
	preserve ;
		qui sum beta_lag`lag' if iteration == 0 ;
		local true_est`lag' = r(mean) ;
		qui sum tstat_lag`lag' if iteration == 0 ; 
		local true_tstat`lag' = r(mean); 
		qui keep if iteration !=0 ;

		sort tstat_lag`lag' ;

		local lower_bound`lag' = tstat_lag`lag'[25] ;
		local upper_bound`lag' = tstat_lag`lag'[975];

		di "**************************";
		di "RESULTS FROM BOOTSTRAP FOR `outcome'";
		di "TRUE COEFF ESTIMATE: " %6.4f `true_est`lag'' ;
		di "ESTIMATED T-STAT FOR LAG `lag':" %6.4f `true_tstat`lag'' ;
		di "CONFIDENCE INTERVAL FOR LAG `lag':" ;
		di "[" %6.4f `lower_bound`lag'' ", " %6.4f `upper_bound`lag'' "]" ;
		di "************************" ;
	restore ;
	} ;


	 
/*skip the graphs for now */
/*
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
	*/
} ;
