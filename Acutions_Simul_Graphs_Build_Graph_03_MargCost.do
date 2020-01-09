
/* Created by RM on 2019.05.02
for analysis of simulations related to auction project
Graphing Percent Allocated to Lowest Marginal Cost Producer
*/

global input "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp"
global temp "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Research Proposal/Temp"
global output "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Research Proposal/Auctions/Output"


clear
set more off

use "$temp/stacked_bids_tracker", clear

g obs = [_n]

bys simul: egen min_obs = min(obs)

g bidder_counter = obs - min_obs + 1

drop if bidder_counter == 16


reshape long v, i(obs) j(period)

drop obs min_obs

rename v bid

bys simul period: egen min_bid = min(bid)
g winning_bidder = bid == min_bid 

save "$temp/reshaped_bids", replace

use "$temp/stacked_margcost_tracker", clear


g obs = [_n]

bys simul: egen min_obs = min(obs)

g bidder_counter = obs - min_obs + 1

drop if bidder_counter == 16

reshape long v, i(obs) j(period)

drop obs min_obs

rename v margcost

bys simul period: egen min_margcost = min(margcost)
g lowest_margcost = margcost == min_margcost 

merge 1:1 simul period bidder_counter using "$temp/reshaped_bids"

g pre_lowest_marg_won = lowest_margcost == winning_bidder & winning_bidder > 0
g pre_near_lowest_marg_won =  winning_bidder > 0 & margcost - min_margcost < 1

bys simul period: egen lowest_marg_won = max(pre_lowest_marg_won)
bys simul period: egen near_lowest_marg_won = max(pre_near_lowest_marg_won)

keep simul period lowest_marg_won near_lowest_marg_won
duplicates drop

bys period: egen count_period_lowest_marg_won = sum(lowest_marg_won)
g perc_lowest_marg_won = count_period_lowest_marg_won / 5

bys period: egen ct_period_near_lowest_marg_won = sum(near_lowest_marg_won)
g perc_near_lowest_marg_won = ct_period_near_lowest_marg_won / 5

keep period perc_lowest_marg_won perc_near_lowest_marg_won
duplicates drop

*graph bar perc_lowest_marg_won perc_near_lowest_marg_won, over(period) xlabel(1(3)25)

g period_2 = period + .4

twoway (bar perc_lowest_marg_won period, barw(.4)) (bar perc_near_lowest_marg_won period_2, barw(.4) ///
	xlabel(1(2)25) ylabel(0(.2)1) xtitle("Period") ytitle("Percent") legend( order(1 "Percent of Simulations Won by Bidder with Lowest Marginal Cost" ///
	2 "Percent of Simulations Won by Bidder with Marginal Cost Within 1 of Lowest Marginal Cost" ) rows(2) si(vsmall) ) ///
	title("Allocative Efficiency of Auctions") ) 
graph export "$output/Allocative_Efficiency.pdf", as (pdf) replace

	
	
	
	
