%Created by RM on 2019.03.06 for ECON 632
%Part II: Programming

%Dependencies: overflow, rm_accumarray, ll3, ll4a, ll4b, ll4c

%%
%%%%%%%%
%1. Import Data
%%%%%%%%

data = csvread('/Users/russellmorton/Desktop/Coursework/Winter 2019/ECON 632/Problem Sets/Temp/insurance_data_mod.csv',1,0);
indiv_id = data(:,1);
choice_sit = data(:,2);
year = data(:,5);
years_enrolled = data(:,6);
age = data(:,7);
income = data(:,9);
risk = data(:,10);
tool = data(:,11);
coverage = data(:,12);
quality = data(:,13);
num_plans = data(:,15);
plan_goes_away = data(:,18);
chose_min = data(:,19);
same_plan = data(:,20);
premium_income_q1 = data(:,29);
premium_income_q2 = data(:,32);
premium_income_q3 = data(:,35);
premium_income_q4 = data(:,38);
quality_risk_q1 = data(:,30);
quality_risk_q2 = data(:,33);
quality_risk_q3 = data(:,36);
quality_risk_q4 = data(:,39);
coverage_risk_q1 =  data(:,31);
coverage_risk_q2 =  data(:,34);
coverage_risk_q3 =  data(:,37);
coverage_risk_q4 =  data(:,40);

%%
%%%%%
%Turn into variables and datasets for use later in likelihood
%%%%%

choice = data(:,3) ==  data(:,4); 
first_year = years_enrolled == 1;

prem_income = horzcat(premium_income_q1, premium_income_q2, premium_income_q3, premium_income_q4);
qual_risk = horzcat(quality_risk_q1, quality_risk_q2, quality_risk_q3, quality_risk_q4);
cov_risk = horzcat(coverage_risk_q1, coverage_risk_q2, coverage_risk_q3, coverage_risk_q4);

prob_vars = horzcat(tool, num_plans, risk, age, income, years_enrolled, chose_min, first_year, plan_goes_away);
plan_vars = horzcat(coverage, quality, same_plan);

%%
minyear = min(year);
maxyear = max(year) - 1;

year_dum = zeros(rows(year),maxyear - minyear + 1);

for i = minyear:maxyear;
    j = i + 1 - minyear;
    year_dum(:,j) = year == i;
end;
    

%%
%%%%%
%Set Starting Values for All Parameters 
%%%%

%alpha = [0 0 0 0];
alpha_start = [1 1 1 1];
beta_start = [0 0 0 0];
gamma_start = [0 0 0 0];
delta_start = [0 0 0];
%xi_start = [0 0 0 0 0 0 0 0 0 0];
xi_start = zeros(1,columns(year_dum));

psi_start = [2 0 0 0 0 0 0 0 0 0 0];
mu_start = 0;
sigma2_start = 1;

x0 = horzcat(alpha_start,beta_start,gamma_start,delta_start,xi_start,psi_start,mu_start,sigma2_start);

%%
%%%%%
%MLE
%%%%%

options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-14,'TolX',1e-14,'Diagnostics','on','MaxFunEvals',200000,'MaxIter',1000); 
%options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-14,'TolX',1e-14,'Diagnostics','on'); 
%[estimateplan,log_like,exitflag,output,Gradient,Hessianplan] = fminunc(@(x)llplan(x,choice_sit,choice,prem_income,qual_risk,cov_risk,plan_dum,prob_vars,plan_vars),x0,options);
[estimateplan] = fminunc(@(x)llplan(x,choice_sit,choice,prem_income,qual_risk,cov_risk,year_dum,prob_vars,plan_vars),x0,options);

%function [log_like] = llplan(alpha,beta,gamma,xi,psi,mu,sigma2,caseid,choice)

%% 
%%%%% 
%Double Check Starting Values
%%%%

alpha_start_2 = [-.4 -.3 -.2 -.1];
beta_start_2 = [1 1.5 2 2.5];
gamma_start_2 = [0 1 2 3];
delta_start_2 = [.1 .1 .1];
%xi_start = [0 0 0 0 0 0 0 0 0 0];
xi_start_2 = zeros(1,columns(year_dum)) + .2;

psi_start_2 = [0 0 0 0 0 0 0 0 0 0 0] + .05;
mu_start_2 = 1;
sigma2_start_2 = 5;

x0_2 = horzcat(alpha_start_2,beta_start_2,gamma_start_2,delta_start_2,xi_start_2,psi_start_2,mu_start_2,sigma2_start_2);

%%
[estimateplan_2] = fminunc(@(x)llplan(x,choice_sit,choice,prem_income,qual_risk,cov_risk,year_dum,prob_vars,plan_vars),x0_2,options);

compare = horzcat(estimateplan',estimateplan_2');
