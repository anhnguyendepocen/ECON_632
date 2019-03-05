%%OverFlow Safe

function [osafeval] = overflow(data)
    max_val = max(data);
    osafeval = max_val + log(exp(data - max_val));
end
