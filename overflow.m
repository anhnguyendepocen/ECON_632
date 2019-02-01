%%OverFlow Safe

function [osafeval] = overflow(data)
    max_val = max(data)
    osafeval = max_val + log(exp(rand_for_exp - max_val));
end;
