/*******************************************************************************************
Program Name: build_ipeds_aws
REad in IPEDS data on awards by college.
Author:MZG
Project:
**********/

global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global figdir "$rootdir/out/fig"
global tabdir "$rootdir/out/tab"
set maxvar 32000





*Create Crosswalks
global irawdir "/home/research/cavoced/tasks/raw"
global idatdir "/home/research/cavoced/tasks/data"

***************************************************************
*Crosswalks:
		*84-89: crosswalk 85-90, then 90-00
		*90-02: crosswalk 90-00
		*10-on: crosswalk 10-00
		*Crosswalks are from NCES, available here http://nces.ed.gov/ipeds/cipcode/resources.aspx?y=55
		*Crosswalks read in in dofile build_TOP_SOC_crosswalk
***************************************************************
	use $idatdir/TOP_ONET_data, clear
		keep cip2000 vocflag
		replace cip=subinstr(cip,"*","",.)
		destring cip, replace
		replace cip=cip/10000
		tostring cip, replace
		duplicates drop
		gen asdf=vocfl=="*"
		bysort cip: egen voced_flag=total(asdf)
			replace voced_flag=voced_flag>0
			keep cip voced_flag
			duplicates drop
		tempfile tempcipv
		save `tempcipv'
	*in all crosswalks, make the cip code of the form "NN.NNNN".
		use $irawdir/cip85cip90, clear
			replace cip85=cip85+"." if strpos(cip85,".")==0
			replace cip90=cip90+"." if strpos(cip90,".")==0
			*first add 0's to the end
			forvalues y=1/8{
			replace cip85=cip85+"0" if length(substr(cip85, strpos(cip85,"."),.))<5
			replace cip90=cip90+"0" if length(substr(cip90, strpos(cip90,"."),.))<5
			}
			*Now add 0's to the front
			replace cip85="0"+cip85 if length(cip85)<7
			replace cip85="0"+cip85 if length(cip85)<7
			replace cip90="0"+cip90 if length(cip90)<7
			replace cip90="0"+cip90 if length(cip90)<7
			tempfile tempx8590
			save `tempx8590'

		use $irawdir/cip90cip00, clear
			replace cip90=cip90+"." if strpos(cip90,".")==0
			replace cip00=cip00+"." if strpos(cip00,".")==0
			*first add 0's to the end
			forvalues y=1/8{
			replace cip00=cip00+"0" if length(substr(cip00, strpos(cip00,"."),.))<5
			replace cip90=cip90+"0" if length(substr(cip90, strpos(cip90,"."),.))<5
			}
			*Now add 0's to the front
			replace cip00="0"+cip00 if length(cip00)<7
			replace cip00="0"+cip00 if length(cip00)<7
			replace cip90="0"+cip90 if length(cip90)<7
			replace cip90="0"+cip90 if length(cip90)<7
			tempfile tempx9000
			save `tempx9000'
			
		use $irawdir/cip00cip10, clear
			replace cip00=cip00+"." if strpos(cip00,".")==0
			replace cip10=cip10+"." if strpos(cip10,".")==0
			*first add 0's to the end
			forvalues y=1/8{
			replace cip00=cip00+"0" if length(substr(cip00, strpos(cip00,"."),.))<5
			replace cip10=cip10+"0" if length(substr(cip10, strpos(cip10,"."),.))<5
			}
			*Now add 0's to the front
			replace cip00="0"+cip00 if length(cip00)<7
			replace cip00="0"+cip00 if length(cip00)<7
			replace cip10="0"+cip10 if length(cip10)<7
			replace cip10="0"+cip10 if length(cip10)<7
			tempfile tempx0010
			save `tempx0010'			
*********************************************************
	*Now merge on
		cd /home/research/cavoced/tasks/data
		 use ipeds_occcip_8413, clear
	
	preserve
	keep if year>1900 & year<1992
	gen cip85=string(cipcode)
		*get it nice and formatted
		replace cip85="0"+cip85 if length(cip85)==5
		destring cip85, replace
		replace cip85=cip85/10000
		tostring cip85, replace
			replace cip85=cip85+"0" if length(substr(cip85, strpos(cip85,"."),.))<5
			forvalues y=1/8{
			replace cip85=cip85+"0" if length(substr(cip85, strpos(cip85,"."),.))<5
			}
			replace cip85="0"+cip85 if length(cip85)<7
			replace cip85="0"+cip85 if length(cip85)<7
		merge m:1 cip85 using `tempx8590'
		replace cip90=cip85 if _merge==1	
			rename _merge mm
		merge m:1 cip90 using `tempx9000'
		
		keep if _merge==3
		drop _merge
		tempfile temp85
		
		save `temp85'
	restore, preserve
	keep if year>1991 & year<2003
	gen cip90=string(cipcode)
		*get it nice and formatted
		replace cip90="0"+cip90 if length(cip90)==5
		destring cip90, replace
		replace cip90=cip90/10000
		tostring cip90, replace
			replace cip90=cip90+"0" if length(substr(cip90, strpos(cip90,"."),.))<5
			forvalues y=1/8{
			replace cip90=cip90+"0" if length(substr(cip90, strpos(cip90,"."),.))<5
			}
			replace cip90="0"+cip90 if length(cip90)<7
			replace cip90="0"+cip90 if length(cip90)<7
		merge m:1 cip90 using `tempx9000'
		keep if _merge==3
		tempfile temp90
		save `temp90'
		restore, preserve
		
	keep if year>2009
	gen cip10=string(cipcode)
		*get it nice and formatted
		replace cip10="0"+cip10 if length(cip10)==5
		destring cip10, replace
		replace cip10=cip10/10000
		tostring cip10, replace
			replace cip10=cip10+"." if strpos(cip10,".")==0
			forvalues y=1/8{
			replace cip10=cip10+"0" if length(substr(cip10, strpos(cip10,"."),.))<5
			}
			replace cip10="0"+cip10 if length(cip10)<7
			replace cip10="0"+cip10 if length(cip10)<7
		merge m:1 cip10 using `tempx0010'
		keep if _merge==3
		tempfile temp10
		save `temp10'
		restore
	keep if year>2002 & year<2010
		*get it nice and formatted
		drop if cipc==99
		gen cip00=string(cipcode)
		replace cip00="0"+cip00 if length(cip00)==5
		destring cip00, replace
		replace cip00=cip00/10000
		tostring cip00, replace
			replace cip00=cip00+"." if strpos(cip00,".")==0
			forvalues y=1/5{
			replace cip00=cip00+"0" if length(substr(cip00, strpos(cip00,"."),.))<5
			}
			replace cip00="0"+cip00 if length(cip00)<7
			replace cip00="0"+cip00 if length(cip00)<7
		drop if cip00==".0099"
	*append them
		append using `temp10'
		append using `temp90'
		append using `temp85'
		tab year
		drop _merge
	*NOTE: In some years NEW, unmatched CIP codes are added. In these cases, summ the new CIP codes to their 4-digit CIP codes
		*Find unmatched cip codes
		gen in90=year>1991 & year<2003
		*make it the "general version"
		bysort cip00 : egen totin=mean(in90)
			replace totin=totin>0
			tab year totin
			replace cip00=substr(cip00,1,5)+"00" if totin==0
		*general version v2
		bysort cip00: egen toti2=mean(in90)
			replace toti2=toti2>0
			tab year toti2
			replace cip00=substr(cip00,1,5)+"01" if toti2==0
		*MOST general version
		bysort cip00: egen toti3=mean(in90)
			replace toti3=toti3>0
			tab year toti3
			replace cip00=substr(cip00,1,3)+"0000" if toti3==0		
		bysort cip00: egen toti4=mean(in90)
			replace toti4=toti4>0
			tab year toti4
		keep if toti4==1

*Merge on Voc-Ed flag from CCCCO
	rename cip00 cip2000
	merge m:1 cip2000 using `tempcipv', gen(mmm)
	
	
	save $datdir/ipeds_awards_precollapse, replace
	
*Content Variables
	gen cip2=substr(cip2000,1,2)
	foreach g of varlist aw_*{
		gen `g'_CTE=`g'*(voced_flag==1)
		gen `g'_IT=`g'*(cip2=="10"|cip2=="11")
		gen `g'_CON=`g'*(inlist(cip2,"15","46","47","48","49")==1)
		gen `g'_PUB=`g'*(inlist(cip2,"43","44")==1)
		gen `g'_HEA=`g'*(cip2=="51")
		gen `g'_BUS=`g'*(cip2=="52")
		gen `g'_FAM=`g'*(cip2=="19")
		gen `g'_EDU=`g'*(cip2=="13")
		gen `g'_PER=`g'*(cip2=="12")
		}
		
	collapse(sum) aw_*, by(unitid year)
		save $datdir/ipeds_awards, replace


dddd







