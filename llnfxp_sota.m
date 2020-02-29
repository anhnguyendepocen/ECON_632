function [log_like] = llnfxp(x,mle_data,beta,state_probs,grid)
    % Parameters
    theta0 = x(1,1);
    theta1 = x(1,2);
    delta = x(1,3);
    
    %%
    
    grid_interact = grid(:,1:columns(grid));
    colcounter = columns(grid);
    
    for i = 1:columns(grid)
     for j = i:columns(grid)
         colcounter = colcounter + 1;
         grid_interact(:,colcounter) = grid(:,i) .* grid(:,j);
     end
    end
    
    colcounter = colcounter + 1;
    grid_interact(:,colcounter) = ones(rows(grid),1);

    
   %%
   
    val = value_sota(theta0,theta1,delta,state_probs,grid,grid_interact);
    %val = val_info(:,3);
        
    
    %% Choice Probabilities
    prob_i0 = zeros(length(mle_data),1);
    pre_log_like = zeros(length(mle_data),1);
    for i = 1: rows(mle_data);
        demand_state_use = mle_data(i,1);
        last_operate = mle_data(i,3);
        val_i0 = sum( val .* (grid(:,1) == demand_state_use) .* (grid(:,2) == 0) );
        val_i1 = sum( val .* (grid(:,1) == demand_state_use) .* (grid(:,2) == 1) );

        prob_i0_num =  exp(beta * val_i0);
        prob_i0_den = prob_i0_num + exp(theta0 + demand_state_use * theta1 - (1 - last_operate) * delta + beta * val_i1 );
        
        prob_i0(i,1) = prob_i0_num / prob_i0_den;
        pre_log_like(i,1) = log(prob_i0(i,1)) * (1 - mle_data(i,2)) + log( (1-prob_i0(i,1)) ) * mle_data(i,2);
        
    end;

    log_like = -sum(pre_log_like);
end