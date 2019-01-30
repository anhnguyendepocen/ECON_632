function [log_like] = ll3(x,caseid,choice,price)
    % Parameter
    xi_test = [x(1,2) x(1,3) 0];
    prod_fe_test = repmat(xi_test',sum(choice),1);
    
    % Representative utility (without error)
    V = x(1,1)*price + prod_fe_test ;

    % Log likelihood
    V_exp = exp(V);
    V_chosen = V_exp(choice==1);
    V_sum = accumarray(caseid,V_exp);
    like_vec = (V_chosen./V_sum);
    log_like = -sum(log(like_vec));
end