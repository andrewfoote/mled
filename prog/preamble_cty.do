drop if year>2011


foreach g in tot aa ba lt1y 1t4{
gen aw_`g'_TOT=aw_`g'
gen aw_`g'_TOT_47=aw_`g'_47
gen aw_`g'_TOT_69=aw_`g'_69
}

*create logs
#delimit;
foreach out of varlist  aw_* ffe_* tef_*{ ;
	qui gen ln_`out'=ln(`out') ;
	*qui replace ln_`out'=0 if ln_`out'==. ;
} ;

*Create shares for awards variables ;
foreach ty in tot lt1y aa 1t4 ba{ ;
	foreach v of varlist aw_`ty'_*{ ;
	 qui	gen sh`v'=`v'/aw_`ty' ;
	} ;
} ;		

gen log_ctylayoff = log(total_ext)  ;
gen log_ctylayoff_nz = log(total_ext)  ;
	replace log_ctylayoff = 0 if total_ext == 0  ;
	
label variable log_ctylayoff  "Log(Layoff Count)"   ;
*replace log_ctylayoff=log_ctylayoff/100;
