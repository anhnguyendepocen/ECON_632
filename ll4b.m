function [log_like] = ll4b(x0,caseid,choice,price,qp,qw)
    % Parameter
    betabar_test = x0(1,1);
    betavar_test = x0(1,2);
    xi_test = [x0(1,3) x0(1,4) x0(1,5)];
    
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
   choice_MC = choice_numerator ./ choice_denominator;
   
   %sum_choice_MC = sum(choice_MC')' ./ size(qp_test,2);
   sum_choice_MC = sum((choice_MC .* qw)')';
   
   %find log likelihood
   log_like_per_sit = log(sum_choice_MC);
   log_like = -sum(log_like_per_sit);
    
end