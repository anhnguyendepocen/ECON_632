/* Created by RM on 4.10.19 
For ECON 632 graphing */

clear
set more off

global output "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Output"

import delim "/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp/ps3_graph_data.csv", delim(",")

rename v1 delta
rename v2 prob_choose_in_from_out
rename v3 prob_choose_in_from_in
rename v4 prob_choose_in_diff

su prob_choose_in_diff, d

graph twoway (scatter prob_choose_in_from_out delta, msize(vsmall) xline(0.5446)), xtitle( {&delta} ) ytitle("Fraction of Periods") ///
				title("Fraction of Periods in Market") ///
				title("as a Function of {&delta}", suffix) ///
				note("Source:  firm_entry.csv", si(vsmall) )  ///
				caption("Estimated probabilities use value function with nested fixed point estimates for {&beta}{sub:0} and {&beta}{sub:1}, the empirical distribution of demand states," "and a discount rate of .95." "Vertical line denotes value of estimated {&delta}.", si(vsmall) ) 
	
	
graph export "$output/ProbabilityInMarket_Delta.pdf", as (pdf) replace
