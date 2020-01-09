
function [valuemat] = check_hm_valfct_using_iter(beta,theta,mat_trans_probs)


%%
%Created by RM on 2020.01.06 to check value function iteration 
%as function of theta and trans probs

%%
%theta = [1 1 1];
%theta = theta_comp

%%

%vals_iter = zeros(10,2) + 1;
vals_iter = [1 2 3 4 5 2 3 4 5 6; 1.5 2.5 3.5 4.5 5.5 2.5 3.5 4.5 5.5 6.5]';
%vals_iter = zeros(10,2);

pre_demand_state = 1:1:10;
demand_state = (pre_demand_state' < 6) .* pre_demand_state' ...
              + (pre_demand_state'> 5) .* (pre_demand_state - 5)';
out_in_state = (pre_demand_state' > 5);

tol = 10^(-14);

theta1 = theta(1,1); 
theta2 = theta(1,2);
delta = theta(1,3);

 flow_utility = theta1 + theta2 * demand_state ...
                    - (1 - out_in_state) * delta;
%%
%val fct iteration
dist = 100;

while dist > tol;
    
    valnext = zeros(10,2) - 1;
 
    %if current state is d = 1, out; choice is out
    %then next period's state is d = X, out, choice = Y
    
    %need to redo this
    %cont value is higher val from state
    %want \beta * max_{d' in (0,1)}E[V(state',d;d')]
    
    %cont val if choose out
    cont_val_pick_out = mat_trans_probs * vals_iter(1:5,1);
    cont_val_pick_in = mat_trans_probs * vals_iter(1:5,2);
    cont_val_out = max(cont_val_pick_out,cont_val_pick_in);
    %cont val if choose in
    cont_val_pick_out = mat_trans_probs * vals_iter(6:10,1);
    cont_val_pick_in = mat_trans_probs * vals_iter(6:10,2);
    cont_val_in = max(cont_val_pick_out,cont_val_pick_in) ;
    
    cont_val = vertcat(cont_val_out,cont_val_in);
    valnext(:,1) = beta * cont_val;
    valnext(:,2) = valnext(:,1) + flow_utility;
    
    dist = max(max(abs(valnext - vals_iter)));
    
    vals_iter = valnext;
    
end;



valuemat = vals_iter;            
    
end
