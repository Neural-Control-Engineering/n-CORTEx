function out = nex_insertAt(v, idx, val)
    out = [v(1:idx-1), val, v(idx:end)];
end
