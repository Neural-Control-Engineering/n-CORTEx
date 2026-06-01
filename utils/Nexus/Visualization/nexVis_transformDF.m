function DF = nexVis_transformDF(DF_in, component, scale)
% Shallow struct copy + complex transform.
% Never mutates the live DF_postOp handle.
    DF.df  = DF_in.df;
    DF.ax  = DF_in.ax;
    DF.ptr = DF_in.ptr;
    if isfield(DF_in, 'sem') && isnumeric(DF_in.sem) && ~isempty(DF_in.sem)
        sem_in = DF_in.sem;
    else
        sem_in = [];
    end
    [DF.df, sem_out] = nexOp_applyComplexTransform(DF.df, sem_in, component, scale);
    DF.sem = sem_out;
    if isempty(sem_out)
        DF.sem = zeros(size(DF.df));
    end
end
