function [log_like] = ll4aalt(x,caseid,choice,price)
    % Parameter
    betabar_test = x(1,1);
    betavar_test = x(1,2);
    xi_test = [x(1,3) x(1,4) 0];
    
    prod_fe_test = repmat(xi_test',sum(choice),1);
   
    %Find price chosen for use in log likelihood
    price_chosen = price(choice == 1);
    fe_chosen = prod_fe_test(choice == 1);
    
   %integrate 
    function [val] = fnormexp(y)
      val =   exp(y * price_chosen + fe_chosen) ./ ...
          ( accumarray(caseid,exp(y * price + prod_fe_test)) )   ...
          .* exp(-(y-betabar_test) .^ 2 ./ (2*betavar_test));
      val(isnan(val)) = 0; 
        
    end;
   integral_choice = integral(@(y) fnormexp(y),-Inf,Inf,'ArrayValued',true,'RelTol',0,'AbsTol',1e-14);
   
   
   %find log likelihood
   log_like_per_sit = log(integral_choice) - log(sqrt(2*pi*betavar_test));
   log_like_per_sit(isnan(log_like_per_sit)) = 0;
   log_like = -sum(log_like_per_sit);

    
    
end