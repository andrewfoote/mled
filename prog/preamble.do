drop if unitid==.
drop if year>2011
xtset unitid year
gen total_ext_shareLF_lf = total_ext/L.lau_LF 
gen cz_total_ext_shareLF_lf = cz_total_ext/L.cz_lau_LF 

*broader age categories for fulltime and parttime enrollment
gen ft_1829 =ftall04+ftall05+ftall06+ftall08
gen ft_3039 =ftall09+ftall10
gen ft_40p  =ftall11+ftall12+ftall13

gen pt_1829 =ptall04+ptall05+ptall06+ptall08
gen pt_3039 =ptall09+ptall10
gen pt_40p  =ptall11+ptall12+ptall13

*create logs
#delimit;
global yvarlist 
		admitcount admssn admssnm admssnw any_aid_num any_aid_pct applcn applcnm
		applcnw applicantcount appliedaid01 appliedaid02 associatedegrees bachelordegrees enrlm enrlt
		enrlw enrollftcount enrollptcount ft_1829 ft_3039 ft_40p  pt_1829 pt_3039 pt_40p  
		fte_count grant01
		grant02 grant03 grant04 grant05 grant06 grant07 grants01 masterdegrees
		 totalawards totalcertificates totalcompletions totaldegrees ;
		#delimit cr
		foreach out of varlist $yvarlist aw_*{
			gen ln_`out'=ln(`out')
			replace ln_`out'=0 if ln_`out'==.
			}
*Create shares for awards variables
foreach ty in tot lt1y aa 1t4 ba{
	foreach v of varlist aw_`ty'_*{
		gen sh`v'=`v'/aw_`ty'
		}
		}
		
tab year, gen(yearfe)
gen lnlay=ln(total_ext_shareLF)
gen czlnlay=ln(cz_total_ext_shareLF)
qui tab fips, gen(fipsfe)

label variable lnlay "Log(Layoff Share)"
label variable czlnlay "Log(CZ Layoff Share)" 

gen log_ctylayoff = log(total_ext) 
	replace log_ctylayoff = 0 if total_ext == 0 
gen log_czlayoff = log(cz_total_ext) 
	replace log_czlayoff = 0 if cz_total_ext == 0 

label variable log_ctylayoff  "Log(Layoff Count)" 
label variable log_czlayoff "Log(CZ Layoff Count)"
	

