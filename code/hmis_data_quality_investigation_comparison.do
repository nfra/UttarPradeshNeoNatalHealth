* Name: hmis_data_quality_investigation_comparison
* Written by: Nathan Franz
* Description: An investigation into the quality of HMIS data -- comparison portion
* Last edited: 3/23/2020

use ".\UttarPradeshNeoNatalHealth\data\comparison_per_state.dta"

* create comparison bar graphs for each of the places of delivery
graph hbar pct_home, over(survey, label(labsize(tiny))) over(state, label(labsize(vsmall)))
graph display, ysize(7)

graph hbar pct_private, over(survey, label(labsize(tiny))) over(state, label(labsize(vsmall)))
graph display, ysize(7)

graph hbar pct_public, over(survey, label(labsize(tiny))) over(state, label(labsize(vsmall)))
graph display, ysize(7)



