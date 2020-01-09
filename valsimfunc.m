function [vals_use] = valsimfunc(beta,theta,trunc_periods,state_sim,probs_sim,choice_sim,sim_num);
%2

%get params
theta1 = theta(1,1);
theta2 = theta(1,2);
delta = theta(1,3);

eulermasch = double(eulergamma);

pre_vals_use = zeros(10,2);
%rows are state, column 1 is picking out column 2 is picking in

for state = 1:10;
    for ch_ind = 1:2;
        %find utility along path for choice specific value function
        pre_demand_state = state_sim(:,:,state,ch_ind) < 6;
        demand_state = pre_demand_state .* state_sim(:,:,state,ch_ind) ... 
                      + (1 - pre_demand_state) .* ( state_sim(:,:,state,ch_ind) - 5);
        
        entry_state = pre_demand_state .* 0 ... 
            + (1 - pre_demand_state) .* 1;
        
        
        flow_utility = choice_sim(:,:,state,ch_ind) .*   ...
                    (    theta1 + theta2 .* demand_state - ...
                        (1 - entry_state) .*  delta  ...
                    );
        
        expectation_taste_utility =   eulermasch - log(probs_sim(:,:,state,ch_ind));;    
        expectation_taste_utility(1,:) = 0;
        
        u_sim = flow_utility + expectation_taste_utility;
        
        seq_for_disc = 1:1:trunc_periods;
        discounting =   (beta .^ (seq_for_disc - 1))';  
        
        u_sim_discounted = u_sim .* discounting;
        
        val_per_sim = sum(u_sim_discounted);
        val = sum(val_per_sim) / sim_num;
       
        pre_vals_use(state,ch_ind) = val;
        
    end;
    
end;

vals_use = pre_vals_use;

end


