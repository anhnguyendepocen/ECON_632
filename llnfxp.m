function [log_like] = llnfxp(x,mle_data,beta,state_probs)
    % Parameters
    %x = [ 1 2 1];
    %x = ln_x0;    
    
    theta_test = [exp(x(1,1)) exp(x(1,2)) exp(x(1,3))];
    
    %%
    
    
    %DO FIXED POINT
        tol = 10^(-14);
        error = 100;

        val = zeros(10,1) + 1;
        demand_state = repmat([ 1 2 3 4 5]',2);
        demand_state = demand_state(:,1);
        operate_state = repmat([ 0 1]',5);
        operate_state = operate_state(:,1);
        val_next = zeros(10,1);

        %loop_counter = 0;

        while error > tol;  
            %loop_counter = loop_counter + 1;

            for i = 1: rows(val);
                 current_demand_state = demand_state(i,1);
                 transition_probs = state_probs(current_demand_state,:);

                 continuation_vals_i0 = beta * val(operate_state == 0);
                 continuation_vals_i1 = beta * val(operate_state == 1);

                 flow_utility = theta_test(1,1) + theta_test(1,2) * current_demand_state - (1-operate_state(i,1)) * theta_test(1,3);

                 logit_incl_vals = log(exp(continuation_vals_i0) + exp(flow_utility + continuation_vals_i1));
                 val_next_i = transition_probs * logit_incl_vals;
                 val_next(i,1) = val_next_i;
          
             end;
    
         error = max(abs(val - val_next));

         val = val_next;

        end;
 
        val_info = horzcat(demand_state,operate_state,val_next);

    
    % Choice Probabilities
    prob_i0 = zeros(rows(mle_data),1);
    pre_log_like = zeros(rows(mle_data),1);
    for i = 1: rows(mle_data);
        demand_state_use = mle_data(i,1);
        last_operate = mle_data(i,3);
        val_i0 = sum( val .* (demand_state == demand_state_use) .* (operate_state == 0) );
        val_i1 = sum( val .* (demand_state == demand_state_use) .* (operate_state == 1) );

        prob_i0_num = exp(beta * val_i0);
        prob_i0_den = prob_i0_num + exp(theta_test(1,1) + demand_state_use * theta_test(1,2) - (1 - last_operate) * theta_test(1,3) + beta * val_i1);
        
        prob_i0(i,1) = prob_i0_num / prob_i0_den;
        pre_log_like(i,1) = prob_i0(i,1) * (1 - mle_data(i,2)) + (1-prob_i0(i,1)) * mle_data(i,2);
        
    end;

    % Log likelihood
    %V_exp = exp(V);
    %V_chosen = V_exp(choice==1);
    %V_sum = accumarray(caseid,V_exp);
    %like_vec = (V_chosen./V_sum);
    log_like = -sum(pre_log_like);
end