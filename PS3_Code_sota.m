%%
%Created by RM on 2020.02.27
%to redo PS3 using SOTA approximation

%NOT CLOSE: TRY TO DEBUG WITH ACTUAL VALUE FUNCTION

%
%%

data = csvread('/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/ProblemSetData/firm_entry.csv',1,0);
%Cols are j, i, x
%Assume ordered temporally within market
beta = .95;


%%


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
%make grid

%demand X past choice is grid

demand_state = repmat([ 1 2 3 4 5]',2,1);
operate_state = [0 0 0 0 0 1 1 1 1 1]';
       
grid = horzcat(demand_state,operate_state);       


%%

x0 = [1 1 1];

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',200000,'MaxIter',1000); 
[estimate_entryexitsota,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x)llnfxp_sota(x,mle_data,beta,state_probs,grid),x0,options);

inv_Hessian = inv(Hessian);
std = sqrt(diag(inv_Hessian));



%%

x0 = [1 1 1];

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',200000,'MaxIter',1000); 
[estimate_entryexit,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x)llnfxp(x,mle_data,beta,state_probs),x0,options);

%%

%also compare value functions

    grid_interact = grid(:,1:columns(grid));
    colcounter = columns(grid);
    
    for i = 1:columns(grid)
     for j = i:columns(grid)
         colcounter = colcounter + 1;
         grid_interact(:,colcounter) = grid(:,i) .* grid(:,j);
     end
    end
    
    colcounter = colcounter + 1;
    grid_interact(:,colcounter) = ones(rows(grid),1);

    %%
    
    theta0 = estimate_entryexitsota(1,1);
    theta1 = estimate_entryexitsota(1,2);
    delta = estimate_entryexitsota(1,3);
    
    value_at_est_sota = value_sota(theta0,theta1,delta,state_probs,grid,grid_interact);

    value_at_est = value(theta0,theta1,delta,state_probs);


    comp_vals = horzcat(value_at_est(:,3),value_at_est_sota);