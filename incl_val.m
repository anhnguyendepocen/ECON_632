% Underflow-safe inclusive value computed along specified dimension
% (implemented in problem set 1)
function iv = incl_val(x,dim)
    max_x = max(x,[],dim);
    iv = log(sum(exp(x - max_x),dim))+max_x;
end