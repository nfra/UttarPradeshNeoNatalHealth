
*******************************************************************************************************
* Model do file for Indian Statistical Institute - Delhi course on demographic decompositions in Stata
* Dean Spears, November 2015, www.riceinstitute.org
* This do file is provided as-is, with no guarantees or technical support
* You will need the user written commands oaxaca, esttab, and cdfplot
*******************************************************************************************************

* This do file helps you make a standard decomposition paper, a convenient way to describe some interesting or important empirical fact about the world

* Table 1: Summary statistics
* Figure 1: A puzzling difference between two groups (even at all levels of a third variable); you could have a panel A and B showing this for two different running variables
* Figure 2: Suggestive evidence that an explanatory factor can explain the difference
* Table 2: A regression table showing that the explanatory factor can linearly account for the difference, with and without an extended set of controls
* Table 3: Evidence from a decomposition: Oaxaca-Blinder and non-parametric reweighting
* Figure 3: Reweighted CDFs corresponding to the non-parametric decomoposition

* It probably makes sense to add an additional regression table with an interesting sample split and/or one with a useful falsification test; that would be 8 exhibits. 

*******************************************************************************************************

version 12.1  // I wrote this in stata vesion 12.1

global directory "C:\Users\Nathan\Documents\RA Research\Development Economics II - Spears\decomposition\"

clear all
set more off  // so the do file keeps rolling
set seed 8062011  // so that any randomized results, like bootstraps, are replicable

cd "$directory"

capture log close  // in case you already have a log going
log using isilog, replace smcl

use BDBR51FL.DTA

egen strata = group(v024 v025) // this makes a distinct number for each combination of v025 and v024 and calls that variable strata
egen psu = group(v001 v024 v025) // sometimes v001 is repeated across strata; better safe than sorry
svyset psu [pweight = v005], strata(strata) // v005 is the weight

**************************************************************
** Make variables ********************************************
**************************************************************

gen hfa = hw70/100 if hw70 <= 600   // it has two decimals and is missing if above 600
gen girl = b4 == 2 if b4 < . // it's 1/2.  note the == for the if statement and that the missing . is larger than any number
gen rural = v025 == 2 if v025 < .
gen electricity = v119 == 1 if v119 <= 1
gen refrigerator = v122 == 1 if v122 < = 1
gen hhsize = v136
gen education = v106 if v106 < 9

global controls girl electricity refrigerator hhsize

* Change this part to reflect the variables that you are using
gen group = rural // This will be useful so you can see the logic below]
gen outcomevariable = hfa // Again, to make this more generic
gen full = outcomevariable!=.&group!=.&education != . // This will be useful to define our maximum sample
gen group1 = group == 1&full == 1
gen group0 = group == 0&full == 1

**************************************************************
** Make summary statistics table *****************************
**************************************************************

* First I'll make variables to store the results in 

foreach sample in full group1 group0 {
gen mean`sample' = .
gen se`sample' = .
}
gen variablename = ""  // notice this one is a string
gen ttest = .

* Now I'll fill that in for each variable

local looper = 0
foreach var in outcomevariable rural education $controls{
local looper = `looper' + 1
replace variablename = "`var'" if _n == `looper'
foreach sample in full group1 group0 {
svy: mean `var' if `sample' == 1
replace mean`sample' = _b[`var'] if _n == `looper'
replace se`sample' = _se[`var'] if _n == `looper'
}
svy: reg `var' group if full == 1
replace ttest = _b[group]/_se[group] if _n == `looper'
}

tab group if full == 1

list variablename meanfull sefull meangroup1 segroup1 meangroup0 segroup0 ttest if _n <= `looper', clean

* So, you'll need to copy and paste that into whatever program (Excel, Latex) you use to make your tables
* Notice that we have results by subgroup, and test whether each variable is different

**************************************************************
** Make figures **********************************************
**************************************************************

* If the distribution of your horizontal axis variable is very skewed or otherwise has long thin tails, you might use sum, detail (with r(p1) and r(p99)) to make a trimming indicator for inclusion before the figure.

* For a figure without the big dots
* The purpose of this variable is to make a puzzle seem interesting: even at all levels of running variable, there is still a big gap in the outcome variable between groups

gen runningvariable = hw1  // so here, we're showing that age in months doesn't explain the rural-urban height gap
twoway (lpoly outcomevariable runningvariable if group == 1 [aweight=v005],  lc(navy) lw(medthick) ) (lpoly outcomevariable runningvariable if group == 0 [aweight=v005],  lc(forest_green) lw(medthick) lp(longdash)) if full == 1, legend(col(2) order(1 "rural" 2 "urban")) xtitle("age in months") ytitle("height-for-age z-score") graphr(c(white) lc(white)) name(puzzlegraph)
graph save puzzlegraph "Graphfilename.gph", replace
graph export "Graphfilename.pdf", as(pdf) replace


* For a figure with the big dots
* The purpose here is to show that our explaining variable, in this case education, can account for the difference, or see by how much it does.
* egen has many uses; you saw group earlier; now you will see tag

gen meanoutcomevariable = .
gen meaned = .
foreach g in 1 0 {
svy: mean outcomevariable if full == 1 & group == `g'
replace meanoutcomevariable = _b[outcomevariable] if full==1&group == `g' 
svy: mean education if full == 1 & group == `g'
replace meaned = _b[education] if full==1&group == `g' 
}
egen grouptag = tag(group) if full == 1  // this picks out just one
* add a scatter:
twoway (lpoly outcomevariable education if group == 1 [aweight=v005],  lc(navy) lw(medthick) ) (lpoly outcomevariable education if group == 0 [aweight=v005],  lc(forest_green) lw(medthick) lp(longdash)) (scatter meanoutcomevariable meaned if grouptag == 1&group==1, color(navy) msize(large)) (scatter meanoutcomevariable meaned if grouptag == 1&group==0, color(forest_green) msize(large) msymbol(Oh)) if full == 1, legend(col(2) order(1 "rural" 2 "urban")) xtitle("mother's education") ytitle("height-for-age z-score") graphr(c(white) lc(white)) name(candidateanswergraph)
graph save candidateanswergraph "Graphfilenamedots.gph", replace
graph export "Graphfilenamedots.pdf", as(pdf) replace

* clearly in this example it looks like education doesn't explain it all very well: the lines are different in rural and urban, and the dots aren't seeming to be explained by a common relationship
 
**************************************************************
** Make regression table *************************************
**************************************************************

* Just for the historical record, it's obviously wrong for me to be putting in the four category education variable as though it were continuous; that was also clear in the graph with dots

* The point here is to see whether adding the explanatory variable (education) changes the coefficient and significance of the group variable, here rural
reg outcomevariable rural if full == 1, cluster(psu)
est store a
reg outcomevariable rural education if full == 1, cluster(psu)
est store b

reg outcomevariable rural $controls if full == 1, cluster(psu)
est store c
reg outcomevariable rural education $controls if full == 1, cluster(psu)
est store d

esttab a b c d, se star(+ 0.1 * 0.05 ** 0.01 *** 0.001) 

* And here if we want to save it in an easy format to put on our computer:
esttab a b c d using tableoutput.csv, se star(+ 0.1 * 0.05 ** 0.01 *** 0.001) replace


**************************************************************
** Oaxaca-Blinder decomposition ******************************
**************************************************************

oaxaca outcomevariable education if full == 1 , by(rural) omega
oaxaca outcomevariable education if full == 1 , by(rural) pooled
oaxaca outcomevariable education if full == 1 , by(rural) weight(0.5)

* What if, as an arbitrary example, I wanted to do it by hand, compute the coefficients separately, weight the coefficients from the two groups equally, and I thought the right thing to do was control for girl in the rural model and household size in the urban model?  OK:

local weightonbeta1 = 0.5
reg outcomevariable education girl if full==1&group1
local beta1 = _b[education]
reg outcomevariable education hhsize if full==1&group0
local beta0 = _b[education]
local betastar = (`weightonbeta1')*`beta1'+(1-`weightonbeta1')*`beta0'
reg outcomevariable group if full
local outcomegap = _b[group]
reg education group if full
local inputgap = _b[group]

di "full gap: ",`outcomegap'
di "explained gap: ",`inputgap'*`betastar'
di "unexplained gap: ",`outcomegap'-`inputgap'*`betastar'
di "explained percent: ", 100*`inputgap'*`betastar'/`outcomegap'

* One standard thing to do would be to include a set of controls in each of these four regressions; that would change both the slopes and the initial gap to be explained, but it might leave the percent explained similar.  What do you think this would mean?


**************************************************************
** non-parametric reweighting decomposition ******************
**************************************************************

* Here we will ask the question, what would urban height be if it matched the distribution of rural mom's education?

tab education group if full == 1, col nof
* graph pie if full == 1, over(education) by(group)
tab education group if full ==1, sum(hfa) nost nof noo

* I've been using education as though it were continuous.  A key part here is making some categorical version of your input variable, such as splitting it into deciles. Here, we don't have to do that.
gen inputbin = education 
* So, we could have made this with more explanatory variables, like egen inputbin = group(education girl)
* A way to make groups from a continuous variable might be gen inputbin = floor(education/c), where c is some constant

egen overallbins = group(inputbin group) if full == 1
gen weightforsumming = v005 if full == 1
egen sumweights = sum(weightforsumming) if full == 1, by(overallbins)
gen sumweights1 = sumweights if group == 1
egen transfersumweights = mean(sumweights1), by(inputbin)
gen multiplier = transfersumweights/sumweights if group == 0
gen newweights = v005*multiplier if group == 0

sum outcomevariable [aweight = v005] if group == 1
local targetmean = r(mean)
sum outcomevariable [aweight = v005] if group == 0
local startingmean = r(mean)
sum outcomevariable [aweight = newweights] if group == 0
local reweightedmean = r(mean)

di "full gap: ",`targetmean'-`startingmean'
di "explained gap: ",`reweightedmean'-`startingmean'
di "unexplained gap: ",`targetmean'-`reweightedmean'
di "explained percent: ", 100*( `reweightedmean'-`startingmean' ) / ( `targetmean'-`startingmean' )


* here you have the CDF:

preserve
gen onesandtwos = 2 - group if full
expand onesandtwos, gen(itsadup)
tab group itsadup
tab group itsadup if full
replace v005 = v005*multiplier if itsadup == 1
gen group3 = group - itsadup
cdfplot outcomevariable [aweight=v005] if full, by(group3) graphr(c(white) lc(white)) name(cdfgraph) legend(col(3) order(1 "reweighted group0" 2 "original group0" 3 "group1")) xtitle("replace with outcome variable units") ytitle("cumulative distribution") 
graph save cdfgraph "GraphfilenameCDF.gph", replace
graph export "GraphfilenameCDF.pdf", as(pdf) replace
restore

* A normal way to make the decomposition table would be for different rows (each showing the explained gap and percent explained) to use different methods and controls

**************************************************************
** Keep at the end to close your log *************************
**************************************************************
capture log close
