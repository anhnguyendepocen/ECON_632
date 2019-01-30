function [log_like] = ll4b(x,caseid,choice,price,qp,qw)
    % Parameter
    betabar_test = x(1,1);
    betavar_test = x(1,2);
    xi_test = [x(1,3) x(1,4) 0];
    
    prod_fe_test = repmat(xi_test',sum(choice),1);
   
    %Find price chosen for use in log likelihood
    price_chosen = price(choice == 1);
    fe_chosen = prod_fe_test(choice == 1);
    
   %integrate: Monte Carlo
   qp_test = qp * sqrt(betavar_test) + betabar_test;
   %beta_MC = random('norm', betabar_test, betavar_test,[1,500]);
   
   %find value for each value of beta MC
   choice_numerator = exp(qp_test .* price_chosen + fe_chosen) ;
   for_choice_denominator = exp(qp_test .* price + prod_fe_test);
   [xx, yy] = ndgrid(caseid,1:size(qp_test,2));
   choice_denominator = accumarray([xx(:) yy(:)],for_choice_denominator(:));
   choice_quad = choice_numerator ./ choice_denominator;
   
   %sum_choice_MC = sum(choice_MC')' ./ size(qp_test,2);
   sum_choice_quad = sum((choice_quad .* qw)')';
   
   %find log likelihood
   log_like_per_sit = log(sum_choice_quad);
   log_like = -sum(log_like_per_sit);
    
end