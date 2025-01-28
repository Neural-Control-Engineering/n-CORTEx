function v_out = gompertz(fit, v_in)
    L = fit(1);
    k = fit(2);
    v0 = fit(3);
    n = fit(4);
    b = fit(5);
    v_out = L .* (exp(-n.*exp(-k.*(v_in-v0)))) + b;        
end