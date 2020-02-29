function [valuemat] = value(theta0,theta1,delta,state_probs,grid,grid_interact)


%theta0 = theta_test(1,1)
%theta1 = theta_test(1,2)
%delta = theta_test(1,3)


params0 = zeros(columns(grid_interact),1) + .1;

%%
%run minimizer to create code
options  =  optimset('GradObj','off','LargeScale','off','Display','iter','TolFun',1e-16,'TolX',1e-16,'Diagnostics','on','MaxFunEvals',200000,'MaxIter',1000); 
[estimate_sotaparams] = fminunc(@(params)sotaparams(theta0,theta1,delta,params,grid,grid_interact,state_probs),params0,options);


%%
%create valuemat from multiplication

valuemat = grid_interact * estimate_sotaparams;

end
