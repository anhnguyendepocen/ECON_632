%%
%created by RM on 2020.02.27 
%to calculate ssr for
%sota of value function

function [sotassr] = sotaparams(theta0,theta1,delta,params,grid,grid_interact,state_probs)

beta = .95;

%%
%calc flow utility and contvalue

flow_utility = 0 * grid;
valfcurr = grid_interact * params;
valfnext = 0 * grid(:,1);


%%

flowutility = zeros(rows(grid),2);
flowutility(:,2) = theta0 .* ones(10,1) + theta1 .* grid(:,1) + ...
                    (-1) .* delta .* (ones(10,1) - grid(:,2));

%%

contval = grid_interact * params;
contval_prime_expand = 0 * grid;
state_probs_expand = repmat(state_probs,2,1);


%%
for dprime = 1:5
    contval_prime = contval(grid(:,1) == dprime,1);
    contval_prime_expand(:,1) = contval_prime(1,1) .* ones(1,10);
    contval_prime_expand(:,2) = contval_prime(2,1) .* ones(1,10);
    val_next = flowutility + beta .* contval_prime_expand;
    max_val = max(val_next')';
    max_val_expand = max_val .* ones(10,2);
    l_sum_exp = log(sum(exp(val_next),2));
    valfnext = valfnext + l_sum_exp .* state_probs_expand(:,dprime);
end

%%
   

resid = valfnext - valfcurr;

sotassr = resid' * resid;

end
        
    

        