
function [valuemat] = check_hm_valfct_using_iter(beta,theta,mat_probs_state_ch)


%%
%Created by RM on 2020.01.06 to check value function iteration 
%as function of theta and trans probs

%%

%theta = theta_comp

%%

vals_iter = zeros(10,2) + 1;

pre_demand_state = 1:1:10;
demand_state = (pre_demand_state' < 6) .* pre_demand_state' ...
              + (pre_demand_state'> 5) .* (pre_demand_state - 5)';
out_in_state = (pre_demand_state' > 5);

tol = 10^(-14);

theta1 = theta(1,1); 
theta2 = theta(1,2);
delta = theta(1,3);

%%
%create probability transition matrix 
%noting that each state can only go to one of demand states GIVEN CHOICE
%as know what next in/out state is

mat_trans_probs_pick_in = zeros(10,10);
mat_trans_probs_pick_out = zeros(10,10);

%given chose out only can end up in states 1 - 5
mat_trans_probs_pick_out = mat_probs_state_ch(:,1:5) ... 
         ./ sum(mat_probs_state_ch(:,1:5) ,2);
        
 %given chose in only can end up in states 6 - 10
mat_trans_probs_pick_in = mat_probs_state_ch(:,6:10) ... 
            ./ sum(mat_probs_state_ch(:,6:10) ,2);
 

 flow_utility = theta1 + theta2 * demand_state ...
                    - (1 - out_in_state) * delta;
%%
%val fct iteration
dist = 100;

while dist > tol;
    
    valnext = zeros(10,2) - 1;
 
    %if current state is d = 1, out; choice is out
    %then next period's state is d = X, out, choice = Y
    
    %if pick out            
    cont_value_out = mat_trans_probs_pick_out * vals_iter(1:5,2);
    %if pick in
    cont_value_in = mat_trans_probs_pick_in * vals_iter(6:10,2);
    
    valnext = beta * horzcat(cont_value_out,cont_value_in);
    valnext(:,2) = valnext(:,2) + flow_utility;
    
    dist = max(max(abs(valnext - vals_iter)));
    
    vals_iter = valnext;
    
end;



valuemat = vals_iter;            
    
end
