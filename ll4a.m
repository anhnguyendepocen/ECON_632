function [log_like] = ll4a(x,caseid,choice,price)
    % Parameter
    betabar_test = x(1,1);
    betavar_test = x(1,2);
    xi_test = [x(1,3) x(1,4) 0];
    
    prod_fe_test = repmat(xi_test',sum(choice),1);
   
    %Find price chosen for use in log likelihood
    price_chosen = price(choice == 1);
    fe_chosen = prod_fe_test(choice == 1);
    
   %integrate 
   Fnormexp = @(y) ( exp(y * price_chosen + fe_chosen) ./ ( accumarray(caseid,exp(y * price + prod_fe_test)) ) ) .* exp(-(y-betabar_test) .^ 2 ./ (2*betavar_test));
   integral_choice = quadv(Fnormexp,betabar_test - (5 * betavar_test), betabar_test + (5 * betavar_test));

   %find log likelihood
   log_like_per_sit = log(integral_choice) - log(sqrt(2*pi*betavar_test));
   log_like = -sum(log_like_per_sit);
    
    
end