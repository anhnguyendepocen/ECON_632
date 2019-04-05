/*
Created by RM on 2019.02.27
For ECON 632 PS 2
Part 1: Reduced Form Analysis
*/

clear
set more off

global data "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/ProblemSetData/"
global output "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Output"
global temp "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp"

import delim using "$data/insurance_data.csv", delim(",")

save "$temp/insurance_data", replace

/* First check that year and choice sit map perfectly */

use "$temp/insurance_data", clear

bys indiv_id year: egen max_choice_sit = max(choice_sit)
bys indiv_id year: egen min_choice_sit = min(choice_sit)
g choice_sit_dif = max_choice_sit - min_choice_sit
su choice_sit_dif, d

/* Question 1: Do Individuals Choose Options That Appear to be Dominated */

use "$temp/insurance_data", clear

/* Assume All Plans Available to All Employees, Consistent with Understanding of Employer Sponsored Health Insurance 
BUT needs to be same year*/

local chosenvars "premium plan_coverage plan_service_quality"

foreach var of local chosenvars {
	g pre_chosen_`var' = `var' if plan_id == plan_choice
	bys indiv_id year: egen chosen_`var' = max(pre_chosen_`var')
	drop pre_chosen_`var'
}

g pre_chose_dominated = plan_id != plan_choice & premium <= chosen_premium ///
	& plan_coverage >= chosen_plan_coverage & plan_service_quality >= chosen_plan_service_quality

bys indiv_id year: 	egen chose_dominated = max(pre_chose_dominated)

g ones = 1
bys indiv_id year: egen num_plans = sum(ones)
drop ones

drop pre_chose_dominated

save "$temp/add_chose_dominated", replace

*Examine Statistically Significant Predictors of Picking a Dominated Plan
use "$temp/add_chose_dominated", clear

keep plan_id plan_choice indiv_id year chose_dominated age sex risk_score income years_enrolled has_comparison_tool premium plan_coverage plan_service_quality num_plans
keep if plan_id == plan_choice

egen minyear = min(year)
local minyear = minyear
egen maxyear = max(year)
local maxyear = maxyear

local vars "age sex risk_score income years_enrolled has_comparison_tool chose_dominated premium plan_coverage plan_service_quality num_plans"

g year_summary = .
g var_summary = ""
g sum_p25 = .
g sum_p50 = .
g sum_p75 = .
g sum_min = .
g sum_max = .
g sum_mean = .
g sum_sd = .
g sum_N = .

local counter = 1

g obs = [_n]

forv m = `minyear'(1)`maxyear' {

	foreach var of local vars {

			quietly: su `var' if year == `m', d
			
			replace year_summary = `m' if obs == `counter'
			replace var_summary = "`var'" if obs == `counter'
			
			replace sum_p25 = r(p25) if obs == `counter'
			replace sum_p50 = r(p50) if obs == `counter'
			replace sum_p75 = r(p75) if obs == `counter'
			replace sum_min = r(min) if obs == `counter'
			replace sum_max = r(max) if obs == `counter'
			replace sum_mean = r(mean) if obs == `counter'
			replace sum_sd = r(sd) if obs == `counter'
			replace sum_N = r(N) if obs == `counter'

			local counter = `counter' + 1
			
		}
			
}
	
keep sum* year_sum* var_sum*

drop if year_summary == .

export excel using "$output/SummaryStats_PS2.xlsx", first(var) replace

use "$temp/add_chose_dominated", clear

egen minyear = min(year)
local minyear = minyear
egen maxyear = max(year)
local maxyear = maxyear

bys year indiv_id: egen min_premium = min(premium)

g last_year_plan = .

forv m = `minyear'(1)`maxyear' {
	local mplus = `m' + 1
	g last_year = year == `m'
	bys indiv_id: egen pre_last_year_plan = max(last_year * plan_choice)
	replace last_year_plan = pre_last_year_plan if year == `mplus'
	drop last_year
	drop pre_last_year_plan
}

replace last_year_plan = . if last_year_plan == 0

bys year indiv_id: egen pre_plan_goes_away = min(abs(last_year_plan - plan_id))
g plan_goes_away = 0
replace plan_goes_away = 1 if pre_plan_goes_away > 0 & last_year_plan != .

*sort indiv_id year plan_id
*browse indiv_id year plan_id plan_choice last_year_plan pre_plan_goes_away plan_goes_away

g switch_plan = last_year_plan != plan_choice & last_year_plan != .
g same_plan = last_year_plan == plan_id

g num_plans_2 = num_plans^2

save "$temp/allrows_addvars", replace

keep if plan_id == plan_choice

g chose_min = premium == min_premium

g chose_new_dominated = switch_plan * chose_dominated

drop pre_plan_goes_away 

save "$temp/deduped_addvars", replace


/* Dominated Plan Analysis */

use "$temp/deduped_addvars", clear

g ones = 1
bys year: egen total_year = sum(ones)
bys year: egen sum_dom = sum(chose_dominated)
drop ones

g perc_dom = sum_dom / total_year

graph twoway (bar perc_dom year, barw(.4) xtitle("Year") ytitle("Percent") ///
		title("Percent of Participants Choosing a Dominated Plan") legend( si(small) cols(1) ///
		lab(1 "% of Participants Choosing a Dominated Plan") ) ///
		note("Note: Percent Choosing Dominated Plan represents the percent of participants who chose a dominated plan.", si(vsmall) ) )
graph export "$output/Dominated_Plan.pdf", as (pdf) replace	


/* Switching Analysis */

bys year: egen count_switch_plan = sum(switch_plan)
g perc_switch_plan = count_switch_plan/total_year

graph twoway (bar perc_switch_plan year, barw(.4)  xtitle("Year") ytitle("Percent") ///
	title("Percent of Participants Switching Plans") ///
	note("Note: No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) ) )
graph export "$output/Switch_Plan.pdf", as (pdf) replace	

g ones = 1
bys year has_comparison_tool: egen count_year_tool = sum(ones)	
bys year has_comparison_tool: egen count_switch_plan_by_tool = sum(switch_plan)

g perc_switch_plan_by_tool = count_switch_plan_by_tool/count_year_tool
bys year: egen perc_switch_plan_with_tool = max(has_comparison_tool * perc_switch_plan_by_tool)
bys year: egen perc_switch_plan_no_tool = max((1-has_comparison_tool) * perc_switch_plan_by_tool)

g year_no_tool = year - .2
g year_tool = year + .2

bys year: egen count_tool = sum(has_comparison_tool)
g perc_tool = count_tool / total_year

graph twoway (bar perc_switch_plan_no_tool year_no_tool, barw(.4)) (bar perc_switch_plan_with_tool year_tool, barw(.4) ) ///
	(scatter perc_tool year, msize(small) connect(I) xtitle("Year") ytitle("Percent") ///
	title("Percent of Participants Switching Plans:") ///
	title("By Access to Comparison Tool", suffix) ///
	legend( si(small) lab(1 "% of Participants Switching Without Comparison Tool") ///
			lab(2 "% of Participants Switching With Comparison Tool") ///
			lab(3 "% of Participants With Comparison Tool") cols(1) ) ///
	note("Note: No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) ) )
graph export "$output/Switch_Plan_Tool.pdf", as (pdf) replace


/* Switching to Dominated Plan Analysis */

bys year: egen sum_new_dom = sum(chose_new_dominated)
g perc_new_dom = sum_new_dom / total_year

g year_dom = year - .2
g year_new_dom = year + .2

graph twoway (bar perc_dom year_dom, barw(.4)) (bar perc_new_dom year_new_dom, barw(.4) xtitle("Year") ytitle("Percent") ///
		title("Participants Choosing vs Switching to Dominated Plans") legend( si(small) cols(1)  ///
		lab(1 "% Choosing a Dominated Plan") lab(2 "% Switching to a Dominated Plan") ) ///
		note("Note: Percent Choosing Dominated Plan represents the percent of participants who chose a dominated plan.", si(vsmall) ) ///
		note("Percent Switching to Dominated Plan represents the percent of participants who chose a dominated plan and switched plans.", si(vsmall)  suffix) ///
		note("No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) suffix) )

graph export "$output/Switch_Dominated_Plan.pdf", as (pdf) replace	

bys year: egen dom_same = sum( same_plan * chose_dominated)
g perc_dom_same = dom_same / sum_dom

graph twoway (bar perc_dom_same year, barw(.4)  xtitle("Year") ytitle("Percent") ///
	title("Percent of Dominated Plan Selections")  ///
	title("Identical to Previous Year's Selection ", suffix) legend(off) ///
	note("Note: Bars represent the percent of selections of dominated plans that are identical to the previous years' plan choice.", si(vsmall) ) ///
	note("No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) suffix) )

graph export "$output/Inertia_Dominated_Plan.pdf", as (pdf) replace	

bys year has_comparison_tool: egen count_switch_dom_by_tool = sum(chose_new_dominated)
g perc_switch_dom_by_tool = count_switch_dom_by_tool / count_tool

bys year: egen perc_switch_dom_with_tool = max(has_comparison_tool * perc_switch_dom_by_tool)
bys year: egen perc_switch_dom_no_tool = max((1-has_comparison_tool) * perc_switch_dom_by_tool)

graph twoway (bar perc_switch_dom_no_tool year_no_tool, barw(.4)) (bar perc_switch_dom_with_tool year_tool, barw(.4) ) ///
	(scatter perc_tool year, msize(small) connect(I) xtitle("Year") ytitle("Percent") ///
	title("Percent of Participants Switching to a Dominated Plan:") ///
	title("By Access to Comparison Tool", suffix) ///
	legend( si(small) lab(1 "% of Participants Switching to a Dominated Plan Without Comparison Tool") ///
			lab(2 "% of Participants Switching to a Dominated Plan With Comparison Tool") ///
			lab(3 "% of Participants With Comparison Tool") cols(1) ) ///
	note("Note: No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) ) )

graph export "$output/Dom_Switch_Plan_Tool.pdf", as (pdf) replace


/* Regression Analysis */

use "$temp/deduped_addvars", clear

logit chose_dominated age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 same_plan plan_goes_away i.year if year > 2008
margins, dydx(*) post
	regsave age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 same_plan plan_goes_away ///
	using "$temp/reduced_form_logit", pval addlabel(outcome, "chose_dominated",interacts, "None") replace
logit switch_plan age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 chose_min i.year if year > 2008 & plan_goes_away == 0
margins, dydx(*) post
	regsave age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 chose_min ///
	using "$temp/reduced_form_logit", pval addlabel(outcome, "switch_plan",interacts, "None") append
logit chose_new_dominated age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 plan_goes_away i.year if year > 2008
margins, dydx(*) post
	regsave age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 plan_goes_away ///
	using "$temp/reduced_form_logit", pval addlabel(outcome, "chose_new_dominated",interacts, "None") append

*Disadvantage of Reduced Form: Hard to Compare distance when multiple dominating plans, which occurs
*Hard to think about price elasticity for higher income
g risk_score_comp_tool = risk_score * has_comparison_tool
g num_plans_comp_tool = has_comparison_tool * num_plans

logit switch_plan risk_score_comp_tool num_plans_comp_tool age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 chose_min i.year if year > 2008 & plan_goes_away == 0
margins, dydx(*) post
	regsave risk_score_comp_tool num_plans_comp_tool age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 chose_min ///
	using "$temp/reduced_form_logit", pval addlabel(outcome, "switch_plan",interacts, "Yes") append
logit chose_new_dominated risk_score_comp_tool num_plans_comp_tool age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 plan_goes_away chose_min i.year if year > 2008
margins, dydx(*) post
	regsave risk_score_comp_tool num_plans_comp_tool age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 plan_goes_away chose_min ///
	using "$temp/reduced_form_logit", pval addlabel(outcome, "chose_new_dominated",interacts, "Yes") append

use "$temp/reduced_form_logit", clear

replace var = outcome + ":" + var

**TOSTRING FOR EXPORT
g coef_round = round(coef,.001)
tostring(coef_round), replace force
replace coef_round = substr(coef_round,1,strpos(coef_round,".")+3)

g stderr_round = round(stderr,.001)
tostring(stderr_round), replace force
replace stderr_round = substr(stderr_round,1,strpos(stderr_round,".")+3)

replace stderr_round = "(" + stderr_round + ")"

replace stderr_round = stderr_round + "*" if pval < .1
replace stderr_round = stderr_round + "*" if pval < .05
replace stderr_round = stderr_round + "*" if pval < .01

export excel using "$output/ReducedFormLogit.xlsx", first(var) replace

/* Prepare Data for Export to Matlab */

use "$temp/deduped_addvars", clear

keep indiv_id year num_plans last_year_plan plan_goes_away chose_min

save "$temp/mergeon", replace

use "$temp/allrows_addvars", clear

merge m:1 indiv_id year using "$temp/mergeon"

drop _merge

drop if year == 2008

local quartilevars "income risk_score"

foreach var of local quartilevars {

	su `var', d

	g `var'_q1 = `var' < r(p25)
	g `var'_q2 = r(p25) <= `var' & `var' < r(p50)
	g `var'_q3 = r(p50) <= `var' & `var' < r(p75)
	g `var'_q4 = r(p75) <= `var' 
	}

forv i = 1(1)4{
	g premium_income_q`i' = premium * income_q`i'
	g quality_risk_q`i' = plan_service_quality * risk_score_q`i'
	g coverage_risk_q`i' = plan_coverage * risk_score_q`i'
	}

drop minyear maxyear pre_plan_goes_away
	
save "$temp/insurance_data_for_matlab", replace	
	
export delim "$temp/insurance_data_mod.csv", delim(",") replace
 

 
 /* Target Two Moments: For Params for Normal */
 
 drop if plan_goes_away == 1
 drop if years_enrolled == 1
 keep if indiv_id == plan_choice
 su switch_plan
 
 

