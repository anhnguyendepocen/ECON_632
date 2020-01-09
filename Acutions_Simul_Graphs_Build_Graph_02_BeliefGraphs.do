

/* Created by RM on 2019.05.02
for analysis of simulations related to auction project
Graphing belief convergence, RMSE
*/

global input "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp"
global temp "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Research Proposal/Temp"
global output "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Research Proposal/Auctions/Output"


clear
set more off


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

keep simul period rmse_period_simul gamma
duplicates drop

forv s=1(1)5 {
	
	g pre_rmse_`s' = rmse_period_simul if simul == `s'
	bys period: egen rmse_`s' = max(pre_rmse_`s')
	drop pre_rmse_`s'
	
}

keep period gamma rmse*

save "$temp/rmse_data", replace

twoway (connected rmse_1 period) (connected rmse_2 period) (connected rmse_3 period) (connected rmse_4 period) (connected rmse_5 period, ///
		title("RMSE Per Period by Simulation") ytitle("RMSE") xtitle("Period") ///
		note("Source:  Simulated Data", si(vsmall) ) legend( off )  ///
		caption("Note: Each series represents the RMSE of the difference between the true value and beliefs about the shape parameter (k) for 15 bidders.", si(vsmall) )  )
graph export "$output/RMSE.pdf", as (pdf) replace
	

twoway (connected rmse_1 period) (connected rmse_2 period) (connected rmse_3 period) (connected rmse_4 period, ///
		title("RMSE Per Period by Simulation") ytitle("RMSE") xtitle("Period") ///
		note("Source:  Simulated Data", si(vsmall) ) legend( off )  ///
		caption("Note: Each series represents the RMSE of the difference between the true value and beliefs about the shape parameter (k) for 15 bidders.  Simulation 5 omitted.", si(vsmall) )  )
graph export "$output/RMSE_no_5.pdf", as (pdf) replace
	
	
	

use "$temp/reshaped_belief_tracker", clear


forv bidder=1(1)15 {
	
	g pre_belief_`bidder' = belief_k if orig_belief_order == `bidder'
	
	bys simul period: egen belief_`bidder' = max(pre_belief_`bidder')
	
	drop pre_belief_`bidder'
	
}


forv s=1(1)5 {

	preserve
	keep if simul == `s'
		twoway (lfit gamma period) (connected belief_1 period) (connected belief_4 period) ///
		   (connected belief_8 period) (connected belief_12 period) (connected belief_15 period,  ///
		   title("Belief About Shape Parameter (k)" "by Bidder per Period in One Simulation") ytitle("Belief About Shape (k)") xtitle("Period") legend(on) ///
		   legend(order(1 "True k" 2 "Belief for Initial Lowest Belief" 3 "Belief for Initial 4th Lowest Belief"    ///
						4 "Belief for Initial Median Belief" 5 "Belief for Initial 4th Highest Belief" 6 "Belief for Initial Highest Belief") si(small) ) ///
		   	note("Source:  Simulated Data from simulation `s'", si(vsmall) )  ///
			caption("Note: Each series represents the belief about shape (k) using the order of initial beliefs.", si(vsmall) )  )
		
	graph export "$output/Sim_`s'_Beliefs.pdf", as (pdf) replace

			
	restore
		   
}


forv bidder=1(1)15 {

	bys period: egen avg_over_simul_`bidder' = mean(belief_`bidder')
	
}
	
	twoway (lfit gamma period) (connected avg_over_simul_1 period) (connected avg_over_simul_4 period) ///
		   (connected avg_over_simul_8 period) (connected avg_over_simul_12 period) (connected avg_over_simul_15 period,  ///
		   title("Average Belief About Shape Parameter (k)" "by Bidder per Period") ytitle("Belief About Shape (k)") xtitle("Period") legend(on) ///
		   legend(order(1 "True k" 2 "Belief for Initial Lowest Belief" 3 "Belief for Initial 4th Lowest Belief"    ///
						4 "Belief for Initial Median Belief" 5 "Belief for Initial 4th Highest Belief" 6 "Belief for Initial Highest Belief") si(small) ) ///
		   	note("Source:  Simulated Data", si(vsmall) )  ///
			caption("Note: Each series represents the average of the belief about shape (k) over simulations using the order of initial beliefs.", si(vsmall) )  )

			
		graph export "$output/Avg_Beliefs.pdf", as (pdf) replace
		     
			
