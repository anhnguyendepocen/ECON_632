function [log_like] = llplan(params,caseid,choice,prem_income,qual_risk,cov_risk,plan_dum,prob_vars,plan_vars)
    
    %Recode Input Variables
    alpha = params(1,1:4);
    beta = params(1,5:8);
    gamma = params(1,9:12);
    delta = params(1,13:14);
    xi = params(1,15:113);
    psi = params(1,114:124);
    mu = params(1,125);
    sigma2 = params(1,126);

    tool = prob_vars(:,1);
    num_plans = prob_vars(:,2);
    risk = prob_vars(:,3);
    age = prob_vars(:,4);
    income = prob_vars(:,5);
    years_enrolled = prob_vars(:,6);
    chose_min = prob_vars(:,7);
    first_year = prob_vars(:,8);
    plan_goes_away = prob_vars(:,9);
    
    coverage = plan_vars(:,1);
    quality = plan_vars(:,2);
    
    % Representative utility (without error)
    V = prem_income * alpha' + qual_risk * beta' + cov_risk * gamma' + plan_dum * xi';
    V = V + delta(1,1) * coverage + delta(1,2) * quality;
    
    %Search Probability
    lower_bound_cdf = psi(1,1) * tool + psi(1,2) * num_plans + psi(1,3) * num_plans .^2;
    lower_bound_cdf = lower_bound_cdf + psi(1,4) * risk + psi(1,5) * age;
    lower_bound_cdf = lower_bound_cdf + psi(1,6) * income + psi(1,7) * years_enrolled;
    lower_bound_cdf = lower_bound_cdf + psi(1,8) * chose_min ;
    lower_bound_cdf = lower_bound_cdf + psi(1,9) * tool .* num_plans ;
    lower_bound_cdf = lower_bound_cdf + psi(1,10) * tool .* risk ;
    lower_bound_cdf = lower_bound_cdf + psi(1,11) * tool .* age ;

    active_choice = horzcat(first_year, plan_goes_away, 1-cdf('Normal',-1 * lower_bound_cdf,mu,sigma2));
    prob_active_choice = max(active_choice,[],2);
    pre_prob_active_choice_per_sit = accumarray(caseid,prob_active_choice,[],@max);
    prob_active_choice_per_sit = pre_prob_active_choice_per_sit(unique(caseid),:);
    
    
    % Log likelihood
    V_exp = exp(V);
    V_chosen = V_exp(choice==1);
    V_sum = accumarray(caseid,V_exp);
    V_sum_per_sit = V_sum(unique(caseid));
    
    like_vec = (V_chosen./V_sum_per_sit) .* prob_active_choice_per_sit + (1 - prob_active_choice_per_sit);
    log_like = -sum(log(like_vec));
end

