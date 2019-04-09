function [log_like] = llnfxp(x,mle_data,beta,state_probs)
    % Parameters
    %x = [ 1 2 1];
    %x = ln_x0;    
    
    %theta_test = [exp(x(1,1)) exp(x(1,2)) exp(x(1,3))];
    theta_test = [x(1,1) x(1,2) x(1,3)];

    
    %%
   
    val_info = value(theta_test(1,1),theta_test(1,2),theta_test(1,3),state_probs);
    val = val_info(:,3);
    max_val = max(val);
    beta_max_val = beta * max_val;
        
    
    %% Choice Probabilities
    prob_i0 = zeros(rows(mle_data),1);
    pre_log_like = zeros(rows(mle_data),1);
    for i = 1: rows(mle_data);
        demand_state_use = mle_data(i,1);
        last_operate = mle_data(i,3);
        val_i0 = sum( val .* (val_info(:,1) == demand_state_use) .* (val_info(:,2) == 0) );
        val_i1 = sum( val .* (val_info(:,1) == demand_state_use) .* (val_info(:,2) == 1) );

        prob_i0_num = beta_max_val + exp(beta * val_i0 - beta_max_val);
        prob_i0_den = prob_i0_num + beta_max_val + exp(theta_test(1,1) + demand_state_use * theta_test(1,2) - (1 - last_operate) * theta_test(1,3) + beta * val_i1 - beta_max_val);
        
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