function DF_pooled = nexOp_poolAxes(pMap, DF, ptr)
    fields_pMap = fieldnames(pMap);
    DF_pooled = DF;
    if ~isempty(DF_pooled.df)
        for i = 1:length(fields_pMap)
            field_pMap = fields_pMap{i};
            pm = pMap.(field_pMap);
            % negative divsPerBin = block-PCA (handled by initReducer, not here)
            if pm.divsPerBin <= 0, continue; end
            % dereference 'axis'
            switch field_pMap
                case "time"
                    ax = "t";            
                otherwise
                    ax = field_pMap;
            end
            % [binAvgs, binIDs, binTicks, binAxis] = nexAnalysis_averagePool(DF_pooled.df, pm, ptr.(ax).dim, DF_pooled.ax.(ax));
            if isfield(ptr.(ax),'dim')
                dim = ptr.(ax).dim;
            else
                continue
            end
            % try
            %     dim = ptr.(ax).dim;
            % catch
            %     keyboard
            % end
            if ~isempty(dim)
                try
                    DF_pooled = pm.pool(DF_pooled, dim);
                catch
                    % keyboard
                end
            end
            % DF_pooled.df=binAvgs;
            % DF_pooled.ax.(ax)=binAxis;
        end    
    end
end