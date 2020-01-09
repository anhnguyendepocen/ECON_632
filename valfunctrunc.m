function [valchoice] = valfunctrunc(beta,a,b,c,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_probs_sims_up);

%3

%get params
theta0 = theta(1,1);
theta1 = theta(1,2);
delta = theta(1,3);


%%
%compute first period
u_first = c *  ( theta0  + theta1 * a + delta * (b - 1) ) ...
            + ;

eulermasch = double(eulergamma);

seq = 1:1:rows(sim_choice);
seq = seq';
u_flow = beta .^ seq .* ...
             sim_choice .* ( ...
              theta0 + theta1 .* sim_demand + delta .* (prev_sim_choice - 1) );
cont_value = beta .^ seq .* ...
           (eulermasch - log(mat_probs_sims_up));
          
v_period = u_flow + cont_value;

v_sum_sim = sum(v_period);

valchoice = u_first + mean(v_sum_sim) ;

            

end
