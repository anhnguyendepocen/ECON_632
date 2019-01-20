%%Created by RM on 2019.01.19 for ECON 632 PS 1


function loglikelihood_q3 = ll3(betahat,xi1hat,xi2hat,xi3hat);

    prod_fe = [xi1hat, xi2hat, xi3hat]';
    fe_of_choice = choice_ind * prod_fe;
    
    fe_rep = repmat(prod_fe',rows(choice_ind),1);
    beta_price_plus_fe = betahat * p + fe_rep;
    exp_beta_price_plus_fe = = arrayfun(@(x) exp((x)),beta_price_plus_fe);
    sum_exps = exp_beta_price_plus_fe * ones(3,1);
    log_sum_exp = arrayfun(@(x) log((x)),sum_exps);
    
    ll_per_obs =  betahat * p_of_choice + fe_of_choice - log_sum_exp;
    ll_sum = sum(ll_per_obs,1);
    loglikelihood_q3 = -ll_sum;

end;