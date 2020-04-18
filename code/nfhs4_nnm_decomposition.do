* Name: nfhs4_nnm_decomposition_kitagawa
* Written by: Nathan Franz, copied partly from Dean Spears
* Description: Kitagawa decomposition of neo-natal mortality rates between Uttar
*			   Pradesh and the rest of India by mother's height
* Last edited: 4/13/2020

version 12.1  // Dean wrote this in Stata version 12.1

global directory "C:\Users\Nathan\Documents\RA Research\Uttar Pradesh Neo-natal Health\UttarPradeshNeoNatalHealth\"

clear all
set more off  // so the do file keeps rolling
set seed 8062011  // so that any randomized results, like bootstraps, are replicable

cd "$directory"

capture log close  // in case you already have a log going
log using isilog, replace smcl

use ".\data\nfhs4_files\IABR74FL.DTA"

egen strata = group(v024 v025) // this makes a distinct number for each combination of v023 and v022 and calls that variable strata
egen psu = group(v001 v024 v025) // sometimes v001 is repeated across strata; better safe than sorry
svyset psu [pweight = v005], strata(strata) // v005 is the weight


* Keep only births in simple look-back period (technically incorrect):
keep if b3 > v008 - 61 & b3 < v008

* TODO: Fix look-back period

* Remove the outliers below 4.5 ft (137.2 cm) and above 6 ft (182.9)
keep if v438 >= 1372 & v438 <= 1829

* Divide height by 10 because v438 is stored with units of tenths of centimeters
gen mother_height_cm = v438/10

* Divide weights by 1,000,000 because v005 is stored with 6 decimal places
gen sample_weight = v005/1000000

* Create group variable, equals 1 if observation is from Uttar Pradesh, else 0
gen is_from_uttar_pradesh = 0
replace is_from_uttar_pradesh = 1 if v024 == 33


* Create variable for neonatal mortality
gen is_neonatal_death = 0
replace is_neonatal_death = 1000 if b7 < 1 // for conventional units of "per thousand"

gen group = is_from_uttar_pradesh // This will be useful so you can see the logic below]
gen outcomevariable = is_neonatal_death // Again, to make this more generic
gen full = outcomevariable!=.&group!=. // This will be useful to define our maximum sample
gen group1 = group == 1&full == 1
gen group0 = group == 0&full == 1


* For a figure without the big dots
* The purpose of this variable is to make a puzzle seem interesting: even at all levels of running variable, there is still a big gap in the outcome variable between groups

*gen runningvariable = mother_height_cm  // so here, we're showing that mother's height doesn't explain the Uttar Pradesh-rest of india NNM gap
*twoway (lpoly outcomevariable runningvariable if group == 1 [aweight=sample_weight],  lc(navy) lw(medthick) ) (lpoly outcomevariable runningvariable if group == 0 [aweight=sample_weight],  lc(forest_green) lw(medthick) lp(longdash)) if full == 1, legend(col(2) order(1 "Uttar Pradesh" 2 "Rest of India")) xtitle("Mother's Height (cm)") ytitle("NNM (per thousand births)") graphr(c(white) lc(white)) name(puzzlegraph)
*graph save puzzlegraph "Graphfilename.gph", replace
*graph export "Graphfilename.pdf", as(pdf) replace

**************************************************************
** making categorical versions of mother's height ************
**************************************************************

* Create variable for deciles for mother's heights
_pctile mother_height_cm, p(10(10)90)
 ret li
 gen mother_height_decile = 10 if mother_height_cm < .
 qui forval i = 9(-1)1 {
         replace mother_height_decile = `i' if mother_height_cm <= r(r`i')
 }

* Create variable for centiles for mother's height
_pctile mother_height_cm, p(1(1)99)
 ret li
 gen mother_height_centile = 100 if mother_height_cm < .
 qui forval i = 99(-1)1 {
         replace mother_height_centile = `i' if mother_height_cm <= r(r`i')
 }
 
**************************************************************
** Kitagawa decomposition ************************************
**************************************************************
 
sum outcomevariable [aweight = sample_weight] if group == 1
local target_mean = r(mean)
local target_sum_weight = r(sum_w)
sum outcomevariable [aweight = sample_weight] if group == 0
local other_mean = r(mean)
local other_sum_weight = r(sum_w)

* Initialize vars
local part_due_to_rate_schedule = 0
local part_due_to_distribution = 0

qui forval i = 10(-1)1 {
		 sum outcomevariable [aweight = sample_weight] if mother_height_decile == `i' & group == 1
		 local target_decile_mean = r(mean)
		 local target_decile_weight = r(sum_w) / `target_sum_weight'
		 sum outcomevariable [aweight = sample_weight] if mother_height_decile == `i' & group == 0
		 local other_decile_mean = r(mean)
		 local other_decile_weight = r(sum_w) / `other_sum_weight'
		 
		 local part_due_to_rate_schedule = `part_due_to_rate_schedule' + (`target_decile_mean'-`other_decile_mean')*(`target_decile_weight'+`other_decile_weight')/2
		 local part_due_to_distribution = `part_due_to_distribution' + (`target_decile_weight'-`other_decile_weight')*(`target_decile_mean'+`other_decile_mean')/2
}

di "full gap: ",`target_mean'-`other_mean'
di "DECILE CALCULATION:"
di "part due to rate schedule: " `part_due_to_rate_schedule'
di "percentage due to rate schedule: " `part_due_to_rate_schedule'/(`target_mean'-`other_mean')*100
di "part due to distribution: " `part_due_to_distribution'
di "percentage due to distribution: " `part_due_to_distribution'/(`target_mean'-`other_mean')*100

* Re-initialize vars
local part_due_to_rate_schedule = 0
local part_due_to_distribution = 0

qui forval i = 100(-1)1 {
		 sum outcomevariable [aweight = sample_weight] if mother_height_centile == `i' & group == 1
		 local target_centile_mean = r(mean)
		 local target_centile_weight = r(sum_w) / `target_sum_weight'
		 sum outcomevariable [aweight = sample_weight] if mother_height_centile == `i' & group == 0
		 local other_centile_mean = r(mean)
		 local other_centile_weight = r(sum_w) / `other_sum_weight'
		 
		 local part_due_to_rate_schedule = `part_due_to_rate_schedule' + (`target_centile_mean'-`other_centile_mean')*(`target_centile_weight'+`other_centile_weight')/2
		 local part_due_to_distribution = `part_due_to_distribution' + (`target_centile_weight'-`other_centile_weight')*(`target_centile_mean'+`other_centile_mean')/2
}



di "CENTILE CALCULATION:"
di "part due to rate schedule: " `part_due_to_rate_schedule'
di "percentage due to rate schedule: " `part_due_to_rate_schedule'/(`target_mean'-`other_mean')*100
di "part due to distribution: " `part_due_to_distribution'
di "percentage due to distribution: " `part_due_to_distribution'/(`target_mean'-`other_mean')*100
 
 
 
**************************************************************
** non-parametric reweighting decomposition ******************
**************************************************************

gen inputbin_dec = mother_height_decile

egen overallbins_dec = group(inputbin_dec group) if full == 1
gen weightforsumming_dec = sample_weight if full == 1
egen sumweights_dec = sum(weightforsumming_dec) if full == 1, by(overallbins_dec)
gen sumweights1_dec = sumweights_dec if group == 1
egen transfersumweights_dec = mean(sumweights1_dec), by(inputbin_dec)
gen multiplier_dec = transfersumweights_dec/sumweights_dec if group == 0
gen newweights_dec = sample_weight*multiplier_dec if group == 0

sum outcomevariable [aweight = sample_weight] if group == 1
local targetmean = r(mean)
sum outcomevariable [aweight = sample_weight] if group == 0
local startingmean = r(mean)
sum outcomevariable [aweight = newweights_dec] if group == 0
local reweightedmean = r(mean)

di "full gap: ",`targetmean'-`startingmean'
di "DECILE CALCULATION:"
di "explained gap: ",`reweightedmean'-`startingmean'
di "unexplained gap: ",`targetmean'-`reweightedmean'
di "explained percent: ", 100*( `reweightedmean'-`startingmean' ) / ( `targetmean'-`startingmean' )


gen inputbin_cent = mother_height_centile

egen overallbins_cent = group(inputbin_cent group) if full == 1
gen weightforsumming_cent = sample_weight if full == 1
egen sumweights_cent = sum(weightforsumming_cent) if full == 1, by(overallbins_cent)
gen sumweights1_cent = sumweights_cent if group == 1
egen transfersumweights_cent = mean(sumweights1_cent), by(inputbin_cent)
gen multiplier_cent = transfersumweights_cent/sumweights_cent if group == 0
gen newweights_cent = sample_weight*multiplier_cent if group == 0

sum outcomevariable [aweight = newweights_cent] if group == 0
local reweightedmean = r(mean)

di "CENTILE CALCULATION:"
di "explained gap: ",`reweightedmean'-`startingmean'
di "unexplained gap: ",`targetmean'-`reweightedmean'
di "explained percent: ", 100*( `reweightedmean'-`startingmean' ) / ( `targetmean'-`startingmean' )

* here you have the CDF:

*preserve
*gen onesandtwos = 2 - group if full
*expand onesandtwos, gen(itsadup)
*tab group itsadup
*tab group itsadup if full
*replace sample_weight = sample_weight*multiplier if itsadup == 1
*gen group3 = group - itsadup
*cdfplot outcomevariable [aweight=sample_weight] if full, by(group3) graphr(c(white) lc(white)) name(cdfgraph) legend(col(3) order(1 "reweighted group0" 2 "original group0" 3 "group1")) xtitle("replace with outcome variable units") ytitle("cumulative distribution") 
*graph save cdfgraph "GraphfilenameCDF.gph", replace
*graph export "GraphfilenameCDF.pdf", as(pdf) replace
*restore

* A normal way to make the decomposition table would be for different rows (each showing the explained gap and percent explained) to use different methods and controls

**************************************************************
** Keep at the end to close your log *************************
**************************************************************
capture log close

