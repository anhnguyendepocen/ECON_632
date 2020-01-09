%%%
%Simulation for Procurement Auctions with Learning 
%Proposal for ECON 632
%Created by RM on 2019.05.01
%%%

%%
%Make Fake Data 
sims = 5

%Num of bidders
N = 15;
%True distribution of constant marginal cost
k = 70;
theta = 1;

%Num of Periods
periods = 25;


%%


bids = zeros(N+1,periods,sims);
belief_tracker_k = zeros(N,periods,sims);
margcost_tracker = zeros(N,periods,sims);

for s = 1:sims;

margcost = gamrnd(k,theta,N,1);

%First Period MC shock
mc_shock = normrnd(0,2,N,1);

%Beliefs About Parameters of MC distribution
initial_belief_theta = theta + normrnd(0,.2,N,1);
initial_belief_theta = max(initial_belief_theta,0.01);
initial_belief_k = (mc_shock + margcost) ./ initial_belief_theta;

curr_belief_k = initial_belief_k;
curr_belief_theta = initial_belief_theta;

signal_variance = normrnd(1,1,N,1);

%%
%Iterate Forward to Figure out Bidding
%FGamma = @(y,k,t) ( ( ones(N,1) - gamcdf(y,k,t) ) .^ (N-1) );
%FGammaOne =  @(y,k,t) ( ( 1 - gamcdf(y,k,t) ) ^ (N-1) );
%Fnormexp = @(y) ( exp(y * price_chosen + fe_chosen) ./ ( accumarray(caseid,exp(y * price + prod_fe_test)) ) ) .* exp(-(y-betabar_test) .^ 2 ./ (2*betavar_test));

%FGammaOne =  @(z)( ( 1 - gamcdf(z,curr_belief_k_b,curr_belief_t_b) ) .^ (N-1) );

%y = 60;
%test = ( 1 - gamcdf(y,curr_belief_k(1,1),curr_belief_theta(1,1)) ) ^ (N-1);
%test2 = FGammaOne(y);
%test3 = integral(FGammaOne,mc_curr_b,50);
%test4 = quadv(@(y)FGamma(y,curr_belief_k,curr_belief_theta), 5*ones(N,1),10 * ones(N,1));

%%


for p = 1:periods;
    s
    p
%p = 1;
    belief_tracker_k(:,p,s) = curr_belief_k;
    %Generate Bids
    mc_shock = normrnd(0,1,N,1);
    mc_curr = margcost + mc_shock;
    margcost_tracker(:,p,s) = mc_curr;

    
    top_integral = ceil(2*mc_curr + 5);    

    for b = 1:N;
      mc_curr_b = mc_curr(b,1);
      curr_belief_k_b = curr_belief_k(b,1);
      curr_belief_t_b = curr_belief_theta(b,1);
      bottom_integral = roundn(mc_curr_b,-4);
      FGammaOne =  @(z)( ( 1 - gamcdf(z,curr_belief_k_b,curr_belief_t_b) ) .^ (N-1) );
      bid_integral_b = integral(FGammaOne, bottom_integral, max(200,top_integral(b,1)) );
      bid_denom_b = (1 - gamcdf(mc_curr_b,curr_belief_k_b,curr_belief_t_b) ) ^ (N-1);
      bid_b = mc_curr_b + bid_integral_b / bid_denom_b;
      bids(b,p,s) = bid_b;

    end;
    
    bids(N+1,p,s) = min(bids(1:N,p,s));
    min_bid = bids(N+1,p,s);


%%
    %back out MC of min bid
    belief_min = zeros(N,1);
    best_fit_k = zeros(N,1);

    for b = 1:N;
        mc_curr_b = mc_curr(b,1);
        curr_belief_k_b = curr_belief_k(b,1);
        curr_belief_t_b = curr_belief_theta(b,1);
        FGammaOne =  @(z)( ( 1 - gamcdf(z,curr_belief_k_b,curr_belief_t_b) ) .^ (N-1) );

        tol = .001;
        diff = 1;
        c_test = mc_curr_b + .5;

        b 
        while diff > tol && c_test > 0;
            c_test = c_test - .001;
            c_test_bottom = roundn(c_test,-4);
            b_test_integral = integral(FGammaOne, c_test_bottom, max(200,ceil(2 * c_test + 5)));
            b_test_denom =(1 - gamcdf(c_test,curr_belief_k_b,curr_belief_t_b) ) ^ (N-1);
            b_test = c_test + b_test_integral / b_test_denom;
            diff = abs(b_test - min_bid);
            %diff
            %c_test
        end;

        belief_min(b,1) = c_test;  
        belief_min = max(belief_min,tol);

    %Update Beliefs
        %MLE for shape parameter
         x0 = curr_belief_k_b;
          if belief_min(b,1) < 1;
                x0 = curr_belief_k_b / 2;
            end;

        options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-14,'TolX',1e-14,'Diagnostics','on'); 
        [estimate] = fminunc(@(x)llgamma(x,belief_min(b,1),N,curr_belief_t_b),x0,options);

        estimate
        k
        belief_min
        min_bid

        %curr_belief_k(b,1) = (p / (p + 1)) * curr_belief_k(b,1) + (1 / (p + 1) ) * this_rep_estimate;
        curr_belief_k(b,1) = (p / (p + 1)) ^2 * curr_belief_k(b,1);
        curr_belief_k(b,1) = curr_belief_k(b,1) + (1 - ( (p / (p + 1)) ^2 ) ) * estimate;
  
   end;
     

end;


    
%%
%Calculate Belief RMSE

belief_RMSE = zeros(1,periods);

for p = 1:periods;
    beliefs = belief_tracker_k(:,p);
    beliefs_less_80 = beliefs - 80;
    beliefs_se = beliefs_less_80' * beliefs_less_80;
    belief_RMSE(1,p) = sqrt(beliefs_se / N);
end;
    %Update Beliefs 
    %for b = 1:N;
     %   curr_belief_k_b = curr_belief_k(b,1);
      %  curr_belief_t_b = curr_belief_theta(b,1);
       % likelihood_of_max = gamcdf(max_bid,curr_belief_k_b,curr_belief_t_b) ^ N
    

 end;

%%
%Export data

folder_path = '/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp/';

export_names = strings([sims,3]);
 
for s=1:sims;

    export_names(s,1) = strcat(folder_path,'belief_tracker_k_',num2str(s),'.csv');
    export_names(s,2) = strcat(folder_path,'margcost_tracker_',num2str(s),'.csv');
    export_names(s,3) = strcat(folder_path,'bids_tracker_',num2str(s),'.csv');

    belief_output = belief_tracker_k(:,:,s);
    csvwrite(export_names(s,1),belief_output);

    margcost_output = margcost_tracker(:,:,s);
    csvwrite(export_names(s,2),margcost_output);

    bids_output = bids(:,:,s);
    csvwrite(export_names(s,3),bids_output);

end;



%csvwrite('/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp/ps3_graph_data.csv',export_graph_data);
 


