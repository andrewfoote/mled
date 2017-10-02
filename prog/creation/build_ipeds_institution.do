/*******************************************************************************************
Program Name: build_ipeds
REad in IPEDS data on completions by college.
Author:MZG
Project:
**********/

global rootdir "/home/research/masslayoff/education"
global datdir "$rootdir/data"
global rawdir "$rootdir/raw"
global figdir "$rootdir/out/fig"
global tabdir "$rootdir/out/tab"
set maxvar 32000



*************************************************************
*Read in IPEDS insitituaional directories
**************************************************************
/*foreach year in 1984 1985 {
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file IC`year'
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'.do
cd ../../../data
save ipedsd`year', replace
}
foreach year in 1986 1987 1988 1989 1992 1993 1994 {
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file IC`year'_A
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'_a.do
cd ../../../data
save ipedsd`year', replace
}

foreach year in 90 {
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file IC`year'HD
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'hd.do
cd ../../../data
save ipedsd19`year', replace
}
foreach year in 1991 {
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file IC`year'_hdr
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'_hdr.do
cd ../../../data
save ipedsd`year', replace
}

foreach year in 1994  {
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file IC`year'_A
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'_a.do
cd ../../../data
save ipedsd`year', replace
}
foreach year in   95 96 {
local year2=`year'+1
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file ic`year'`year2'_A
local path "`file'"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'`year2'_a.do
cd ../../../data
save ipedsd19`year', replace
}
foreach year in   97  {
local year2=`year'+1
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file ic`year'`year2'_HDR
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'`year2'_hdr.do
cd ../../../data
save ipedsd19`year', replace
}
foreach year in   98  {
local year2=`year'+1
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file IC`year'hdac
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'hdac.do
cd ../../../data
save ipedsd19`year', replace
}

foreach year in   99  {
local year2=`year'+1
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file IC`year'_HD
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/ic`year'_hd.do
cd ../../../data
save ipedsd19`year', replace
}


foreach year in 2000 2001 {
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file FA`year'HD
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/fa`year'hd.do
cd ../../../data
save ipedsd`year', replace
}
forvalues year=2002/2012 {
cd /home/research/cavoced/tasks/raw/ipeds
clear
local file HD`year'
local path "`file'_Data_Stata"
di "`path'"
cd `path'
do ../`file'_Stata/hd`year'.do
cd ../../../data
save ipedsd`year', replace
}
*/


cd /home/research/cavoced/tasks/data

clear
use ipedsd1984
	gen year=1984
	keep unitid cnty* county* zip stabbr year  city addr 
	tostring zip, replace
	tempfile temp
	save `temp'
use ipedsd1985, clear
	gen year=1985
	keep unitid cnty* county* zip stabbr year   city addr 
	tostring zip, replace
	append using `temp'
	save `temp', replace
use ipedsd1986, clear
	gen year=1986
	keep unitid cnty*  zip stabbr year sector   city addr
	tostring zip, replace
	append using `temp'
	save `temp', replace
use ipedsd1987, clear
	gen year=1987
	keep unitid county*  zip stabbr year sector   city addr
	tostring zip, replace
	append using `temp'
	save `temp', replace
use ipedsd1988, clear
	gen year=1988
	keep unitid county*   zip stabbr year sector   city addr
	tostring zip, replace
	append using `temp'
	save `temp', replace
use ipedsd1989, clear
	gen year=1989
	keep unitid county*   zip stabbr year sector   city addr
	tostring zip, replace
	append using `temp'
	save `temp', replace
use ipedsd1990, clear
	gen year=1990
	keep unitid county*   zip stabbr year sector   city addr
	tostring zip, replace
	append using `temp'
	save `temp', replace
use ipedsd1991, clear
	gen year=1991
	keep unitid county*   zip stabbr year sector   city addr
	tostring zip, replace
	append using `temp'
	save `temp', replace
use ipedsd1992, clear
	gen year=1992
	keep unitid county*   zip stabbr year sector   city addr
	tostring zip, replace
	append using `temp'
	save `temp', replace
use ipedsd1993, clear
	gen year=1993
	keep unitid county*   zip stabbr year sector   city addr
	tostring zip, replace
	append using `temp'
	save `temp', replace


forvalues v=1994/1999{
	append using `temp'
	save `temp', replace
use ipedsd`v', clear
	gen year=`v'
	keep unitid county*   zip stabbr year sector   city addr
	tostring zip, replace

	}

forvalues v =2000/2008{
	append using `temp'
	save `temp', replace
	use ipedsd`v', clear
	gen year=`v'
	keep unitid    zip stabbr year sector   city addr
	tostring zip, replace
	}
forvalues v=2009/2012{
	append using `temp'
	save `temp', replace
use ipedsd`v', clear
	gen year=`v'
	keep unitid county*   zip stabbr year sector   city addr
	tostring zip, replace

	}
	append using `temp'
	cd /home/research/masslayoff/education/data
	egen tagflag=tag(unitid year)
	keep if tagflag==1
	drop tagflag
	save ipeds_instchar, replace
	
	
	