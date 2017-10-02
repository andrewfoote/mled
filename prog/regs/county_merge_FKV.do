#delimit ; 

foreach outcome of varlist total_ext aw_* tef* ffe* { ;
	bys czone year: egen cz_`outcome' = sum(`outcome') ;
}  ;

bys czone year: egen cz_total_pop = sum(total_pop) ;


collapse (first) cz_*, by(czone year) ; /* this creates a cz-year dataset of enrollment, awards, etc */

foreach outcome of varlist cz_total_pop cz_aw_* cz_tef_* cz_ffe_*{  ;
	local newname = subinstr("`outcome'","cz_","",1)  ; 
	rename `outcome' `newname' ;
}  ;

sort czone year ;


