function [mindist] = mindistfunc(beta,theta,trunc_periods,state_sim,probs_sim,choice_sim,sim_num,mat_probs_in,mat_trans_probs);

%theta = [-1.5 .15 .5]
vals_for_probs = valsimfunc(beta,theta,trunc_periods,state_sim,probs_sim,choice_sim,sim_num);


%4

dist = 0;


for state = 1:10;
    
    %iter = iter + 1    
    prob_model_in = exp(vals_for_probs(state,2) ) / ( exp(vals_for_probs(state,2)) + exp(vals_for_probs(state,1)) );
    prob_data_in =  mat_probs_in(state);
    dist = dist + (prob_model_in - prob_data_in) ^2;
    %dist
end;


%dist
%theta

mindist =  sqrt(dist);



end