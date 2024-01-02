function random_number = negative_exp_rand(range_min, range_max)
    % range_min is the minimum value of the range
    % range_max is the maximum value of the range
    mu = mean([range_min, range_max]);
    random_number = range_min-1;
    while random_number >= range_max || random_number <= range_min
        random_number = exprnd(mu);
    end
end
