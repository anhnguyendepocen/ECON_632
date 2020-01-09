function [vals_use] = valsimfunc(beta,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_trans_probs_in_in,mat_trans_probs_in_out,mat_trans_probs_out_in,mat_trans_probs_out_out,trunc_periods,sim_num,mat_probs_sims);
%2


vals = zeros(5,2,2);
%a and b are states; c is current choice

for a = 1:5;
    %3
  for b = 0:1;
    for c = 0:1;

   mat_probs_sims_up = mat_probs_sims;
      
   
for i = 2:trunc_periods;
  for j = 1:sim_num;
      
    if b > .5 & c > .5;
      mat_probs_sims_up(1,j) = mat_trans_probs_in_in(a,sim_demand(1,j));
    end;
    
    if b > .5 & c < .5;
      mat_probs_sims_up(1,j) = mat_trans_probs_in_out(a,sim_demand(1,j));
    end;
 
   if b < .5 & c > .5;
      mat_probs_sims_up(1,j) = mat_trans_probs_out_in(a,sim_demand(1,j));
    end;
      
    if b < .5 & c < .5;
      mat_probs_sims_up(1,j) = mat_trans_probs_out_out(a,sim_demand(1,j));
    end;
  

  end;
end;

    b_sub = b + 1;
    c_sub = c + 1;
    vals(a,b_sub,c_sub) = valfunctrunc(beta,a,b,c,sim_choice,prev_sim_choice,sim_demand,prev_sim_demand,theta,mat_probs_sims_up);

    end;
  end;
end;

vals_use = vals / sim_num;


end