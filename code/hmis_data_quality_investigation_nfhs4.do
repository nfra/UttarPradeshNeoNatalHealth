* Name: hmis_data_quality_investigation_nfhs4
* Written by: Nathan Franz
* Description: An investigation into the quality of HMIS data -- NFHS-4 portion
* Last edited: 3/23/2020

use ".\UttarPradeshNeoNatalHealth\data\nfhs4_files\IABR74FL.DTA""

* Keep only births in period of interest: Apr 2014 - Mar 2015
* In CMCs, this is 1372 - 1383
keep if b3 >=1372 & b3<=1383

generate overall_wgt = v005/1000000
label variable overall_wgt "women's sample weight, decimalized"

generate state_wgt = sv005/1000000
label variable state_wgt "state women's sample weight, decimalized"

* This table looks at the per-state means of state sample weight, which I would 
* expect to be 1.
table v024, c(mean state_wgt)

* Note that the numbers associated with the places came from the accompanying DO file
gen place_of_dlv = "home" if inlist(m15, 10, 11, 12, 13)
replace place_of_dlv = "public" if inlist(m15, 20, 21, 22, 23, 24, 25, 26, 27)
replace place_of_dlv = "private" if inlist(m15, 30, 31, 32, 33)
replace place_of_dlv = "other" if m15 == 96

label variable place_of_dlv "place of delivery; fewer, more-general categories"

* This table gives per-state percentage of deliveries in each place, using state weights
tab v024 place_of_dlv [iweight=state_wgt], row nofreq

* This table gives in the second column percentage of deliveries in each place, using overall weights 
tab place_of_dlv [iweight=overall_wgt]

* This table looks at the per-state means of state sample weight for those 
* observations with place of delivery specified to see if weights still work
keep if m15 != .
table v024, c(mean state_wgt)