%Created by RM on 2019.01.12 for ECON 632
%Part II: Programming

%Dependencies: overflow, rm_accumarray, ll3, ll4a, ll4b, ll4c

%%
%%%%%%%%
%1. Underflow and Overflow
%%%%%%%%

val_over = 0;
loop_over = 1;

%Get approximation of upper bound
while loop_over > 0
    
        val_over = val_over + 100;
        val_test = log(exp(val_over));
        if val_test ~= val_over
               loop_over = -1;
        end;
        
end;

%Zoom in on upper bound
lowerbound_over = 0;
upperbound_over = val_over;
midpoint_over = (upperbound_over + lowerbound_over) / 2;
midlast_over = 0;
first = 1;
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
        lowerbound_over = midpoint_over;
    else
        upperbound_over = midpoint_over;
    end;
    
end;
bound_over = min(midpoint_over,midlast_over);

%Get approximation of lower bound
val_under = 0;
loop_under = 1;

while loop_under > 0
    
        val_under = val_under - 100;
        val_test = log(exp(val_under));
        if val_test ~= val_under
               loop_under = -1;
        end
        
end

%Zoom in on lower bound
lowerbound_under = val_under;
upperbound_under = 0;
midpoint_under = (upperbound_under + lowerbound_under) / 2;
midlast_under = 0;
first = 1;

tol = 10^(-14);

while abs(midpoint_under-midlast_under) > tol;
    
 if first > 0 
        midlast_under = 1;
        first = -1;
    else
        midlast_under = midpoint_under;
    end;
    midpoint_under = (upperbound_under + lowerbound_under) / 2;
    
    test_mid_under = log(exp(midpoint_under));
    if midpoint_under == test_mid_under
        upperbound_under = midpoint_under;
    else
        lowerbound_under = midpoint_under;
    end; 

end;
bound_under = max(midpoint_under,midlast_under);

bound_under
bound_over


%% Overflow
%%%%%%
%Overflow Safe Computing
%https://lingpipe-blog.com/2009/06/25/log-sum-of-exponentials/
%%%%%%

%Create some random numbers over the upper bound to test:
rand_exp_lower = round(bound_over);
rand_exp_upper = round(bound_over)+500;
rand_for_check = randi([rand_exp_lower rand_exp_upper], 1, 200 );

overflow_safe = overflow(rand_for_check);
verify_identical = min(overflow_safe == rand_for_check) * 1

%% 2_Accumarray
%%%%%%%%
%2. Accumarray
%%%%%%%%

subs = [ 1 8 5 5 10 8 5 7; 4 9 3 5 1 9 5 3]';

rand_vector = random('uniform',0,10,[rows(subs),1]);

rm_accum_out = rm_accumarray(subs,rand_vector);
accum_out = accumarray(subs,rand_vector);

verify_identical = min(rm_accum_out == accum_out) * 1


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
beta = -5;
xi = [25 12 0];

% Simulate x (prices)
price = random('lognorm', .1, 1,[nsit*nopt,1]);

% Create Product FEs
prod_fe = repmat(xi',nsit,1);

% Utility
u3 = beta*price + prod_fe + random('ev', 0, 1,[nsit*nopt,1]) ;

% Find max utility
max_u3 = accumarray(caseid,u3,[],@max);
choice3 = (max_u3(caseid)==u3);

%%
%%%%%%%%%%%%%%%%%%%%%%%%
%     RUN LOGIT
%%%%%%%%%%%%%%%%%%%%%%%%

% Set starting values
betahat = 0;
xi1hat = 0;
xi2hat = 0;
xi3hat = 0;
x0 = [betahat xi1hat xi2hat];

%Optimize Log Likelihood
options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-14,'TolX',1e-14,'Diagnostics','on'); 
[estimate3,log_like,exitflag,output,Gradient,Hessian3] = fminunc(@(x)ll3([x],caseid,choice3,price),x0,options);

% Calcuate standard errors
cov_Hessian = inv(Hessian3);
std_c = sqrt(diag(cov_Hessian));
%t_stat = estimator_big./std_c;

%%
% Bootstrap standard errors
bstrap_reps = 1000;

bstrap_id = ceil(random('uniform', 0, 1,[nsit,bstrap_reps])*nsit) ;
bstrap_caseid = sort(repmat(bstrap_id,nopt,1)); % Choice situation id
bstrap_output = zeros(bstrap_reps,columns(x0));

prodnumber = repmat([1 2 3]',nsit,1);

for i = 1:bstrap_reps;
    %Need Bstrap Choice as Well
    this_rep_ids = bstrap_caseid(:,i);
    this_rep_rowselect = max(prodnumber) * (this_rep_ids- 1) + prodnumber;
    this_rep_price = price(this_rep_rowselect,1);

    % Find max utility
    this_rep_choice = choice3(this_rep_rowselect);
    
    x0 = [betahat xi1hat xi2hat];
    %options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-6,'TolX',1e-6,'Diagnostics','on'); 
    [this_rep_estimate,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x)ll3(x,caseid,this_rep_choice,this_rep_price),x0,options);

    bstrap_output(i,1) = this_rep_estimate(1,1);
    bstrap_output(i,2) = this_rep_estimate(1,2);
    bstrap_output(i,3) = this_rep_estimate(1,3);
    
end;

%Compute SE from bootstrapped point estimates
bstrap_means = repmat(mean(bstrap_output),bstrap_reps,1);
bstrap_demeaned = bstrap_output - bstrap_means;
bstrap_demeaned_squared = bstrap_demeaned .^ 2;
bstrap_se = sqrt((sum(bstrap_demeaned_squared) * (1/(bstrap_reps - 1))))';


%% 4_MLE_Utility with Random Coefs
%%%%%%%%
%4. MLE Estimation of Utility with Random Coefs
%%%%%%%% 

%%%%%%%%%%%%%%%%%%%%%%%%
%     SIMULATE DATA
%%%%%%%%%%%%%%%%%%%%%%%%
%Need to additional simulate beta

betabar = -5;
betavar = 2;

betanorm = randn(nsit,1) * sqrt(betavar) + betabar;
nsit_nopt = (1:(nsit*nopt))';
take_beta = ceil(nsit_nopt/3);
betanorm_rep = betanorm(take_beta,:);

% Utility
u = betanorm_rep.*price + prod_fe + random('ev', 0, 1,[nsit*nopt,1]);

% Find max utility
max_u = accumarray(caseid,u,[],@max);
choice = (max_u(caseid)==u);

%%
%%%%%%%%%%%%%%%%%%%%%%%%
%     RUN LOGIT: USING QUADV
%%%%%%%%%%%%%%%%%%%%%%%%

% Set starting values; recall that utility up to normalization so force
% last fe to be 0
betahat = 0;
betavarhat = 1;
xi1hat = 0;
xi2hat = 0;
x0 = [betahat betavarhat xi1hat xi2hat];

%Optimize Log Likelihood
options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-14,'TolX',1e-14,'Diagnostics','on'); 
tic;
[estimate4a,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x)ll4a(x(1:4),caseid,choice,price),x0,options);
toc;
toc4a = toc;

%%
%4b
%%%%%%%%%%%%%%%%%%%%%%%%
%     RUN LOGIT: USING MONTE CARLO DRAWS
%%%%%%%%%%%%%%%%%%%%%%%%
betahat = 0;
betavarhat = 1;
xi1hat = 0;
xi2hat = 0;
x0 = [betahat betavarhat xi1hat xi2hat];

%Get Quadrature Points for Monte Carlo
sims = 500;
quadp_MC = random('norm', 0, 1,[1,sims]);
quadw_MC = repmat((1/sims),1,sims);

%Optimize Log Likelihood
options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-14,'TolX',1e-14,'Diagnostics','on'); 
tic;
[estimate4b,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x)ll4b(x,caseid,choice,price,quadp_MC,quadw_MC),x0,options);
toc;
toc4b = toc;

%%
%4c
%%%%%%%%%%%%%%%%%%%%%%%%
%     RUN LOGIT: USING SPARSE GRID POINTS
%%%%%%%%%%%%%%%%%%%%%%%%
betahat = 0;
betavarhat = 1;
xi1hat = 0;
xi2hat = 0;
x0 = [betahat betavarhat xi1hat xi2hat];

%Get Quadrature Points for Sparse Grids
[quadp_sg , quadw_sg] = nwspgr('KPN',1,4);

%Optimize Log Likelihood
options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-12,'TolX',1e-12,'Diagnostics','on'); 
tic;
[estimate4c,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x)ll4c(x,caseid,choice,price,quadp_sg',quadw_sg'),x0,options);
toc;
toc4c = toc;


%Trying different starting point
betahat = -1;
betavarhat = 1;
xi1hat = 10;
xi2hat = 5;
x0 = [betahat betavarhat xi1hat xi2hat];

%Optimize Log Likelihood
options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-12,'TolX',1e-12,'Diagnostics','on');
[estimate4calt,log_like,exitflag,output,Gradient,Hessian] = fminunc(@(x)ll4c(x,caseid,choice,price,quadp_sg',quadw_sg'),x0,options);



%% Aggregate Data (Berry 1994 style)

%%%%%%%%%%%%%%%%%%%%%%%%
%     USE SIMILATED DATA, SIMILAR CODE FROM 3: CALC MARKET SHARES, AVERAGE PRICES; CREATE
%     INSTRUMENT
%%%%%%%%%%%%%%%%%%%%%%%%


nsit = 5000; % number of choice situations
nopt = 3; % number of options in each choice situation
nopt_rep = repmat((1:nopt)',nsit,1);
msize = 50;

%Make beta small, xi smaller and flatter for the purpose of getting reasonable outside option
%
beta = -1;
xi = [1 2 3];

% Create Product FEs
prod_fe = repmat(xi',nsit,1);

%prices
price = random('lognorm', .1, 1,[nsit*nopt,1]);
market = ceil( (1 : (nsit * nopt))' / (msize * nopt) );
market_prod_id = (market - 1) * nopt + nopt_rep;
avg_market_prices = accumarray(market_prod_id, price) / msize; 

% Utility
avg_market_prices_expand = kron(avg_market_prices, ones(msize,1));
u5 = beta*avg_market_prices_expand + prod_fe + random('ev', 0, 1,[nsit*nopt,1]) ;

caseid = sort(repmat((1:nsit)',nopt,1)); % Choice situation id

sum(u5 > 0)/rows(u5)

% Find max utility
max_u5 = accumarray(caseid,u5,[],@max);
choice5 = (max_u5(caseid)==u5);

%%%For outside option: determistic piece of 0 then add the random shock

val_outside = random('ev', 0, 1,[nsit,1]);
max_u5_with_outside = max(max_u5,val_outside);
choice5_with_outside = (max_u5_with_outside(caseid)==u5);

%%%%Calc Market Shares and Prices in Markets
%find choice by id

market_share = accumarray(market_prod_id, choice5_with_outside) / msize;

market_id = ceil( (1 : (nopt * max(market)) ) / nopt)';
outside_share = 1 - accumarray(market_id, market_share);
outside_share_expand = kron(outside_share, [1 1 1]');

sum(outside_share == 0)/rows(outside_share)

%% Estimate Model: Force Zeros Away from Zero
%Turn 0s to 10 ^ (-14)
market_share_no0 = max(market_share,10^(-14));
outside_share_expand_no0 = max(outside_share_expand,10^(-14));

log_market_share_less_out_no0 = log(market_share_no0) - log(outside_share_expand_no0);

%%%%Create Instrument
price_instrument = avg_market_prices + random('norm', 0, .1, [rows(avg_market_prices), 1]);

%%%%Add product FE

prod_fe = horzcat( repmat( [ 1 0 0]', rows(avg_market_prices) / 3, 1) , ...
                    repmat( [ 0 1 0]', rows(avg_market_prices) / 3, 1) , ...
                    repmat( [ 0 0 1]', rows(avg_market_prices) / 3, 1) ) ;



%%%%Run 2SLS : No Zeros
%first_stage
z_iv = horzcat(price_instrument, prod_fe);
first_stage = inv(z_iv' * z_iv) * (z_iv' * avg_market_prices);
pred_vals = z_iv * first_stage;

%second stage
x_second_iv = horzcat(pred_vals, prod_fe);
second_stage = inv(x_second_iv' * x_second_iv) * (x_second_iv' * log_market_share_less_out_no0); 

%Compute SE
x_iv = horzcat(avg_market_prices, prod_fe);
H0_hat = inv((1/rows(x_iv)) * x_iv' * (z_iv * inv(z_iv' * z_iv) * z_iv') * x_iv);
epsilon_no0 = log_market_share_less_out_no0 - x_second_iv * second_stage;
V0_hat =(1/rows(x_iv))^2* x_iv' *  (z_iv * inv(z_iv' * z_iv) * z_iv') * (epsilon_no0' * epsilon_no0) * (z_iv * inv(z_iv' * z_iv) * z_iv') * x_iv;
Var_hat =(1/rows(x_iv)) * H0_hat * V0_hat * H0_hat;
stdev_hat = sqrt(diag(Var_hat));

%%%%Drop Markets with Zero Market Shares
market_has_zero =  accumarray(market_id, market_share, [], @min);
market_outside_has_zero = min(market_has_zero,outside_share);
market_has_zero_expand = kron(market_outside_has_zero, [1 1 1]');

drop_markets_with_zeros = market_share(market_has_zero_expand > 0);   
drop_outside_with_zeros = outside_share_expand(market_has_zero_expand > 0);

log_market_share_less_out_drop0 = log(drop_markets_with_zeros) - log(drop_outside_with_zeros);

avg_market_prices_drop0 = avg_market_prices(market_has_zero_expand > 0);
price_instrument_drop0 = price_instrument(market_has_zero_expand > 0);

%%%%Run 2SLS: Drop Zeros
%first_stage
prod_fe_drop0 = prod_fe(market_has_zero_expand > 0,:);

z_iv_drop0 = horzcat(price_instrument_drop0, prod_fe_drop0);
first_stage_drop0 = inv(z_iv_drop0' * z_iv_drop0) * (z_iv_drop0' * avg_market_prices_drop0);
pred_vals_drop0 = z_iv_drop0 * first_stage_drop0;

%second stage
x_second_iv_drop0 = horzcat(pred_vals_drop0, prod_fe_drop0);
second_stage_drop0 = inv(x_second_iv_drop0' * x_second_iv_drop0) * (x_second_iv_drop0' * log_market_share_less_out_drop0); 

%Compute SE
x_iv_drop0 = horzcat(avg_market_prices_drop0, prod_fe_drop0);
H0_hat_drop0 = inv( (1/rows(x_iv_drop0)) * x_iv_drop0' * (z_iv_drop0 * inv(z_iv_drop0' * z_iv_drop0) * z_iv_drop0') * x_iv_drop0);
epsilon_drop0 = log_market_share_less_out_drop0 - x_second_iv_drop0 * second_stage_drop0;
V0_hat_drop0 = (1/rows(x_iv_drop0))^2 * x_iv_drop0' *  (z_iv_drop0 * inv(z_iv_drop0' * z_iv_drop0) * z_iv_drop0') * (epsilon_no0' * epsilon_no0) ...
    * (z_iv_drop0 * inv(z_iv_drop0' * z_iv_drop0) * z_iv_drop0') * x_iv_drop0;
Var_hat_drop0 =1/rows(x_iv_drop0) * H0_hat_drop0 * V0_hat_drop0 * H0_hat_drop0;
stdev_hat_drop0 = sqrt(diag(Var_hat_drop0));

second_stage
stdev_hat
second_stage_drop0
stdev_hat_drop0

ci_perc90_no0 = horzcat(second_stage - 1.645 * stdev_hat, second_stage + 1.645 * stdev_hat);
ci_perc90_drop0 = horzcat(second_stage_drop0 - 1.645 * stdev_hat_drop0, second_stage_drop0 + 1.645 * stdev_hat_drop0);
