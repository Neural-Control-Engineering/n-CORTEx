function DF_perm = nexOp_permute2First(DF, axSel, ptr)
    switch class(DF)
        case 'struct'
            df = DF.df;
            % concatenate dfs along first dimension
            % nDims = cellfun(@(x) ndims(x), dfCol, "UniformOutput", false);
            % nDims = max(cat(1,nDims{:}));
            nDims = ndims(df);
            % catDim = nDims+1;    
            dims = [1:nDims];
            dimSel = ptr.(axSel).dim;
            % put time dimension into first slot    
            permuteOrder = [dimSel, setdiff(dims,dimSel)];
            df_perm = permute(df, permuteOrder);        
            DF_perm = DF;
            DF_perm.df=df_perm;
            DF_perm = nex_initAxisPointer_v2(DF_perm);
            % DF_perm.ptr=ptr_perm;
        case 'double'
            df = DF;
            nDims = ndims(df);
            % catDim = nDims+1;    
            dims = [1:nDims];
            try
                dimSel = ptr.(axSel).dim;
            catch
                keyboard
            end
            % put time dimension into first slot    
            permuteOrder = [dimSel, setdiff(dims,dimSel)];
            df_perm = permute(df, permuteOrder);        
            DF_perm = df_perm;
            % DF_perm.df=df_perm;
            % DF_perm = nex_initAxisPointer_v2(DF_perm);
        otherwise
            df = DF.df;
            % concatenate dfs along first dimension            
            nDims = ndims(df);            
            dims = [1:nDims];
            dimSel = ptr.(axSel).dim;
            % put time dimension into first slot    
            permuteOrder = [dimSel, setdiff(dims,dimSel)];
            df_perm = permute(df, permuteOrder);        
            DF_perm = DF;
            DF_perm.df=df_perm;
            DF_perm = nex_initAxisPointer_v2(DF_perm);            
    end
    
end