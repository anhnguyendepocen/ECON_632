%Created by RM on 2019.04.05 for ECON 632 
%PS 3: Dynamic Discrete Choice Estimation

%%
%Import Data

data = csvread('/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/ProblemSetData/firm_entry.csv',1,0);
%Cols are j, i, x
%Assume ordered temporally within market
beta = .95;

%%
%Compute transition probabilities of exogenous observed state variable
%Assume same for all markets

rows_data = length(data);
pre_state_probs = zeros(5,5);

pre_market = data(1,1);
pre_x = data(1,3);

for i = 2:rows_data;
    market = data(i,1);
    x = data(i,3);
    
    if pre_market == market;
        pre_state_probs(pre_x,x) =  pre_state_probs(pre_x,x) + 1;
    end;
    
    pre_market = market;
    pre_x = x;
      

end;

row_sums = sum(pre_state_probs');
inv_row_sums = zeros(rows(pre_state_probs),1);

for i = 1:length(pre_state_probs);
    inv_row_sums(i,1) = 1/row_sums(1,i);
end;

initial_state_probs = inv_row_sums * ones(1,5)  ;

state_probs = initial_state_probs .* pre_state_probs;


%%
%Prepare Data for use in MLE

%Create New Dataset For MLE with exogenous state, operate decision, and
%lag, operate decision

mle_data = zeros(rows_data-50,3);

pre_market = data(1,1);
pre_x = data(1,3);
row_counter = 1;

for i = 2:rows_data;
    
    market = data(i,1);
    
    if market == pre_market;
        demand_state = data(i,3);
        
        operate_choice = data(i,2);
        
        j = i - 1;
        last_operate_choice = data(j,2);
        
        mle_data(row_counter,:) = [demand_state  operate_choice last_operate_choice];
        
        row_counter = row_counter + 1;

    end;
    
    pre_market = market;
    
end;


%%
%RUN MLE!!!

x0 = [1 1 1];

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',200000,'MaxIter',1000); 
[estimate_entryexit,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x)llnfxp(x,mle_data,beta,state_probs),x0,options);

inv_Hessian = inv(Hessian);
std = sqrt(diag(inv_Hessian));

%%
%Chart of Fraction of Periods Operating Given Delta

%One as in market prob given not in market (entry prob)
%One as in market prob given in market (stay prob)
%One as weighted prob based on actual distribution of in/out in data in 
%first period

delta_list = (-5:.01:5)';
graph_data = zeros(length(delta_list),3);
theta0 = estimate_entryexit(1,1);
theta1 = estimate_entryexit(1,2);

%Need to find value function for each parameter value,  write as function
%and then go from there

%find distribution of states in the data
dist_states = row_sums / sum(row_sums);
operate_state = [0 0 0 0 0 1 1 1 1 1]';
demand_state = [1 2 3 4 5 1 2 3 4 5]';
%delta_list = [.1 .2 .3 .4 .5]';

for i = 1:length(delta_list);

    delta_use = delta_list(i,1);
    vals = value(theta0,theta1,delta_use,state_probs);
    vals_at_i0 = vals(operate_state == 0);
    vals_at_i1 = vals(operate_state == 1);

    prob_i0_by_state_num = exp(beta * vals_at_i0);
    prob_i0_by_state_denom_from1 = prob_i0_by_state_num + exp( theta0  + demand_state(1:5,1) * theta1 + beta * vals_at_i1);
    prob_i0_by_state_denom_from0 = prob_i0_by_state_num + exp( theta0  + demand_state(1:5,1) * theta1 + beta * vals_at_i1 - delta_use);

    prob_i0_by_state_from1 = prob_i0_by_state_num ./ prob_i0_by_state_denom_from1;
    prob_i0_by_state_from0 = prob_i0_by_state_num ./ prob_i0_by_state_denom_from0;

    transitions_to0_from_1 = prob_i0_by_state_from1 .* state_probs;
    transitions_to1_from_1 = (1 - prob_i0_by_state_from1) .* state_probs;
    transitions_to0_from_0 = prob_i0_by_state_from0 .* state_probs;
    transitions_to1_from_0 = (1 - prob_i0_by_state_from0) .* state_probs;
    
    %Now Start With All Firms At Zero
    iter_to0 = dist_states' .* transitions_to0_from_0;
    iter_to1 = dist_states' .*  transitions_to1_from_0;
    next_to0 = sum(iter_to0);
    next_to1 = sum(iter_to1);
   
            for j = 1 : 1000;
                iter_to0 = next_to0' .* transitions_to0_from_0 + next_to1' .* transitions_to0_from_1;
                iter_to1 = next_to0' .* transitions_to1_from_0 + next_to1' .* transitions_to1_from_1;
                next_to0 = sum(iter_to0);
                next_to1 = sum(iter_to1);
            end;
            
     graph_data(i,1) = sum(next_to1);
     
     %Now Start With All Firms At One
    iter_to0 = dist_states' .* transitions_to0_from_1;
    iter_to1 = dist_states' .*  transitions_to1_from_1;
    next_to0 = sum(iter_to0);
    next_to1 = sum(iter_to1);
   
            for j = 1 : 1000;
                iter_to0 = next_to0' .* transitions_to0_from_0 + next_to1' .* transitions_to0_from_1;
                iter_to1 = next_to0' .* transitions_to1_from_0 + next_to1' .* transitions_to1_from_1;
                next_to0 = sum(iter_to0);
                next_to1 = sum(iter_to1);
            end;
            
      graph_data(i,2) = sum(next_to1);
      
      graph_data(i,3) = abs(graph_data(i,2) - graph_data(i,1));
 
    
end;

%%
%Export to Stata for better graphing

export_graph_data = horzcat(delta_list,graph_data);
csvwrite('/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp/ps3_graph_data.csv',export_graph_data);

