
*** Tier System Evaluation Study *****
*** Impact of Policy on Mobility *****
***** Version 11/1/21 ****************

*** import mobility data from U.S. Bureau of Transportation 
***https://www.bts.gov/daily-travel

import delimited "C:\Users\lnschwar\Documents\CA_tier_study\Data\Trips_by_Distance.csv"

** Keep only California data
keep if level=="County"
keep if statepostalcode=="CA"
 drop level statefips statepostalcode rowid
 
** create date/week variables
gen date2=date(date, "YMD")
gen dow=dow(date2)
gen year=year(date2)
gen week=week(date2)
 
** change week to correspond to week following tier system measures
 replace week=week-1
 
**Create pop staying home variable
rename populationstayingathome pophome
rename populationnotstayingathome popnothome
gen tot_pop=pophome+popnothome
 
** create pop staying home and trips per 100 persons variables
gen populationstayingathome= (pophome/tot_pop)*100
gen populationnotstayingathome = (popnothome/tot_pop)*100
 
foreach var in  numberoftrips  numberoftrips1 numberoftrips13 numberoftrips35 numberoftrips510 numberoftrips1025 numberoftrips2550 numberoftrips50100 numberoftrips100250 numberoftrips250500 numberoftrips500{
 	
	replace `var' = (`var'/tot_pop)*100
 }
 
** take an average by week
collapse (mean) populationstayingathome populationnotstayingathome numberoftrips numberoftrips1 numberoftrips13 numberoftrips35 numberoftrips510 numberoftrips1025 numberoftrips2550 numberoftrips50100 numberoftrips100250 numberoftrips250500 numberoftrips500 tot_pop, by(countyname week year)
 
save "C:\Users\lnschwar\Documents\CA_tier_study\Data\mobility_19_21.dta", replace

** create dataset for 2019 data and rename for merging back in

use  "C:\Users\lnschwar\Documents\CA_tier_study\Data\mobility_19_21.dta"

keep if year==2019

keep week year countyname populationstayingathome populationnotstayingathome numberoftrips  numberoftrips1 numberoftrips13 numberoftrips35 numberoftrips510 numberoftrips1025 numberoftrips2550 numberoftrips50100 numberoftrips100250 numberoftrips250500 numberoftrips500 tot_pop

rename populationstayingathome popstayhome2019
rename populationnotstayingathome popnothome2019
 
 foreach var in  numberoftrips  numberoftrips1 numberoftrips13 numberoftrips35 numberoftrips510 numberoftrips1025 numberoftrips2550 numberoftrips50100 numberoftrips100250 numberoftrips250500 numberoftrips500{
 	
	rename `var' `var'_2019
 }

 save "C:\Users\lnschwar\Documents\CA_tier_study\Code\mob_2019.dta", replace
 
 ** Use mobility dataset with 2020/2021 to merge it back in
 use  "C:\Users\lnschwar\Documents\CA_tier_study\Data\mobility_19_21.dta"
 merge m:1 week  countyname using "C:\Users\lnschwar\Documents\CA_tier_study\Code\mob_2019.dta"

 *take difference with 2019 measures
 gen popstayhomediff= populationstayingathome- popstayhome2019
 gen popnotstayhomediff= populationnotstayingathome - popnothome2019
 
 foreach var in numberoftrips numberoftrips1 numberoftrips13 numberoftrips35 numberoftrips510 numberoftrips1025 numberoftrips2550 numberoftrips50100 numberoftrips100250 numberoftrips250500 numberoftrips500{
 
 gen `var'_diff= ( `var' - `var'_2019 )
 }
 
drop _merge
drop if year==2019

* continue week numbering from 1st week of 2020
replace week=. if year==2021

** change to week from 1st week of 2020
sort countyname year week
bysort countyname: replace week=week[_n-1] + 1 if week==.
sort countyname week

save "C:\Users\lnschwar\Documents\CA_tier_study\Data\mobility_19_21.dta", replace

** use tier system data
 use "C:\Users\lnschwar\Documents\CA_tier_study\Data\Tier_system_data.dta"
 
* merge in mobility data 
 merge 1:1 countyname week using "C:\Users\lnschwar\Documents\CA_tier_study\Data\mobility_19_21.dta"
 
 keep if _merge==3
 save "C:\Users\lnschwar\Documents\CA_tier_study\Data2\Tier_system_mobility_data.dta", replace
 
 ** Preparing County-level demographic dataset
 
 /**
 ** County level data downloaded from: https://www.counties.org/data-and-research
 
 import excel "C:\Users\lnschwar\Documents\CA_tier_study\census_data\datapile_-_headline_datasets_-_current (1).xlsx", sheet("County Profile") firstrow

 save "C:\Users\lnschwar\Documents\CA_tier_study\census_data\County_DataPile.dta"
 
 ** Census data median income (2019 estimates)
 
 import delimited "C:\Users\lnschwar\Documents\CA_tier_study\census_data\ACSDT1Y2019.B19013_data_with_overlays_2021-09-14T144307", varnames(2) 
 
split geographicareaname , parse(,) generate(countyname)
 drop countyname2
 rename countyname1 countyname
 keep estimatemedianhouseholdincomeint countyname
 rename estimatemedianhouseholdincomeint medianincome  
  
split countyname, p("County")
replace countyname1=strtrim(countyname1)
rename countyname1 county

save "C:\Users\lnschwar\Documents\CA_tier_study\census_data\census_CA_Counties_income_2019.dta", replace

 
 *** Recall data
 
 import excel "C:\Users\lnschwar\Documents\CA_tier_study\Data\Recall votes.xlsx", sheet("Feuil1") firstrow clear
 save "C:\Users\lnschwar\Documents\CA_tier_study\Data\Gov_recall_data.dta"
  **/
  
 
 ** importing County level data to overall dataset
 use "C:\Users\lnschwar\Documents\CA_tier_study\Data2\Tier_system_mobility_data.dta"
split countyname, p("County")
replace countyname1=strtrim(countyname1)
rename countyname1 County
drop _merge
merge m:1 County using "C:\Users\lnschwar\Documents\CA_tier_study\census_data\County_DataPile.dta"
keep if _merge==3
 drop _merge
 
 *creating farms per 1000 persons variable
 gen farms_per_1000 = (FarmsAugust2018/ tot_pop )* 1000
  
 **merge census income data 
 merge m:1 countyname using "C:\Users\lnschwar\Documents\CA_tier_study\census_data\census_CA_Counties_income_2019.dta"
  drop _merge
  
 *** importing Recall data
 merge m:1 County using "C:\Users\lnschwar\Documents\CA_tier_study\Data\Gov_recall_data.dta"

gen recall=.
replace recall=1 if Yes>= No
replace recall=0 if Yes< No

 ** change error in one county 
replace Yes=40 if Yes==.4
replace No=60 if No==.6	

** Making tier system changes variables 
* More restrictive tier
 sort countyname week
 
gen tier_2t1=0
bysort countyname: replace tier_2t1=1 if tier_1==1 & tier_2[_n-1]==1

gen tier_3t2=0
bysort countyname: replace tier_3t2=1 if tier_2==1 & tier_3[_n-1]==1

gen tier_4t3=0
bysort countyname: replace tier_4t3=1 if tier_3==1 & tier_4[_n-1]==1
  
gen tier_3t1=0
bysort countyname: replace tier_3t1=1 if tier_1==1 & tier_3[_n-1]==1


gen tier_4t2=0
bysort countyname: replace tier_4t2=1 if tier_2==1 & tier_4[_n-1]==1

gen tier_4t1=0
bysort countyname: replace tier_4t1=1 if tier_1==1 & tier_4[_n-1]==1
  
  
*less restrictive tier
gen tier_1t2=0
bysort countyname: replace tier_1t2=1 if tier_2==1 & tier_1[_n-1]==1

gen tier_2t3=0
bysort countyname: replace tier_2t3=1 if tier_3==1 & tier_2[_n-1]==1

gen tier_3t4=0
bysort countyname: replace tier_3t4=1 if tier_4==1 & tier_3[_n-1]==1

** make measure of tier
gen tier=.

replace tier=1 if tier_1==1
 replace tier=2 if tier_2==1

 replace tier=3 if tier_3==1
 replace tier=4 if tier_4==1

*overall measures 
 gen tier_lower=0
 replace tier_lower=1 if tier_1t2==1| tier_2t3==1|tier_3t4==1
 
 gen tier_higher=0
 replace tier_higher=1 if tier_2t1==1| tier_3t2==1|tier_4t3==1|tier_3t1==1|tier_4t2==1
 
 save "C:\Users\lnschwar\Documents\CA_tier_study\Data\Tier_system_mobility_data.dta", replace
 
 ** preparing for analysis: fixed effect at county level
use "C:\Users\lnschwar\Documents\CA_tier_study\Data\Tier_system_mobility_data.dta"

egen id = group(countyname)
 xtset id
 
**** Analysis
** by different trip lengths
* tier_higher
xtreg popnotstayhomediff tier_higher, fe
regsave tier_higher using res_trips_tier_higher, tstat pval ci  addlabel(trip, "all")

foreach var in numberoftrips_diff numberoftrips1_diff numberoftrips13_diff numberoftrips35_diff numberoftrips510_diff numberoftrips1025_diff numberoftrips2550_diff numberoftrips50100_diff numberoftrips100250_diff numberoftrips250500_diff numberoftrips500_diff{
 
capture  xtreg `var' tier_higher, fe
capture regsave tier_higher using res_trips_tier_higher, tstat pval ci append addlabel(trip, `var')

}

*tier_lower
xtreg popnotstayhomediff tier_lower, fe
regsave tier_lower using res_trips_tier_lower, tstat pval ci  addlabel(trip, "all")

foreach var in numberoftrips_diff numberoftrips1_diff numberoftrips13_diff numberoftrips35_diff numberoftrips510_diff numberoftrips1025_diff numberoftrips2550_diff numberoftrips50100_diff numberoftrips100250_diff numberoftrips250500_diff numberoftrips500_diff{
 
capture  xtreg `var' tier_lower, fe
capture regsave tier_lower using res_trips_tier_lower, tstat pval ci append addlabel(trip, `var')

}
 
 
 ** by county analysis
 * tier_higher
use "C:\Users\lnschwar\Documents\CA_tier_study\Data\Tier_system_mobility_data.dta"

xtreg popnotstayhomediff tier_higher, fe
regsave tier_higher using results_tier_higher, tstat pval ci  addlabel(county, "all")

levelsof county, local(CA_county)

foreach c of local CA_county{
use if county=="`c'" using "C:\Users\lnschwar\Documents\CA_tier_study\Data2\Tier_system_mobility_data.dta"
capture noisily reg popnotstayhomediff tier_higher
capture regsave tier_higher using results_tier_higher, tstat pval ci append addlabel(county, "`c'")
}

*tier_lower
use "C:\Users\lnschwar\Documents\CA_tier_study\Data2\Tier_system_mobility_data.dta"

xtreg popnotstayhomediff tier_lower, fe
regsave tier_lower using results_tier_lower, tstat pval ci  addlabel(county, "all")

levelsof county, local(CA_county)

foreach c of local CA_county{
use if county=="`c'" using "C:\Users\lnschwar\Documents\CA_tier_study\Data2\Tier_system_mobility_data.dta"
capture noisily reg popnotstayhomediff tier_lower
capture regsave tier_lower using results_tier_lower, tstat pval ci append addlabel(county, "`c'")
}
 
 ** Getting tot pop dataset
 
 use "C:\Users\lnschwar\Documents\CA_tier_study\Data\Tier_system_mobility_data.dta"
 collapse (mean) tot_pop, by(county)
 save "C:\Users\lnschwar\Documents\CA_tier_study\Data\tot_pop.dta"
 
 ** Adding demographic information to by county results datasets
 *tier_higher
 
use "C:\Users\lnschwar\Documents\CA_tier_study\Code\results_tier_higher.dta"
drop if county=="all"

merge m:1 county using "C:\Users\lnschwar\Documents\CA_tier_study\Data\Gov_recall_data.dta"
drop _merge
  
merge m:1 county using "C:\Users\lnschwar\Documents\CA_tier_study\Data\tot_pop.dta"
drop _merge
   
merge m:1 county using "C:\Users\lnschwar\Documents\CA_tier_study\census_data\census_CA_Counties_income_2019.dta"
drop _merge
 
merge m:1 county using "C:\Users\lnschwar\Documents\CA_tier_study\census_data\County_DataPile.dta"
gen farmsper1000= (FarmsAugust2018/tot_pop)*1000

export delimited using "C:\Users\lnschwar\Documents\CA_tier_study\Results\Mobility_tier_higher_byCounty.csv", replace
 
* tier_lower

use "C:\Users\lnschwar\Documents\CA_tier_study\Code\results_tier_lower.dta"
drop if county=="all"

 merge m:1 county using "C:\Users\lnschwar\Documents\CA_tier_study\Data\Gov_recall_data.dta"
 drop _merge
  
 merge m:1 county using "C:\Users\lnschwar\Documents\CA_tier_study\Data\tot_pop.dta"
 drop _merge
  
 merge m:1 county using "C:\Users\lnschwar\Documents\CA_tier_study\census_data\census_CA_Counties_income_2019.dta"
 drop _merge
 
 merge m:1 county using "C:\Users\lnschwar\Documents\CA_tier_study\census_data\County_DataPile.dta"
 
gen farmsper1000= (FarmsAugust2018/tot_pop)*1000

export delimited using "C:\Users\lnschwar\Documents\CA_tier_study\Results\Mobility_tier_lower_byCounty.csv", replace
 

*reformatting by trip results dataset
*tier_higher
 use "C:\Users\lnschwar\Documents\CA_tier_study\Code\res_trips_tier_higher.dta" 
 drop if trip=="all"
 
  replace trip=">500" if trip=="numberoftrips500_diff"
  replace trip="250-500" if trip=="numberoftrips250500_diff"
  replace trip="100-250" if trip=="numberoftrips100250_diff"
  replace trip="50-100" if trip=="numberoftrips50100_diff"
  replace trip="25-50" if trip=="numberoftrips2550_diff"
  replace trip="10-25" if trip=="numberoftrips1025_diff"
  replace trip="5-10" if trip=="numberoftrips510_diff"
  replace trip="3-5" if trip=="numberoftrips35_diff"
  replace trip="1-3" if trip=="numberoftrips13_diff"
  replace trip="<1" if trip=="numberoftrips1_diff"
  
  save "C:\Users\lnschwar\Documents\CA_tier_study\Code\res_trips_tier_higher.dta", replace
  
  
 *tier_lower
 use "C:\Users\lnschwar\Documents\CA_tier_study\Code\res_trips_tier_lower.dta" 
 drop if trip=="all"
 
  replace trip=">500" if trip=="numberoftrips500_diff"
  replace trip="250-500" if trip=="numberoftrips250500_diff"
  replace trip="100-250" if trip=="numberoftrips100250_diff"
  replace trip="50-100" if trip=="numberoftrips50100_diff"
  replace trip="25-50" if trip=="numberoftrips2550_diff"
  replace trip="10-25" if trip=="numberoftrips1025_diff"
  replace trip="5-10" if trip=="numberoftrips510_diff"
  replace trip="3-5" if trip=="numberoftrips35_diff"
  replace trip="1-3" if trip=="numberoftrips13_diff"
  replace trip="<1" if trip=="numberoftrips1_diff"
  
  save "C:\Users\lnschwar\Documents\CA_tier_study\Code\res_trips_tier_lower.dta", replace
  
  
 
 *** descriptive statistics (during implementation of tier system)
 
 use "C:\Users\lnschwar\Documents\CA_tier_study\Data\Tier_system_mobility_data.dta"
 drop if tier_1==0 & tier_2==0 & tier_3==0 & tier_4==0
 
 