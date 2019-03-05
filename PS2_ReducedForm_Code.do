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

drop choice_sit

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

			su `var' if year == `m', d
			
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

keep if plan_id == plan_choice

xtset indiv_id year

g last_year_plan = L1.plan_choice

g switch_plan = last_year_plan != plan_choice & last_year_plan != .

g num_plans_2 = num_plans^2

g chose_new_dominated = switch_plan * chose_dominated

save "$temp/deduped_addvars", replace


/* Dominated Plan Analysis */

use "$temp/deduped_addvars", clear

g ones = 1
bys year: egen total_year = sum(ones)
bys year: egen sum_dom = sum(chose_dominated)
bys year: egen sum_new_dom = sum(chose_new_dominated)
drop ones

g perc_dom = sum_dom / total_year
g perc_new_dom = sum_new_dom / total_year

graph twoway (bar perc_dom year, barw(.4) xtitle("Year") ytitle("Percent") ///
		title("Percentage of Participants Choosing Dominated Plans") legend( width(100) cols(1) ///
		lab(1 "Percent Choosing Dominated Plan") ) ///
		note("Note: Percent Choosing Dominated Plan represents the percent of participants who chose a dominated plan.", si(vsmall) ) )
graph export "$output/Dominated_Plan.pdf", as (pdf) replace	


/* Switching Analysis */

bys year: egen count_switch_plan = sum(switch_plan)
g perc_switch_plan = count_switch_plan/total_year

graph twoway (bar perc_switch_plan year, barw(.4)  xtitle("Year") ytitle("Percent") ///
	title("Percentage of Participants Switching Plans") ///
	note("Note: No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) ) )
graph export "$output/Switch_Plan.pdf", as (pdf) replace	

g ones = 1
bys year has_comparison_tool: egen count_year_tool = sum(ones)	
bys year has_comparison_tool: egen count_switch_plan_by_tool = sum(switch_plan)

g perc_switch_plan_by_tool = count_switch_plan_by_tool/total_year
bys year: egen perc_switch_plan_with_tool = max(has_comparison_tool * perc_switch_plan_by_tool)
bys year: egen perc_switch_plan_no_tool = max((1-has_comparison_tool) * perc_switch_plan_by_tool)

g year_no_tool = year - .2
g year_tool = year + .2

bys year: egen count_tool = sum(has_comparison_tool)
g perc_tool = count_tool / total_year

graph twoway (bar perc_switch_plan_no_tool year_no_tool, barw(.4)) (bar perc_switch_plan_with_tool year_tool, barw(.4) ) ///
	(scatter perc_tool year, msize(small) connect(I) xtitle("Year") ytitle("Percent") ///
	title("Percentage of Participants Switching Plans:") ///
	title("By Access to Comparison Tool", suffix) ///
	legend( lab(1 "Percent of Participants Switching Without Comparison Tool") ///
			lab(2 "Percent of Participants Switching With Comparison Tool") ///
			lab(3 "Percent of Participants With Comparison Tool") cols(1) ) ///
	note("Note: No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) ) )
graph export "$output/Switch_Plan_Tool.pdf", as (pdf) replace


/* Switching to Dominated Analysis */

g year_dom = year - .2
g year_new_dom = year + .2

graph twoway (bar perc_dom year_dom, barw(.4)) (bar perc_new_dom year_new_dom, barw(.4) xtitle("Year") ytitle("Percent") ///
		title("Percentage of Participants Switching to Dominated Plans") legend( width(100) cols(1)  ///
		lab(1 "Percent Choosing Dominated Plan") lab(2 "Percent Switching to Dominated Plan") ) ///
		note("Note: Percent Choosing Dominated Plan represents the percent of participants who chose a dominated plan.", si(vsmall) ) ///
		note("Percent Switching to Dominated Plan represents the percent of participants who chose a dominated plan and switched plans.", si(vsmall)  suffix) ///
		note("No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) suffix) )

graph export "$output/Switch_Dominated_Plan.pdf", as (pdf) replace	

g same_plan = plan_choice == last_year_plan
bys year: egen dom_same = sum( same_plan * chose_dominated)
g perc_dom_same = dom_same / sum_dom


graph twoway (bar perc_dom_same year, barw(.4)  xtitle("Year") ytitle("Percent") ///
	title("Percentage of Dominated Plan Selections")  ///
	title("Identical to Previous Year's Selection ", suffix) legend(off) ///
	note("Note: Bars represent the percent of selections of dominated plans that are identical to the previous years' plan choice.", si(vsmall) ) ///
	note("No data on plan choices prior to 2008 are available; therefore, no participants can be identified as having switched in 2008.", si(vsmall) suffix) )
graph export "$output/Inertia_Dominated_Plan.pdf", as (pdf) replace	


/* Also Graph This by Comparison Tool */


*xtset indiv_id year
*xtreg chose_dominated i.year age sex risk_score income years_enrolled, fe
reg chose_dominated i.year age sex risk_score income years_enrolled has_comparison_tool  premium plan_service_quality plan_coverage num_plans num_plans_2

*Find that tool matters and that less healthy individuals check more
/*
*Investigate Inertia by Seeing What Percent of Chose Dominated Are Just People Who Kept a Plan
use "$temp/add_chose_dominated", clear

keep indiv_id year plan_choice
duplicates drop

xtset indiv_id year

g last_year_plan = L1.plan_choice


save "$temp/last_year_plan", replace

use "$temp/add_chose_dominated", clear

merge m:1 indiv_id year plan_choice using "$temp/last_year_plan"
drop _merge

save "$temp/add_last_year", replace

use "$temp/add_last_year", clear

g num_plans_2 = num_plans^2
keep indiv_id year chose_dominated age sex risk_score income years_enrolled has_comparison_tool last_year_plan plan_choice num_plans num_plans_2

duplicates drop

g chose_new_dominated = chose_dominated == 1 & last_year_plan != plan_choice
reg chose_new_dominated i.year age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2

g chose_same = plan_choice == last_year_plan
reg chose_dominated i.year age sex risk_score income years_enrolled has_comparison_tool num_plans num_plans_2 chose_same


	
*Generate by Year and Tool Comparison Percent Choosing Dominated Plan
use "$temp/add_chose_dominated", clear

preserve

keep if plan_id == plan_choice
g ones = 1



bys year has_comparison_tool: egen consumers_year_tool = sum(ones)
bys year has_comparison_tool: egen consumers_year_tool_dom = sum(chose_dominated)
g perc_dom = consumers_year_tool_dom/consumers_year_tool

bys year: egen consumers_year_with_tool = sum(has_comparison_tool)
bys year: egen consumers_year = sum(ones)
g perc_tool = consumers_year_with_tool / consumers_year

bys year tool: 

keep indiv_id year consumers_year_tool consumers_year_tool_dom perc_dom perc_tool
save "$temp/choose_dom", replace

restore
merge m:1 indiv_id year using "$temp/choose_dom"

save "$temp/merged_data", replace

*Show Results Visually

use "$temp/merged_data", clear
 
keep year has_comparison_tool perc_dom perc_tool
duplicates drop

g pre_perc_dom_with_tool = perc_dom if has_comparison_tool == 1
g pre_perc_dom_no_tool = perc_dom if has_comparison_tool == 0

bys year: egen perc_dom_with_tool = max(pre_perc_dom_with_tool)
bys year: egen perc_dom_no_tool = max(pre_perc_dom_no_tool)

keep year perc_dom_with_tool perc_dom_no_tool perc_tool
duplicates drop

*graph bar perc_dom_no_tool perc_dom_with_tool, over(year)

graph twoway (bar perc_dom_no_tool perc_dom_with_tool year) 

g year_no_tool = year - .2
g year_tool = year + .2
*/


bys year has_comparison_tool: egen count_year_tool_dom = sum(chose_dominated)
bys year has_comparison_tool: egen count_year_tool_switch_dom = sum(chose_new_dominated)

g perc_dom_by_tool = count_year_tool_dom/ count_year_tool
g perc_dom_switch_by_tool = count_year_tool_switch_dom / count_year_tool

g pre_perc_dom_with_tool = perc_dom_by_tool if has_comparison_tool == 1
bys year: egen perc_dom_with_tool = max(pre_perc_dom_with_tool)
drop pre_perc_dom_with_tool

g pre_perc_dom_no_tool = perc_dom_by_tool if has_comparison_tool == 0
bys year: egen perc_dom_no_tool = max(pre_perc_dom_no_tool)
drop pre_perc_dom_no_tool


g year_no_tool = year - .2
g year_tool = year + .2

graph twoway (bar perc_dom_no_tool year_no_tool, barw(.4)) (bar perc_dom_with_tool year_tool, barw(.4)) ///
			(line perc_tool year)

g pre_perc_dom_switch_with_tool = perc_dom_switch_by_tool if has_comparison_tool == 1
bys year: egen perc_dom_switch_with_tool = max(pre_perc_dom_switch_with_tool)
drop pre_perc_dom_switch_with_tool

g pre_perc_dom_switch_no_tool = perc_dom_switch_by_tool if has_comparison_tool == 0
bys year: egen perc_dom_switch_no_tool = max(pre_perc_dom_switch_no_tool)
drop pre_perc_dom_switch_no_tool

graph twoway (bar perc_dom_switch_no_tool year_no_tool, barw(.4)) (bar perc_dom_switch_with_tool year_tool, barw(.4)) ///
			(line perc_tool year)

*Percent Of Switchers Who Had Dominated Plan
xtset indiv_id year
g had_dominated = L1.chose_dominated

bys year: egen count_switched = sum(switch_plan)
bys year: egen count_switched_dom = sum(switch_plan * had_dominated)

g perc_switch_dominated = count_switched_dom / count_switched

graph twoway (bar perc_switch_dominated year, barw(.4))

bys year has_comparison_tool: egen count_switched_dom_by_tool = sum(switch_plan * had_dominated)
g perc_switched_dom_by_tool = count_switched_dom_by_tool / count_year_tool

g pre_perc_switched_dom_with_tool = perc_switched_dom_by_tool if has_comparison_tool == 1
bys year: egen perc_switched_dom_with_tool = max(pre_perc_switched_dom_with_tool)
drop pre_perc_switched_dom_with_tool

g pre_perc_switched_dom_no_tool = perc_switched_dom_by_tool if has_comparison_tool == 0
bys year: egen perc_switched_dom_no_tool = max(pre_perc_switched_dom_no_tool)
drop pre_perc_switched_dom_no_tool

graph twoway (bar perc_switched_dom_no_tool year_no_tool, barw(.4)) (bar perc_switched_dom_with_tool year_tool, barw(.4)) ///
			(line perc_tool year)

			
/* Direct Inertia Graph: Of Those Who Have Dominated, How Many Had Same Plan Last Year */





