function R = nexOp_extractBrainSenseLfp(R_bs, side)
    R_bs = struct2table(R_bs);
    R = table();
    for i = 1:height(R_bs)
        r = R_bs(i,:);
        meta1 = removevars(r, ["TherapySnapshot","LfpData"]);
        meta2 = removevars(struct2table(r.TherapySnapshot), ["Left","Right"]);
        meta = [meta1, meta2];
        % therapy snapshot
        meta_TS = struct2table(r.TherapySnapshot.(side));
        meta = [meta, meta_TS];
        meta.Hemisphere=side;
        % lfpData
        r_lfp = struct2table(r.LfpData{1,1});
        r_lfp_meta = removevars(r_lfp, ["Left","Right"]);
        r_lfp = struct2table(r_lfp.(side));
        T_r = [r_lfp_meta, r_lfp];
        meta.LFP_bs = {T_r};
        R = [R; wrapChars(meta)];
        
    end
end

function T = wrapChars(T)
    for v = string(T.Properties.VariableNames)
        if ischar(T.(v))
            T.(v) = {T.(v)};
        end
    end
end