%%Created by RM on 2019.12.27
%%to practice CCP Hotz Miller Estimator

%%CHANGE: THROW VALUE FINDING CODE INSIDE OPTIMIZATION ROUTINE

%%Make sure probabilities line up correctly!

%%NEED TO COMPUTE CORRECT PROBABILITIES:
%PROBABILITY PICKS IN GIVEN STATE
%(DEMAND LEVEL AND LAST PERIODS' DECISION) 

%%NEED TO USE EMPIRICAL PROBABILITIES TO MAKE SIMULATIONS!!


%%
%Import Data

data = csvread('/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/ProblemSetData/firm_entry.csv',1,0);
%Cols are j (market), i (in/out), x (demand)
%Assume ordered temporally within market
beta = .95;

%%Pick number of periods to use for value function estimation
trunc_periods = 1000;

%%Pick number of sims to use for value function estimation 
sim_num = 500;

%%
%Compute empirical conditional choice probabilities
%conditional on state and control

%here: observed state is some rep of. demand 
%and control is enter or not

%what is next period demand given current demand and choice?
min_demand = min(data(:,3));
max_demand = max(data(:,3));

mat_trans_counts_in_in= zeros(max_demand - min_demand + 1,max_demand - min_demand + 1);
mat_trans_counts_in_out= zeros(max_demand - min_demand + 1,max_demand - min_demand + 1);
mat_trans_counts_out_in= zeros(max_demand - min_demand + 1,max_demand - min_demand + 1);
mat_trans_counts_out_out= zeros(max_demand - min_demand + 1,max_demand - min_demand + 1);

obs_data = rows(data);

for i = 2: (obs_data-1) ;
    curr_demand = data(i,3);
    next_demand = data(i+1,3);
    
    prev_market = data(i-1,1);
    curr_market = data(i,1);
    next_market = data(i+1,1);
   
    prev_in_out = data(i-1,2);
    in_out = data(i,2);
    
    if curr_market == prev_market & curr_market == next_market ...
                & in_out > .5 & prev_in_out > .5;
        mat_trans_counts_in_in(curr_demand,next_demand) = ...
              mat_trans_counts_in_in(curr_demand,next_demand) + 1;
    end;
    
    if curr_market == prev_market & curr_market == next_market ...
                & in_out < .5 & prev_in_out > .5;
        mat_trans_counts_in_out(curr_demand,next_demand) = ...
              mat_trans_counts_in_out(curr_demand,next_demand) + 1;
    end;
    
    if curr_market == prev_market & curr_market == next_market ...
                & in_out > .5 & prev_in_out < .5;
        mat_trans_counts_out_in(curr_demand,next_demand) = ...
              mat_trans_counts_out_in(curr_demand,next_demand) + 1;
    end;
       
    if curr_market == prev_market & curr_market == next_market ...
                & in_out < .5 & prev_in_out < .5;
        mat_trans_counts_out_out(curr_demand,next_demand) = ...
              mat_trans_counts_out_out(curr_demand,next_demand) + 1;
    end; 
    
   
    
end;

mat_trans_probs_in_in = mat_trans_counts_in_in ./ ( sum(mat_trans_counts_in_in,2) + sum(mat_trans_counts_in_out,2) );
mat_trans_probs_in_out = mat_trans_counts_in_out ./ ( sum(mat_trans_counts_in_in,2) + sum(mat_trans_counts_in_out,2) );
mat_trans_probs_out_in = mat_trans_counts_out_in ./ ( sum(mat_trans_counts_out_in,2) + sum(mat_trans_counts_out_out,2) );
mat_trans_probs_out_out = mat_trans_counts_out_out ./ ( sum(mat_trans_counts_out_in,2) + sum(mat_trans_counts_out_out,2) );

%%

%Simulate choices and demand states 

%Create two separate matrices:
%one for choice (enter not)
%one for demand state
sim_choice = rand(trunc_periods,sim_num);
sim_choice = sim_choice > .5;

sim_demand = rand(trunc_periods,sim_num);
sim_demand = ceil(sim_demand * 5);

prev_sim_choice = zeros(trunc_periods, sim_num);
prev_sim_demand = prev_sim_choice;

for i = 2:trunc_periods;
    j = i - 1;
    prev_sim_choice(i,:) = sim_choice(j,:);
    prev_sim_demand(i,:) = sim_demand(j,:);
    
end;

in_in = prev_sim_choice > .5 & sim_choice > .5;
in_out = prev_sim_choice > .5 & sim_choice < .5;
out_in = prev_sim_choice < .5 & sim_choice > .5;
out_out = prev_sim_choice < .5 & sim_choice < .5;


mat_probs_sims = zeros(trunc_periods,sim_num);

for dprev = 1:5;
   for dcurr = 1:5;
       
   rel_demand = sim_demand == dcurr & prev_sim_demand == dprev;
   
   mat_probs_sims = mat_probs_sims + ...
                    rel_demand .* in_in * mat_trans_probs_in_in(dprev,dcurr) + ...
                    rel_demand .* in_out .* mat_trans_probs_in_out(dprev,dcurr) + ...
                    rel_demand .* out_in .* mat_trans_probs_out_in(dprev,dcurr) + ...
                    rel_demand .* out_out .* mat_trans_probs_out_out(dprev,dcurr);
 
   end;
end;

%%PAY ATTENTION TO FIRST ROW OF WHAT HAPPENS FOR VAL FUNCTION!!

%%
%Now fill in matrix with probs
%Loop through values

theta0 = [1 1 1];

%test = valsimfunc(beta,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_trans_probs_in_in,mat_trans_probs_in_out,mat_trans_probs_out_in,mat_trans_probs_out_out,trunc_periods,sim_num);

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',1000,'MaxIter',1000); 
[estimate_hm,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(theta)mindistfunc(beta,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_trans_probs_in_in,mat_trans_probs_in_out,mat_trans_probs_out_in,mat_trans_probs_out_out,trunc_periods,sim_num,mat_trans_counts_in_in,mat_trans_counts_in_out,mat_trans_counts_out_in,mat_trans_counts_out_out,mat_probs_sims),theta0,options);




%%

theta0 = [1 1 1];

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',1000,'MaxIter',700); 
[estimate_hm_search,log_like_hm_search] = fminsearch(@(theta)mindistfunc(beta,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_trans_probs_in_in,mat_trans_probs_in_out,mat_trans_probs_out_in,mat_trans_probs_out_out,trunc_periods,sim_num,mat_trans_counts_in_in,mat_trans_counts_in_out,mat_trans_counts_out_in,mat_trans_counts_out_out,mat_probs_sims),theta0,options);









