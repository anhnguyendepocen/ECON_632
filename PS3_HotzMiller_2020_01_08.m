%%Created by RM on 2019.12.27
%%to practice CCP Hotz Miller Estimator

%%Updated by RM on 2019.01.07 to consider transition matrix
%%ONLY for exogenous state for transition probs
%%logic: no probability for agents to think about for endog. states


%%
%Import Data

data = csvread('/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/ProblemSetData/firm_entry.csv',1,0);
%Cols are j (market), i (in/out), x (demand)
%Assume ordered temporally within market
beta = .95;

%%Pick number of periods to use for value function estimation
trunc_periods = 1000;

%%Pick number of sims to use for value function estimation 
sim_num = 2500;

num_exog_states = 5;
num_endog_states = 2;
num_choices = 2;

num_states = num_exog_states * num_endog_states;


%%
%Compute empirical changes in exogenous state (demand)

min_demand = min(data(:,3));
max_demand = max(data(:,3));

mat_trans_counts= zeros(max_demand - min_demand + 1,max_demand - min_demand + 1);

obs_data = rows(data);

for i = 2: (obs_data-1) ;
    prev_demand = data(i-1,3);
    curr_demand = data(i,3);
    
    prev_market = data(i-1,1);
    curr_market = data(i,1);
    
      if curr_market == prev_market;
          mat_trans_counts(prev_demand,curr_demand) = ...
          mat_trans_counts(prev_demand,curr_demand) + 1;
    end;
end;
     
mat_trans_probs = mat_trans_counts ./ sum(mat_trans_counts,2);


%%
%Compute choices as function of exogenous and endogenous state

counts_out_in = zeros(num_states,num_choices);
denom = zeros(num_states,1);

for i = 2: (obs_data-1) ;
    prev_demand = data(i-1,3);
    curr_demand = data(i,3);
    
    prev_market = data(i-1,1);
    curr_market = data(i,1);
    
    prev_in = data(i-1,2);
    curr_in = data(i,2);
    
    state = curr_demand + prev_in * 5;
    
    if curr_market == prev_market & curr_in < 1;
         counts_out_in(state,1) = counts_out_in(state,1) + 1;
    end;
    
    if curr_market == prev_market & curr_in > 0;
        counts_out_in(state,2) = counts_out_in(state,2) + 1;
    end;
    
    if curr_market == prev_market ;
          denom(state) = denom(state) + 1;
    end;

end;

mat_probs_in =  counts_out_in(:,2) ./ ...
            (counts_out_in(:,2) + counts_out_in(:,1) );
check_mat_probs_in = counts_out_in(:,2) ./ denom;


%%
%Turn demand state into 0-1 totals so rand draw gives demand 

mat_trans_probs_0_1 = 0 * mat_trans_probs;

prev = zeros(num_exog_states,1);
for i = 1:num_exog_states;
        mat_trans_probs_0_1(:,i) = prev + mat_trans_probs(:,i);
        prev = mat_trans_probs_0_1(:,i);
end;


%%
%CALC VALUE FUNCTION USING CCP ESTIMATOR
%Simulate choices and demand states 
%need a separate simulation for each (INITIAL) STATE PAIR
%total of 2 X 5 = 10 states
%think of state 1 as out, demand 1; state 6 as in, demand 1
%so make matrix that is sim counter X 1 X 1

%also make probability matrix that finds probability of choosing
%in or out given the state

%for debugging
%state = 1;
%ch = 0;
%j = 2;
%v = 1;


state_sim = zeros(trunc_periods,sim_num,num_states,num_choices);
probs_sim = zeros(trunc_periods,sim_num,num_states,num_choices) - 1;
choice_sim = zeros(trunc_periods,sim_num,num_states,num_choices) - 1;

sim_draw_exog = rand(trunc_periods,sim_num);
sim_draw_ch = rand(trunc_periods,sim_num);

for state = 1:num_states;
 for ch = 0:(num_choices - 1);
    
     %First Row: Same for all sims as initial state
    ch_ind = ch + 1;
    state_sim(1,:,state,ch_ind) = state;
    if ch < 1;
        %PROBS PICK OUT GIVEN STATE
        probs_sim(1,:,state,ch_ind) = 1 - mat_probs_in(state);
    end;
    if ch > 0;
        %PROBS PICK IN GIVEN STATE
         probs_sim(1,:,state,ch_ind) = mat_probs_in(state);
    end;
    choice_sim(1,:,state,ch_ind) = ch;
    
    %Subsequent rows: diff for each sim!  
    %trying to recode to do all sims at once
    
    %for i = 1:sim_num;
    
     for j = 2:trunc_periods;
           %draw given state
           k = j -1;
           state_from = state_sim(k,:,state,ch_ind);
          
           
           %Find curr exog (demand) state
            demand_state_from = state_from ... 
               - 5 * (state_from > 5);
           rand_draw_exog = sim_draw_exog(j,:);
           
           pre_prev_draw = repmat(0,sim_num);
           prev_draw = pre_prev_draw(1,:);
           
           to_demand_state = zeros(1,sim_num);
           
           for v = 1:num_exog_states;
               
               rel_trans_probs = mat_trans_probs_0_1(demand_state_from,v)';
               to_demand_state_indicator = prev_draw < rand_draw_exog & rand_draw_exog < rel_trans_probs;
               
               to_demand_state = to_demand_state + to_demand_state_indicator * v;
               
               prev_draw = rel_trans_probs;
               
           end;
           
           %Find endog state (past period's choice)
           prev_in =  choice_sim(k,:,state,ch_ind) > 0;
           state_sim(j,:,state,ch_ind) =  to_demand_state + 5 * prev_in;
           
           %Find choice and record
           rand_draw_ch = sim_draw_ch(j,:);
           
           in_choice_probs = mat_probs_in(state_from)';
           choose_in = rand_draw_ch < in_choice_probs  ;
           choice_sim(j,:,state,ch_ind) =  choose_in  ;

            %update prob of choice
           probs_sim(j,:,state,ch_ind) = in_choice_probs .* choose_in ...
                                    + (1- in_choice_probs) .* (1-choose_in);
           
           
        end;
        
    end;
    
end;

%%
%for debugging

test_state = state_sim(:,:,state,ch_ind);
test_probs = probs_sim(:,:,state,ch_ind);
test_choice = choice_sim(:,:,state,ch_ind);

unique(test_state(j,:))
unique(test_probs(j,:))
unique(test_choice(j,:))
%%

%test value functions
thetatest = [-1.67 .15 .55];

value_test_hm = valsimfunc(beta,thetatest,trunc_periods,state_sim,probs_sim,choice_sim,sim_num);

value_test_iter = check_hm_valfct_using_iter(beta,thetatest,mat_trans_probs);

value_nochoice = value(thetatest(1,1),thetatest(1,2),thetatest(1,3),state_probs);

%%
%Now fill in matrix with probs
%Loop through values

%theta0 = [1 1 1];
%theta0 = theta_rust;
%theta0 = [0 0 0];
%test = valsimfunc(beta,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_trans_probs_in_in,mat_trans_probs_in_out,mat_trans_probs_out_in,mat_trans_probs_out_out,trunc_periods,sim_num);

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',1000,'MaxIter',1000); 

theta0 = [1 1 1]

[estimate_hm_ccp,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(theta)mindistfunc(beta,theta,trunc_periods,state_sim,probs_sim,choice_sim,sim_num,mat_probs_in,mat_trans_probs),theta0,options);

inv_Hessian = inv(Hessian);
std = sqrt(diag(inv_Hessian));


%%

theta0 = [0 0 0];

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',1000,'MaxIter',700); 
[estimate_hm_ccp_2,log_like_hm_ccp_2] = fminunc(@(theta)mindistfunc(beta,theta,trunc_periods,state_sim,probs_sim,choice_sim,sim_num,mat_probs_in,mat_trans_probs),theta0,options);


%%
%compare estimates from search with rust estimates:
%q: is it just flat here?

%theta_search = [-4.6 .4 1.04];
theta_search = estimate_hm;
theta_rust = [-1.7 .15 .54];
theta_zeros = [0 0 0];

dist_search = mindistfunc(beta,theta_search,trunc_periods,state_sim,probs_sim,choice_sim,sim_num,mat_probs_in,mat_trans_probs)

dist_rust = mindistfunc(beta,theta_rust,trunc_periods,state_sim,probs_sim,choice_sim,sim_num,mat_probs_in,mat_trans_probs)

dist_zeros = mindistfunc(beta,theta_zeros,trunc_periods,state_sim,probs_sim,choice_sim,sim_num,mat_probs_in,mat_trans_probs)


%so far off--suggests something wrong in value function
%need to check line by line!!



%%
%checking

thetatest = [1 1 1];

value_test_hm = valsimfunc(beta,thetatest,trunc_periods,state_sim,probs_sim,choice_sim,sim_num);

value_test_iter = check_hm_valfct_using_iter(beta,theta,mat_trans_probs);

standardize_hm = value_test_hm - min(min(value_test_hm));
standardize_iter = value_test_iter - min(min(value_test_iter));
standardize_sw_iter = vf - min(min(vf));