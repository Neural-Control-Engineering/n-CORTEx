function DF_flat = nexOp_viewDF(DF)
    % line all non-first-dimensional axes along the second axis
    df=DF.df;
    df_flat = reshape(df,size(df,1),[]);
    DF_flat=DF; 
    DF_flat=rmfield(DF_flat,"ptr");
    DF_flat.df = df_flat;
    DF_flat.ax = DF.ax;
    DF_flat.ax.feature = []; % combined list of features
    % axes

    ptr=DF.ptr;
    ptrFields = fieldnames(ptr);
    dim=[];
    axes={};
    fName=[];
    for i = 1:length(ptrFields)
        field=convertCharsToStrings(ptrFields{i});        
        dim_i = ptr.(field).dim;
        if dim_i~=1
            dim=[dim, dim_i];
            axes=[axes,DF.ax.(field)];
            fName=[fName,field];
        end
    end

    [dimSort, sortOrder]=sort(dim);
    axes=axes(sortOrder);
    fName=fName(sortOrder);
    % axes=sort(axes,sortOrder);
    % axes = {DF.ax.f, DF.ax.chans};
    nDims = numel(axes);
    grid = cell(1,nDims);
    [grid{:}] = ndgrid(axes{:});

    feature = strings(numel(grid{1}),1);    
    for i = 1:numel(feature)
        PARTS = strings(1,nDims);
        parts = strings(1,nDims);
        m=1;
        for d = 1:nDims
            parts(1) = fName(d);
            parts(2) = grid{d}(i);   
            PARTS(d)=strjoin(parts,":");
            m=m+2;
        end        
        feature(i) = strjoin(PARTS,"; ");
    end

    feature=feature';
    DF_flat.ax.feature=feature;
    DF_flat=nex_initAxisPointer_v2(DF_flat);
    % f_reshape = reshape(feature, size(df,1), []);

end