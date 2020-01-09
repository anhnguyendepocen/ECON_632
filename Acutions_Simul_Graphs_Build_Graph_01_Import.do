
/* Created by RM on 2019.05.02
for analysis of simulations related to auction project
Import belief, MC and bids data
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




