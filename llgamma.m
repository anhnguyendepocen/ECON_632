function [log_like] = llgamma(x,min,num,t)

like = num *  ( ( 1- gamcdf(min,x,t)) .^ (num-1) ) * gampdf(min,x,t) ;
like = max(like,.000000000000000001);
log_like = -log(like);
end
