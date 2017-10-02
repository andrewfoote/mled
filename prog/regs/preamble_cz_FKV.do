#delimit ; 

drop if year>2011;

foreach g in tot aa ba lt1y 1t4{;
gen aw_`g'_TOT=aw_`g';
gen aw_`g'_TOT_47=aw_`g'_47;
gen aw_`g'_TOT_69=aw_`g'_69;
gen aw_`g'_TOT_4769=aw_`g'_4769;
};

foreach out of varlist  aw_* ffe_* tef_*{ ;
	qui gen ln_`out'=ln(`out') ;
	*qui replace ln_`out'=0 if ln_`out'==. ;
} ;

	levelsof czone, local(czones) ;
	gen t=year-1996  ;


	foreach j in `czones' { ;
		gen cztrend`j'=(czone == `j' )*t ;
	} ;

gen log_czlayoff = log(cz_total_ext)  ;

replace log_czlayoff = 0 if cz_total_ext == 0  ;


	