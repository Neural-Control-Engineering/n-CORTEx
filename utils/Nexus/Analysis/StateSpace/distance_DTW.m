function DF_out = distance_DTW(DF1_in, DF2_in, args)
    
    % CFG HEADER
    d1 = args.d1; % default = 1

    dtw = py.importlib.import_module("dtaidistance.dtw_ndim");
    dtw_fast = dtw.distance_fast;

    switch isempty(DF2_in)
        case 1 % INTER-DISTANCES
            % select baseline trajectory
            x1Sel = args.x1Sel;            
        
            if ~isfield(DF1_in,"ptr")
                ptr = nexInit_axisPointer(DF1_in.df, DF1_in.ax);
            else
                ptr = DF1_in.ptr;
            end
            axID_items = nexOp_findAxByDim(ptr,3); % find axis that encodes the third dimension
            ax_items = DF1_in.ax.(axID_items);
            idx_x1 = find(ismember(ax_items, x1Sel));
        
            x1Slice = repmat({':'},1,ndims(DF1_in.df));
            x1Slice{end} = idx_x1;
            X1 = DF1_in.df(x1Slice{:});
            X1_py = py.numpy.array(X1);                   
            idx_x2 = [1:length(ax_items)];            
            D = {};
            for i = 1:length(idx_x2)
                idx=idx_x2(i);
                slice=repmat({':'},1,ndims(DF1_in.df));
                slice{end}=idx;
                X2 = DF1_in.df(slice{:});
                X2_py = py.numpy.array(X2);
                d = dtw_fast(X1_py, X2_py);
                D{i}=d;        
                % L{i} = id_traj;
            end        

        case 0 % CROSS-DISTANCES

            % assumed dim: T (time) x L (latent) x N (trajectory number)

            if ~isfield(DF1_in,"ptr")
                ptr = nexInit_axisPointer(DF1_in.df, DF1_in.ax);
            else
                ptr = DF1_in.ptr;
            end
            axID_items = nexOp_findAxByDim(ptr, 3);
            ax_items = DF1_in.ax.(axID_items);
            slice=repmat({':'},1,ndims(DF1_in.df));
            D = {};
            for i = 1:length(ax_items)
                slice{end}=i;
                X1 = DF1_in.df(slice{:});
                X1_py = py.numpy.array(X1);
                X2 = DF2_in.df(slice{:});
                X2_py = py.numpy.array(X2);
                d = dtw_fast(X1_py, X2_py);
                D{i}=d;        
            end
    
    end

    D = cat(1, D{:});
    DF_out.df=D;
    DF_out.ax.(axID_items) = ax_items;
    DF_out.ptr=nexInit_axisPointer(D, DF_out.ax);
    DF_out.args=args;

        
end