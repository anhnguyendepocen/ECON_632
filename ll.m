function [log_like] = ll(c,choice_sit,chosen,p,x_sit,X,i_sit,N,t_sit)
    %per-period profit determined by parameter guess
    %%
    market_id = data(:,1);
    i = data(:,2);
    x = data(:,3);
    K = max(market_id);
    N = size(i,1);
    x_sit = reshape(repmat(x,1,2)',N*2,1);
    choice_sit = reshape(repmat(1:N,2,1),N*2,1);
    i_chosen_sit = reshape(repmat(i,1,2)',N*2,1);
    i_sit = reshape(repmat([0;1],N,1),N*2,1);
    t_sit = reshape(repmat(1:100,2,50),N*2,1);
    chosen = (i_sit==i_chosen_sit);

    %estimate state transition probabilities
    x_next = [x(2:end);0];
    last_period = [diff(market_id);1];
    transitions = [x(last_period==0), x_next(last_period==0)];
    transition_count = accumarray(transitions,1);
    p = transition_count ./ sum(transition_count,2);
    %beta0 = c(1);
    %beta1 = c(2);
    %delta = c(3);

    beta0 = 1;
    beta1 = 1;
    delta = 1;
    X = max(x);
    pi = zeros(X,2,2); %pi(:,1,1) and pi(:,2,1) should be 0
    pi(:,1,2) = beta0+beta1*(1:X)-delta;
    pi(:,2,2) = beta0+beta1*(1:X);
    
    % Estimate value function using fixed point iteration
    % This gives us the value of being at each state x,i(-1) and choosing i
    vf = vf_iter(zeros(X,2,2),pi,p,1e-20);
    %%
    V = zeros(N*2,1);
    parfor index = (1:(N*2))
        if t_sit(index) == 1
            V(index) = vf(x_sit(index),1,i_sit(index)+1);
        else
            V(index) = vf(x_sit(index),i_sit(index-2)+1,i_sit(index)+1);
        end
    end
    
    % Log likelihood
    V_max = accumarray(choice_sit,V,[],@max);
    V_safe = V - V_max(choice_sit);
    V_exp_safe = exp(V_safe);
    V_chosen_safe = V_exp_safe(chosen==1);
    V_sum_safe=accumarray(choice_sit,V_exp_safe);
    like_vec = (V_chosen_safe./V_sum_safe);
    log_like = -sum(log(like_vec));
end