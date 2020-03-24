* Name: hmis_data_quality_investigation_hmis
* Written by: Nathan Franz
* Description: An investigation into the quality of HMIS data -- HMIS portion
* Last edited: 3/23/2020

use ".\UttarPradeshNeoNatalHealth\data\hmis1415_per_state.dta"

gen num_pvt_dlv = num_inst_dlv - num_pbl_dlv
label variable num_pvt_dlv "Number of babies delivered at private institutions in FY 2014-2015"

gen pct_hom_dlv = num_hom_dlv / tot_rptd_dlv * 100
label variable pct_hom_dlv "Pctg. delivered at home of all reported babies delivered in FY 2014-2015"

gen pct_pbl_dlv = num_pbl_dlv / tot_rptd_dlv * 100
label variable pct_pbl_dlv "Pctg. delivered at public inst. of all reported babies delivered in FY14-15"

gen pct_pvt_dlv = num_pvt_dlv / tot_rptd_dlv * 100
label variable pct_pvt_dlv "Pctg. delivered at private inst. of all reported babies delivered in FY14-15"

table state, c(mean pct_hom_dlv  mean pct_pbl_dlv  mean pct_pvt_dlv) row col