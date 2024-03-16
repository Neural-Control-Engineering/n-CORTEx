function dataExtract = extractSLRT(q, pq, params, sessions_to_extract)
    cmd = sprintf("dataExtract = extract%s(q, pq, params, sessions_to_extract);", params.extractCfg.experiment);
    eval(cmd);
end