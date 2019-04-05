
/*
Created by RM on 2019.03.08
For ECON 632 PS 2
Part 2: Structural Analsysis: Dominated Plan Choice
*/


clear
set more off

global data "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/ProblemSetData/"
global output "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Output"
global temp "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp"

import delim using "$temp/params_hat.csv", delim(",")

/* Prepare the data */

rename v1 alpha1
rename v2 alpha2
rename v3 alpha3
rename v4 alpha4
rename v5 beta1
rename v6 beta2
rename v7 beta3
rename v8 beta4
rename v9 gamma1
rename v10 gamma2
rename v11 gamma3
rename v12 gamma4
rename v13 delta1
rename v14 delta2
rename v15 delta3
rename v16 psi1
rename v17 psi2
rename v18 psi3
rename v19 psi4
rename v20 psi5
rename v21 psi6
rename v22 psi7
rename v23 psi8
rename v24 psi9
rename v25 psi10
rename v26 psi11
rename v27 mu
g sigma2 = 1

g to_merge = 1

save "$temp/params_hat_rename", replace

use "$temp/insurance_data_for_matlab", clear

g to_merge = 1

merge m:1 to_merge using "$temp/params_hat_rename"

drop _merge
drop to_merge

/* Begin to get counterfactual choices */

bys indiv_id: egen first_year_participant = min(year)
bys indiv_id: egen last_year_participant = max(year)

g active_choice_shock = rnormal(mu,sigma2)

g years_in_program = last_year_participant - first_year_participant
egen max_years_in_program = max(years_in_program)

g year_in_program_recode = year + 1 - first_year_participant

local maxyearsprogram = max_years_in_program

g first_year = years_enrolled == 1


g chose_min_sim = 0
replace chose_min_sim = chose_min if year_in_program_recode == 1
g plan_goes_away_sim = plan_goes_away if year_in_program_recode == 1
g same_plan_sim = same_plan if year_in_program_recode == 1
g plan_choice_sim = .
g last_year_plan_sim = last_year_plan if year_in_program_recode == 1

g taste_shock_cdf = runiform()
g taste_shock_scale = sqrt(6 / (c(pi)^2) )
g taste_shock = -1 * taste_shock_scale * log( - 1 * log(taste_shock_cdf))


forv y=1(1)`maxyearsprogram' {

	*di "y is `y'"

	g active_choice_prob_`y' = psi1 * has_comparison_tool + psi2 * num_plans + psi3 * num_plans^2 ///
						+ psi4 * risk_score + psi5 * age + psi6 * income + psi7 * years_enrolled ///
						+ psi8 * chose_min_sim + psi9 * has_comparison_tool * num_plans ///
						+ psi10 * has_comparison_tool * risk_score + psi11 * has_comparison_tool * age ///
						 if year_in_program_recode == `y'
	
	g active_choice_`y' = active_choice_prob_`y' > 0
	
	replace active_choice_`y' = max(first_year,active_choice_`y', plan_goes_away_sim)
	
	g indir_util_`y' = 0

	forv i = 1(1)4 {
		replace indir_util_`y' = indir_util_`y' + alpha`i' * premium_income_q`i' + beta`i' * quality_risk_q`i' ///
								+ gamma`i' * coverage_risk_q`i'  if year_in_program_recode == `y'
		if `i' < 4 {
			replace indir_util_`y' = indir_util_`y' + delta1 * plan_coverage + delta2 * plan_service_quality ///
			+ delta3 * same_plan_sim if year_in_program_recode == `y'
		}
	}
	
	bys indiv_id year: egen max_indir_util_`y' = max(indir_util_`y')
	
		/* Now Update Sim Variables */
	
	g pre_pre_plan_choice_sim = plan_id if year_in_program_recode == `y' & indir_util_`y' == max_indir_util_`y'
	replace pre_pre_plan_choice_sim = last_year_plan_sim if active_choice_`y' == 0
	
	bys indiv_id year: egen pre_plan_choice_sim = max(pre_pre_plan_choice_sim)
	
	replace plan_choice_sim = pre_plan_choice_sim if year_in_program_recode == `y'
	
	drop pre_pre_plan_choice_sim pre_plan_choice_sim
	
	save "$temp/base", replace
	
	keep indiv_id year plan_choice_sim
	duplicates drop
	xtset indiv_id year
	g last_year_plan_sim_mergeon = L1.plan_choice_sim
	
	drop plan_choice_sim
	
	save "$temp/mergeon_last_year_plan_sim", replace
	
	use "$temp/base", clear
	
	merge m:1 indiv_id year using  "$temp/mergeon_last_year_plan_sim"
	
	replace last_year_plan_sim = last_year_plan_sim_mergeon if last_year_plan_sim == .
	
	replace same_plan_sim = plan_id == last_year_plan_sim
	
	bys indiv_id year: egen max_same_plan_sim = max(same_plan_sim)	
	replace plan_goes_away_sim = max_same_plan_sim == 0
	drop max_same_plan_sim
	
	drop _merge last_year_plan_sim_mergeon

	
	/* Still Need Chose Min Sim */
	
	g chosen_premium_sim = premium if plan_id == plan_choice_sim & year_in_program_recode == `y'
	bys indiv_id year: egen min_premium_sim = min(premium)
	replace chose_min_sim = 1 if year_in_program_recode == `y' & chosen_premium_sim == min_premium_sim
	
	drop chosen_premium_sim min_premium_sim
	
	
}


g correct_sim = plan_choice_sim == plan_choice 
replace correct_sim = . if plan_choice_sim == .

preserve
keep if plan_id == plan_choice_sim

tab num_plans correct_sim, row
restore

/*
 sort indiv_id year plan_id
 browse indiv_id year plan_id year_in_program_recode active_choice_1 indir_util_1 active_choice_2 indir_util_2 plan_choice_sim last_year_plan_sim
*/

/* Compare Statistics About Dominated Plan */

rename plan_service_quality quality

local chosenvars "premium plan_coverage quality"

capture drop chosen_sim_premium

foreach var of local chosenvars {
	g pre_chosen_sim_`var' = `var' if plan_id == plan_choice_sim
	bys indiv_id year: egen chosen_sim_`var' = max(pre_chosen_sim_`var')
	drop pre_chosen_sim_`var'
}



g pre_chose_sim_dominated = plan_id != plan_choice_sim & premium <= chosen_sim_premium ///
	& plan_coverage >= chosen_sim_plan_coverage & quality >= chosen_sim_quality

bys indiv_id year: 	egen chose_sim_dominated = max(pre_chose_sim_dominated)

keep indiv_id year plan_choice_sim chose_sim_dominated

duplicates drop

save "$temp/baseline_sim_choice_dominated", replace


