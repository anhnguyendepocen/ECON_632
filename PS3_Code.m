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

rows_data = rows(data);
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

for i = 1:rows(pre_state_probs);
    inv_row_sums(i,1) = 1/row_sums(1,i);
end;

initial_state_probs = inv_row_sums * ones(1,5)  ;

state_probs = initial_state_probs .* pre_state_probs;

%%
%For NFXP Algo, compute value function given parameters
%Use expected value function rather than actual value function

param = [ 1 2 1];

%tol = 1^(-14);
tol = 10^(-14);
error = 100;

val = zeros(10,1) + 1;
demand_state = repmat([ 1 2 3 4 5]',2);
demand_state = demand_state(:,1);
operate_state = repmat([ 0 1]',5);
operate_state = operate_state(:,1);
val_next = zeros(10,1);

loop_counter = 0;

while error > tol;  
    loop_counter = loop_counter + 1;

    for i = 1: rows(val);
         current_demand_state = demand_state(i,1);
         transition_probs = state_probs(current_demand_state,:);

         continuation_vals_i0 = beta * val(operate_state == 0);
         continuation_vals_i1 = beta * val(operate_state == 1);

         flow_utility = param(1,1) + param(1,2) * current_demand_state - (1-operate_state(i,1)) * param(1,3);
         
         logit_incl_vals = log(exp(continuation_vals_i0) + exp(flow_utility + continuation_vals_i1));
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
        
        j = i -1;
        last_operate_choice = data(j,2);
        
        mle_data(row_counter,:) = [demand_state  operate_choice last_operate_choice];
        
        row_counter = row_counter + 1;

    end;
    
    pre_market = market;
    
end;


%%
%RUN MLE!!!

x0 = [1 1 1];
ln_x0 = log(x0);

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-14,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',200000,'MaxIter',1000); 
[estimate_entryexit] = fminunc(@(x)llnfxp(x,mle_data,beta,state_probs),ln_x0,options);

estimates = log(estimate_entryexit)
