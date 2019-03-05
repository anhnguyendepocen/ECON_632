%Created by RM on 2019.01.12 for ECON 632
%Part II: Programming
%rng('default');
rng(632632);

%%
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

val_under = 0;
loop_under = 1;

while loop_under > 0
    
        val_under = val_under - 100;
        val_test = log(exp(val_under));
        if val_test ~= val_under
               loop_under = -1;
        end
        
end

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

%check_val = log(exp(bound_under));
%abs(check_val - bound_under)

%%%%%%
%Overflow Safe Computing
%https://lingpipe-blog.com/2009/06/25/log-sum-of-exponentials/
%%%%%%

%Create some random numbers near the upper bound:
rand_exp_lower = round(bound_over)-100;
rand_exp_upper = round(bound_over)+100;
%rand_for_exp = round(random('uniform',rand_exp_lower, rand_exp_upper, [1, 200] ) );
rand_for_exp = randi([rand_exp_lower rand_exp_upper], 1, 200 );
max_rand = max(rand_for_exp);

overflow_safe = max_rand + log(exp(rand_for_exp - max_rand));
verify_identical = min(overflow_safe == rand_for_exp) * 1;

%% 2_Accumarray
%%%%%%%%
%2. Accumarray
%%%%%%%%

rand_vector = rand([1,200])*9 + 1;

subs = [ 1 8 5 5 10 8 5 ; 4 9 3 5 1 9 5]';

accum_out = rm_accumarray(subs,rand_vector);

