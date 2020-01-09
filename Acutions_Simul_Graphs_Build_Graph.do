
/* Created by RM on 2019.05.02
for analysis of simulations related to auction project
Graphing belief convergence, RMSE, and relationship between marginal cost and winning
*/

global input "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp"
global temp "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Research Proposal/Temp"


clear
set more off



forv i = 1(1)5 {

import delimited "$input/belief_tracker_k_`i'.csv", clear
g simul = `i'
g gamma = 70

save "$temp/belief_tracker_`i'", replace

import delimited "$input/margcost_tracker_`i'.csv", clear
g simul = `i'

save "$temp/margcost_tracker_`i'", replace


import delimited "$input/bids_tracker_`i'.csv", clear
g simul = `i'

save "$temp/bids_tracker_`i'", replace


if `i' < 2 {
	use "$temp/belief_tracker_`i'", clear
	save "$temp/stacked_belief_tracker", replace
	
	use "$temp/margcost_tracker_`i'", clear
	save "$temp/stacked_margcost_tracker", replace
	
	use "$temp/bids_tracker_`i'", clear
	save "$temp/stacked_bids_tracker", replace	

}

if `i' > 1 {
	use "$temp/belief_tracker_`i'", clear
	append using "$temp/stacked_belief_tracker"
	save "$temp/stacked_belief_tracker", replace

	use "$temp/margcost_tracker_`i'", clear
	append using "$temp/stacked_margcost_tracker"
	save "$temp/stacked_margcost_tracker", replace

	use "$temp/bids_tracker_`i'", clear
	append using "$temp/stacked_bids_tracker"
	save "$temp/stacked_bids_tracker", replace	
	
}

}


/* Make Belief Graphs */

use "$temp/stacked_belief_tracker", clear

gsort simul v1

g obs = [_n]

bys simul: egen min_obs = min(obs)

g orig_belief_order = obs - min_obs + 1

drop min_obs

reshape long v, i(obs) j(period)

drop obs

rename v belief_k

save "$temp/reshaped_belief_tracker", replace

bys period orig_belief_order: egen avg_belief_k_by_orig_order = mean(belief_k)

g ones = 1

bys simul period: egen count_bidders_period = sum(ones)

drop ones 

g squared_error = (gamma - belief_k)^2 / count_bidders_period
bys simul period: egen mean_se = sum(squared_error)
g rmse_period_simul = sqrt(mean_se)

keep simul period rmse_period_simul
duplicates drop

forv s=1(1)5 {
	
	g pre_rmse_`s' = rmse_period_simul if simul == `s'
	bys period: egen rmse_`s' = max(pre_rmse_`s')
	drop pre_rmse_`s'
	
}

keep period rmse*

save "$temp/rmse_data", replace

twoway (connected rmse_1 period) (connected rmse_2 period) (connected rmse_3 period) (connected rmse_4 period) (connected rmse_5 period)


use "$temp/reshaped_belief_tracker", clear


forv bidder=1(1)15 {
	
	g pre_belief_`bidder' = belief_k if orig_belief_order == `bidder'
	
	bys simul period: egen belief_`bidder' = max(pre_belief_`bidder')
	
	drop pre_belief_`bidder'
	
}
	


