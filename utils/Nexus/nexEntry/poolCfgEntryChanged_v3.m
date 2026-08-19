function poolCfgEntryChanged_v3(src, ~, poolMap, field)
    poolMap.(field) = src.Value;
end
