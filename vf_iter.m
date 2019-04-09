%%%%ARGS%%%%
%v_0: initial guess for value function iteration (X*2*2)
%pi: per-period profit, determined by parameter guess in outer MLE problem
%    (X*2*2)
%p: estimated state transition probabilities (X*X)
%tol: solution tolerance (scalar)
%
%%%%OUTPUT%%%%
%vf: vf(x,i(-1),i) is the expected discounted value of being in state x,
%    having chosen i(-1) last period, and choosing i this period (X*2*2)
function [vf] = vf_iter(v_0, pi, p, tol)
    beta = .95;
    dist = Inf;
    v = v_0;
    while dist > tol
        %find continuation values
        %continuation value choosing 0 this period
        v_i_next_0 = p*v(:,1,1);
        v_i_next_1 = p*v(:,1,2);
        ev_i_0 = incl_val([v_i_next_0,v_i_next_1],2);
        %continuation value choosing 1 this period
        v_i_next_0 = p*v(:,2,1);
        v_i_next_1 = p*v(:,2,2);
        ev_i_1 = incl_val([v_i_next_0,v_i_next_1],2);
        %continuation values
        ev = zeros(size(v));
        ev(:,1,1) = ev_i_0;
        ev(:,1,2) = ev_i_0;
        ev(:,2,1) = ev_i_1;
        ev(:,2,2) = ev_i_1;        
        v_prime = pi + beta * ev; 
        dist = max(abs(v_prime - v));
        v = v_prime;
    end
    vf = v;
end