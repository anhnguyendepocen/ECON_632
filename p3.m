% Shwetha Raghuraman
% ECON 632 Problem Set 3

%read data
data = csvread("firm_entry.csv",1);
market_id = data(:,1);
i = data(:,2);
x = data(:,3);

%set variables
X = max(x);
K = max(market_id);
N = size(i,1);
x_sit = reshape(repmat(x,1,2)',N*2,1);
choice_sit = reshape(repmat(1:N,2,1),N*2,1);
i_chosen_sit = reshape(repmat(i,1,2)',N*2,1);
i_sit = reshape(repmat([0;1],N,1),N*2,1);
t_sit = reshape(repmat(1:100,2,50),N*2,1);
chosen = (i_sit==i_chosen_sit);

%estimate state transition probabilities
x_next = [x(2:end);0];
last_period = [diff(market_id);1];
transitions = [x(last_period==0), x_next(last_period==0)];
transition_count = accumarray(transitions,1);
p = transition_count ./ sum(transition_count,2);

%mle
sv = [1;1;1];

options  =  optimset("GradObj","off","LargeScale","off","Display",...
    "off","TolFun",1e-6,"TolX",1e-6); 
tic;
[estimate,log_like,~,~,~,Hessian] = ...
    fminunc(@(c)ll(c,choice_sit,chosen,p,x_sit,X,i_sit,N,t_sit),sv,options);
estimation_time = toc;

% Calcuate analytical standard errors
cov_Hessian = inv(Hessian);
std_c = sqrt(diag(cov_Hessian));

% Print output
coef = ["beta0";"beta1";"delta"]
disp(" ");
disp("    Coef        Estimate         AnStdErr");
table = [estimate, std_c];
disp([coef,table]);
fprintf("Log Likelihood: %.2f\n", log_like);
dlmwrite("results.csv",table,"&");
fprintf("Estimation took %f seconds.\n",estimation_time);
