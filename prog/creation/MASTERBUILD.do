/********************* 
This dofile runs all the relevant
dofiles for creating the dataset in order
****************************/

global dodir /home/research/masslayoff/education/prog/creation

/* creates variables at the CTY/CZ level */
do "$dodir/build_ipeds_ctycz.do" 


/* builds mass layoff data */
do "$dodir/build_masslayoffs.do"

/*merges the data together */
do "$dodir/educ_layoff_merge.do" 

/*done */