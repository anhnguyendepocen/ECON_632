function [log_like] = llplan(params,caseid,choice,prem_income,qual_risk,cov_risk,prob_vars,plan_vars)
 
    %Recode Input Variables
    alpha = params(1,1:4);
    beta = params(1,5:8);
    gamma = params(1,9:12);
    delta = params(1,13:15);
    psi = params(1,16:26);
    mu = params(1,27);
    
    tool = prob_vars(:,1);
    num_plans = prob_vars(:,2);
    risk = prob_vars(:,3);
    age = prob_vars(:,4);
    income = prob_vars(:,5);
    years_enrolled = prob_vars(:,6);
    chose_min = prob_vars(:,7);
    first_year = prob_vars(:,8);
    plan_goes_away = prob_vars(:,9);
    switch_plan = prob_vars(:,10);
    
    coverage = plan_vars(:,1);
    quality = plan_vars(:,2);
    same_plan = plan_vars(:,3);
    
    % Representative utility (without error)
    V = prem_income * alpha' + qual_risk * beta' + cov_risk * gamma';
    V = V + delta(1,1) * coverage + delta(1,2) * quality + delta(1,3) * same_plan;
    
    %Search Probability
    lower_bound_cdf = psi(1,1) * tool + psi(1,2) * num_plans + psi(1,3) * num_plans .^2;
    lower_bound_cdf = lower_bound_cdf + psi(1,4) * risk + psi(1,5) * age;
    lower_bound_cdf = lower_bound_cdf + psi(1,6) * income + psi(1,7) * years_enrolled;
    lower_bound_cdf = lower_bound_cdf + psi(1,8) * chose_min ;
    lower_bound_cdf = lower_bound_cdf + psi(1,9) * tool .* num_plans ;
    lower_bound_cdf = lower_bound_cdf + psi(1,10) * tool .* risk ;
    lower_bound_cdf = lower_bound_cdf + psi(1,11) * tool .* age ;

    prob_active_choice = 1-cdf('Normal',-1 * lower_bound_cdf,mu,1);
    prob_active_choice_per_sit = accumarray(caseid,prob_active_choice,[],@max);
    prob_active_choice_per_sit = prob_active_choice_per_sit(unique(caseid));
    
    new = max(horzcat(first_year,plan_goes_away),[],2);
    new_per_sit = accumarray(caseid,new,[],@max);
    new_per_sit = new_per_sit(unique(caseid));
    not_new_per_sit = 1 - new_per_sit;
    
    switch_plan_per_sit = accumarray(caseid,switch_plan,[],@max);
    switch_plan_per_sit = switch_plan_per_sit(unique(caseid));
    
    % Log likelihood
    V_exp = exp(V);
    V_chosen = V_exp(choice==1);
    V_sum = accumarray(caseid,V_exp);
    V_sum_per_sit = V_sum(unique(caseid));
    
    prob_choose_j = (V_chosen./V_sum_per_sit);
    like_vec = prob_choose_j .* new_per_sit + not_new_per_sit .* ( prob_active_choice_per_sit .*  prob_choose_j);
    like_vec = like_vec + not_new_per_sit .* ( (1-switch_plan_per_sit) .* (1 - prob_active_choice_per_sit) );
    log_like = -sum(log(like_vec));

end

