function [log_like] = ll4(x0,caseid,choice,price)
    % Parameter
    xi_test = [x0(1,3) x0(1,4) x0(1,5)];
    prod_fe_test = repmat(xi_test',sum(choice),1);
    
    % Representative utility (without error)
    V = x0(1,1)*price + prod_fe_test ;

    % Log likelihood
    V_exp = exp(V);
    V_chosen = V_exp(choice==1);
    V_sum=accumarray(caseid,V_exp);
    like_vec = (V_chosen./V_sum);
    log_like = -sum(log(like_vec));
end