function [valuemat] = value(theta0,theta1,delta,state_probs)
beta = .95;

tol = 10^(-14);
error = 100;

val = zeros(10,1) + 1;
demand_state = repmat([ 1 2 3 4 5]',2);
demand_state = demand_state(:,1);
operate_state = [0 0 0 0 0 1 1 1 1 1]';
val_next = zeros(10,1);

loop_counter = 0;

while error > tol;  
    loop_counter = loop_counter + 1;

    for i = 1: length(val);
         current_demand_state = demand_state(i,1);
         transition_probs = state_probs(current_demand_state,:);

         continuation_vals_i0 = beta * val(operate_state == 0);
         continuation_vals_i1 = beta * val(operate_state == 1);
         max_val = beta * max(val);

         flow_utility = theta0 + theta1 * current_demand_state - (1-operate_state(i,1)) * delta;
         
         logit_incl_vals = max_val + log( exp(continuation_vals_i0 - max_val) + exp(flow_utility + continuation_vals_i1 - max_val) );
         %logit_incl_vals = log(  exp(continuation_vals_i0) + exp(flow_utility + continuation_vals_i1) );
         val_next_i = transition_probs * logit_incl_vals;
         val_next(i,1) = val_next_i;
          
    end;
    
    error = max(abs(val - val_next));
    
    val = val_next;

end;

valuemat = horzcat(demand_state,operate_state,val_next);

end
