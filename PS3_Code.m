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
%For NFXP Algo, compute value function given parameters
%Use expected value function rather than actual value function

param = [1 2 1];

%tol = 1^(-14);
tol = 10^(-16);
error = 100;

val = zeros(10,1) ;
demand_state = repmat([ 1 2 3 4 5]',2);
demand_state = demand_state(:,1);
operate_state = [0 0 0 0 0 1 1 1 1 1]';
operate_state = operate_state(:,1);
val_next = zeros(10,1);

loop_counter = 0;

while error > tol;  
    loop_counter = loop_counter + 1;
    loop_counter

    for i = 1: length(val);
         current_demand_state = demand_state(i,1);
         transition_probs = state_probs(current_demand_state,:);

         continuation_vals_i0 = beta * val(operate_state == 0);
         continuation_vals_i1 = beta * val(operate_state == 1);
         max_val = beta * max(val);

         flow_utility = param(1,1) + param(1,2) * current_demand_state - (1-operate_state(i,1)) * param(1,3);
         
         logit_incl_vals =  max_val + log(  exp(continuation_vals_i0 - max_val ) + exp(flow_utility + continuation_vals_i1 - max_val) );
         %logit_incl_vals_ugly = log(  exp(continuation_vals_i0) + exp(flow_utility + continuation_vals_i1) );
         val_next_i = transition_probs * logit_incl_vals;
         val_next(i,1) = val_next_i;
          
    end;
    
    error = max(abs(val - val_next));
    
    val = val_next;

end;

val_info = horzcat(demand_state,operate_state,val_next);


%%
%Now Put Into a MLE Routine: First, prepare data

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



delta_list = (0:.01:2)';
graph_data = zeros(rows(delta_list),3);
theta0 = 1;
theta1 = 1;

%Need to find value function for each parameter value,  write as function
%and then go from there

%find distribution of states in the data
dist_states = row_sums / rows(data);

%delta_list = [.1 .2 .3 .4 .5]';

for i = 1:rows(delta_list);

    delta_use = delta_list(i,1);
    vals = value(theta0,theta1,delta_use,state_probs);
    %vals = value(theta0,theta1,.1,state_probs);
    max_val = max(vals);
    vals_at_i0 = vals(operate_state == 0);
    vals_at_i1 = vals(operate_state == 1);

    prob_i0_delta = 0;
    prob_i0_state = zeros(5,2);
    
    for j = 1: rows(vals_at_i0);
       prob_i0_temp_num  = beta * max_val + exp(beta * vals_at_i0(j,1) - beta * max_val);
       prob_i0_temp_den_from_0  = beta * max_val + exp(theta0 + j * theta1 - delta_use + beta * vals_at_i1(j,1) - beta * max_val);
       prob_i0_temp_den_from_1  = beta * max_val + exp(theta0 + j * theta1 + beta * vals_at_i1(j,1) - beta * max_val);
       prob_i0_state(j,1) = prob_i0_temp_num / prob_i0_temp_den_from_0;
       prob_i0_state(j,2) = prob_i0_temp_num / prob_i0_temp_den_from_1;
    end;
    
    prob_i0_avg_state = dist_states * prob_i0_state;
    graph_data(i,1) = 1 - prob_i0_avg_state(1,1);
    graph_data(i,2) = 1 - prob_i0_avg_state(1,2);
    graph_data(i,3) = sum(data(:,2))/rows(data) * graph_data(i,2) + (1- sum(data(:,2))/rows(data)) * graph_data(i,1); 
    
%Now just use pi0 which is ratio and then graph
end;

%%
%Export to Stata for better graphing
export_graph_data = horzcat(delta_list,graph_data);
csvwrite('/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp/ps3_graph_data.csv',export_graph_data);


