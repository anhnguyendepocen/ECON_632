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
sim_num = 800;

num_states = 10;
num_choices = 2;

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
    prev_demand = data(i-1,3);
    curr_demand = data(i,3);
    
    prev_market = data(i-1,1);
    curr_market = data(i,1);
   
    prev_in_out = data(i-1,2);
    curr_in_out = data(i,2);
    
    if curr_market == prev_market ...
                & curr_in_out > .5 & prev_in_out > .5;
        mat_trans_counts_in_in(prev_demand,curr_demand) = ...
              mat_trans_counts_in_in(prev_demand,curr_demand) + 1;
    end;
    
    if curr_market == prev_market  ...
                & curr_in_out < .5 & prev_in_out > .5;
        mat_trans_counts_in_out(prev_demand,curr_demand) = ...
              mat_trans_counts_in_out(prev_demand,curr_demand) + 1;
    end;
    
    if curr_market == prev_market ...
                & curr_in_out > .5 & prev_in_out < .5;
        mat_trans_counts_out_in(prev_demand,curr_demand) = ...
              mat_trans_counts_out_in(prev_demand,curr_demand) + 1;
    end;
       
    if curr_market == prev_market  ...
                & curr_in_out < .5 & prev_in_out < .5;
        mat_trans_counts_out_out(prev_demand,curr_demand) = ...
              mat_trans_counts_out_out(prev_demand,curr_demand) + 1;
    end; 
    
   
    
end;

mat_trans_probs_in_in = mat_trans_counts_in_in ./ ( sum(mat_trans_counts_in_in,2) + sum(mat_trans_counts_in_out,2) );
mat_trans_probs_in_out = mat_trans_counts_in_out ./ ( sum(mat_trans_counts_in_in,2) + sum(mat_trans_counts_in_out,2) );
mat_trans_probs_out_in = mat_trans_counts_out_in ./ ( sum(mat_trans_counts_out_in,2) + sum(mat_trans_counts_out_out,2) );
mat_trans_probs_out_out = mat_trans_counts_out_out ./ ( sum(mat_trans_counts_out_in,2) + sum(mat_trans_counts_out_out,2) );

%%

%Turn into version for simulating states by making out first
mat_trans_probs_in = zeros(max_demand - min_demand + 1,num_states);
mat_trans_probs_out = zeros(max_demand - min_demand + 1,num_states);

prev_val_in = zeros(5,1);
prev_val_out = zeros(5,1);

for i = 1:num_states;
    if i < 6;
        mat_trans_probs_in(:,i) = prev_val_in + mat_trans_probs_in_out(:,i);
        mat_trans_probs_out(:,i) = prev_val_out + mat_trans_probs_out_out(:,i);
    end;
    
    if i > 5;
       mat_trans_probs_in(:,i) = prev_val_in + mat_trans_probs_in_in(:,i-5);
       mat_trans_probs_out(:,i) = prev_val_out + mat_trans_probs_out_in(:,i-5);
    end;
    
    prev_val_in =  mat_trans_probs_in(:,i);
    prev_val_out = mat_trans_probs_out(:,i);
    
end; 

mat_trans_probs = vertcat(mat_trans_probs_out,mat_trans_probs_in);

pre_mat_probs_state_ch_from_out = horzcat(mat_trans_probs_out_out,mat_trans_probs_out_in);
pre_mat_probs_state_ch_from_in = horzcat(mat_trans_probs_in_out,mat_trans_probs_in_in);
mat_probs_state_ch = vertcat(pre_mat_probs_state_ch_from_out,pre_mat_probs_state_ch_from_in);


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
sim_draw = rand(trunc_periods,sim_num);

probs_in_by_state_from = sum(mat_probs_state_ch(:,6:10),2);

for state = 1:num_states;
 for ch = 0:(num_choices - 1);
    
     %First Row: Same for all sims as initial state
    ch_ind = ch + 1;
    state_sim(1,:,state,ch_ind) = state;
    if ch < 1;
        %PROBS PICK OUT GIVEN STATE
        probs_sim(1,:,state,ch_ind) = sum(mat_probs_state_ch(state,1:5));
    end;
    if ch > 0;
        %PROBS PICK IN GIVEN STATE
         probs_sim(1,:,state,ch_ind) = sum(mat_probs_state_ch(state,6:10));
    end;
    choice_sim(1,:,state,ch_ind) = ch;
    
    %Subsequent rows: diff for each sim!  
    %trying to recode to do all sims at once
    
    %for i = 1:sim_num;
    
     for j = 2:trunc_periods;
           %draw given state
           k = j -1;
           state_from = state_sim(k,:,state,ch_ind);
            
           rand_draw = sim_draw(j,:);
           
           pre_prev_draw = repmat(0,sim_num);
           prev_draw = pre_prev_draw(1,:);
           for v = 1:num_states;
               
               rel_trans_probs = mat_trans_probs(state_from,v);
               to_state_indicator = prev_draw < rand_draw & rand_draw < rel_trans_probs';
               
               state_sim(j,:,state,ch_ind) =  state_sim(j,:,state,ch_ind) + ...
                                            to_state_indicator * v;
               
               prev_draw = mat_trans_probs(state_from,v)';
               
           end;
           
           %update choice
           picked_in = state_sim(j,:,state,ch_ind) > 5;
           choice_sim(j,:,state,ch_ind) =  picked_in  ;

            %update prob of choice
           probs_sim(j,:,state,ch_ind) = picked_in .* probs_in_by_state_from(state_from)' ...
                                        + (1-picked_in) .* (1 - probs_in_by_state_from(state_from)');
           
           
        end;
        
    end;
    
end;

%%
%for debugging

test_state = state_sim(:,:,state,ch_ind);
test_probs = probs_sim(:,:,state,ch_ind);
test_choice = choice_sim(:,:,state,ch_ind);

unique(test_state(3,:))
unique(test_probs(3,:))
unique(test_choice(3,:))


%%
%Now fill in matrix with probs
%Loop through values

theta0 = [1 1 1];
%theta0 = theta_rust;
%theta0 = [0 0 0];
%test = valsimfunc(beta,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_trans_probs_in_in,mat_trans_probs_in_out,mat_trans_probs_out_in,mat_trans_probs_out_out,trunc_periods,sim_num);

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',1000,'MaxIter',1000); 
[estimate_hm,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(theta)mindistfunc(beta,theta,trunc_periods,matrix_sim,probs_sim,choice_sim,sim_num,mat_probs_state_ch),theta0,options);



%%

theta0 = [1 1 1];

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',1000,'MaxIter',700); 
[estimate_hm_search,log_like_hm_search] = fminsearch(@(theta)mindistfunc(beta,theta,trunc_periods,matrix_sim,probs_sim,choice_sim,sim_num,mat_probs_state_ch),theta0,options);


%%
%compare estimates from search with rust estimates:
%q: is it just flat here?

%theta_search = [-4.6 .4 1.04];
theta_search = estimate_hm;
theta_rust = [-1.7 .15 .54];

dist_search = mindistfunc(beta,theta_search,trunc_periods,matrix_sim,probs_sim,choice_sim,sim_num,mat_probs_state_ch)

dist_rust = mindistfunc(beta,theta_rust,trunc_periods,matrix_sim,probs_sim,choice_sim,sim_num,mat_probs_state_ch)

%so far off--suggests something wrong in value function
%need to check line by line!!



%%
%checking

thetatest = [1 1 1];

value_test_hm = valsimfunc(beta,thetatest,trunc_periods,matrix_sim,probs_sim,choice_sim,sim_num);

value_test_iter = check_hm_valfct_using_iter(beta,thetatest,mat_probs_state_ch);

standardize_hm = value_test_hm - min(min(value_test_hm));
standardize_iter = value_test_iter - min(min(value_test_iter));
