%Created by RM on 2019.01.12 for ECON 632
%Part II: Programming

rng(632632632);

%%%%%%%%
%1. Underflow and Overflow
%%%%%%%%

val_over = 0;
loop_over = 1;

while loop_over > 0
    
        val_over = val_over + 100;
        val_test = log(exp(val_over));
        if val_test ~= val_over
               loop_over = -1;
        end;
        
end;

lowerbound_over = 0;
upperbound_over = val_over;
midpoint_over = (upperbound_over + lowerbound_over) / 2;
midlast_over = 0;
first = 1
tol = 10^(-14);

while abs(midpoint_over-midlast_over) > tol;
    
    if first > 0 
        midlast_over = 1
        first = -1
    else
        midlast_over = midpoint_over;
    end;
    midpoint_over = (upperbound_over + lowerbound_over) / 2;

    test_mid_over = log(exp(midpoint_over));
    if midpoint_over == test_mid_over
        lowerbound_over = midpoint_over
    else
        upperbound_over = midpoint_over
    end;
    
end;
bound_over = min(midpoint_over,midlast_over);

val_under = 0;
loop_under = 1;

while loop_under > 0
    
        val_under = val_under - 100;
        val_test = log(exp(val_under));
        if val_test ~= val_under
               loop_under = -1;
        end;
        
end;

lowerbound_under = val_under;
upperbound_under = 0;
midpoint_under = (upperbound_under + lowerbound_under) / 2;
midlast_under = 0;
first = 1;

tol = 10^(-14);

while abs(midpoint_under-midlast_under) > tol;
    
 if first > 0 
        midlast_under = 1
        first = -1
    else
        midlast_under = midpoint_under;
    end;
    midpoint_under = (upperbound_under + lowerbound_under) / 2;
    
    test_mid_under = log(exp(midpoint_under));
    if midpoint_under == test_mid_under
        upperbound_under = midpoint_under
    else
        lowerbound_under = midpoint_under
    end; 

end;
bound_under = max(midpoint_under,midlast_under);

bound_under
bound_over

%check_val = log(exp(bound_under));
%abs(check_val - bound_under)

%%%%%%
%Overflow Safe Computing
%https://lingpipe-blog.com/2009/06/25/log-sum-of-exponentials/
%%%%%%

%Create some random numbers near the upper bound:
rand_exp_lower = round(bound_over)-100;
rand_exp_upper = round(bound_over)+100;
rand_for_exp = randi([rand_exp_lower rand_exp_upper],1,200);
max_rand = max(rand_for_exp);

overflow_safe = max_rand + log(exp(rand_for_exp - max_rand))
verify_identical = min(overflow_safe == rand_for_exp) * 1;

%% 2_Accumarray
%%%%%%%%
%2. Accumarray
%%%%%%%%

rand_vector = randi([1 10],1,200);

subs = [ 1 8 5 5 10 8 5 ; 4 9 3 5 1 9 5]';

accum_out = rm_accumarray(subs,rand_vector);


%% 3_MLE_Utility
%%%%%%%%
%3. MLE Estimation of Utility
%%%%%%%% 


%%%%%%%%%%%%%%%%%%%%%%%%
%     SIMULATE DATA
%%%%%%%%%%%%%%%%%%%%%%%%


nsit = 5000; % number of choice situations
nopt = 3; % number of options in each choice situation
caseid = sort(repmat((1:nsit)',nopt,1)); % Choice situation id

% Set parameters
beta = -18;
xi = [12 25 29];
xi = xi - mean(xi);

% Simulate x (prices)
price = random('norm', 10, 10,[nsit*nopt,1]);

% Create Product FEs
prod_fe = repmat(xi',nsit,1);

% Utility
u = beta*price + prod_fe + random('ev', 0, 1,[nsit*nopt,1]);

% Find max utility
max_u = accumarray(caseid,u,[],@max);
choice = (max_u(caseid)==u);


%%%%%%%%%%%%%%%%%%%%%%%%
%     RUN LOGIT
%%%%%%%%%%%%%%%%%%%%%%%%

% Set starting values
betahat = 0;
xi1hat =0;
xi2hat = 0;
xi3hat = 0;
x0 = [betahat xi1hat xi2hat xi3hat];

%Optimize Log Likelihood
options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-6,'TolX',1e-6,'Diagnostics','on'); 
[estimate,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x0)ll3(x0,caseid,choice,price),x0,options);

% Calcuate standard errors
cov_Hessian = inv(Hessian);
std_c = sqrt(diag(cov_Hessian));
%t_stat = estimator_big./std_c;

% Bootstrap standard errors
bstrap_reps = 1000;

bstrap_id = ceil(rand(nsit,bstrap_reps)*nsit);
bstrap_caseid = sort(repmat(bstrap_id,nopt,1)); % Choice situation id
bstrap_output = zeros(bstrap_reps,columns(x0));

prodnumber = repmat([1 2 3]',nsit,1);

for i = 1:bstrap_reps;
    %Need Bstrap Choice as Well
    this_rep_ids = bstrap_caseid(:,i);
    this_rep_rowselect = max(prodnumber) * (this_rep_ids- 1) + prodnumber;
    this_rep_price = price(this_rep_rowselect,1);
    this_rep_u = u(this_rep_rowselect,1);

    % Find max utility
    this_rep_max_u = accumarray(this_rep_ids,this_rep_u,[],@max);
    this_rep_choice = (max_u(this_rep_ids)==this_rep_u);

    options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-6,'TolX',1e-6,'Diagnostics','on'); 
    [this_rep_estimate,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x0)ll3(x0,caseid,this_rep_choice,this_rep_price),x0,options);

    bstrap_output(i,1) = this_rep_estimate(1,1);
    bstrap_output(i,2) = this_rep_estimate(1,2);
    bstrap_output(i,3) = this_rep_estimate(1,3);
    bstrap_output(i,4) = this_rep_estimate(1,4);
    
end;




















    
    




        
        


