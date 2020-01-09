function [mindist] = mindistfunc(beta,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_trans_probs_in_in,mat_trans_probs_in_out,mat_trans_probs_out_in,mat_trans_probs_out_out,trunc_periods,sim_num,mat_trans_counts_in_in,mat_trans_counts_in_out,mat_trans_counts_out_in,mat_trans_counts_out_out,mat_probs_sims);
%1

%theta = [-1.5 .15 .5]
vals_for_probs = valsimfunc(beta,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_trans_probs_in_in,mat_trans_probs_in_out,mat_trans_probs_out_in,mat_trans_probs_out_out,trunc_periods,sim_num,mat_probs_sims);

%4

dist = 0;

iter = 0;

for a = 1:5;
    
    %iter = iter + 1
    
    prob_model_in_in = exp(vals_for_probs(a,2,2) ) / ( exp(vals_for_probs(a,2,2)) + exp(vals_for_probs(a,2,1)) );
    prob_model_out_in = exp(vals_for_probs(a,1,2) ) / ( exp(vals_for_probs(a,1,2)) + exp(vals_for_probs(a,1,1)) );
    prob_in_in_diff =  prob_model_in_in - ...
    ( sum(mat_trans_counts_in_in(a,:) ) / ...
    ( sum(mat_trans_counts_in_in(a,:) ) + sum(mat_trans_counts_in_out(a,:) ) ) )  ; 
    prob_out_in_diff = prob_model_out_in  - ...
     ( sum(mat_trans_counts_out_in(a,:) ) / ...
     ( sum(mat_trans_counts_out_in(a,:) ) + sum(mat_trans_counts_out_out(a,:) ) ) ) ;   
 
    dist = dist + sqrt(prob_in_in_diff ^2) + sqrt(prob_out_in_diff ^ 2);
    %dist
end;


%dist
theta

mindist =  dist;

end