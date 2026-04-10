function DF_out = distance_DTW(DF_in, args)
    
    % CFG HEADER
    d1 = args.d1; % default = 1

    % select baseline trajectory
    x1Sel = args.x1Sel;    

    dtw = py.importlib.import_module("dtaidistance.dtw_ndim");
    dtw_fast = dtw.distance_fast;

    if ~isfield(DF_in,"ptr")
        ptr = nexInit_axisPointer(DF_in.df, DF_in.ax);
    else
        ptr = DF_in.ptr;
    end
    ID_axItr = nexOp_findAxByDim(ptr,3); % find axis that encodes the third dimension
    ax_itr = DF_in.ax.(ID_axItr);
    idx_x1 = find(ismember(ax_itr, x1Sel));

    x1Slice = repmat({':'},1,ndims(DF_in.df));
    x1Slice{end} = idx_x1;
    X1 = DF_in.df(x1Slice{:});
    X1_py = py.numpy.array(X1);

    % idx_x2 = find(~ismember(ax_itr,x1Sel));
    idx_x2 = [1:length(ax_itr)];
    x2Slice=x1Slice;
    D = {};
    for i = 1:length(idx_x2)
        idx=idx_x2(i);
        slice=repmat({':'},1,ndims(DF_in.df));
        slice{end}=idx;
        X2 = DF_in.df(slice{:});
        X2_py = py.numpy.array(X2);
        d = dtw_fast(X1_py, X2_py);
        D{i}=d;        
        % L{i} = id_traj;
    end

    D = cat(1, D{:});
    DF_out.df=D;
    DF_out.ax.(ID_axItr) = ax_itr;
    DF_out.args=args;
    
end