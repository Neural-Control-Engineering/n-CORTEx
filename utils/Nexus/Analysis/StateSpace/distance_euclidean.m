function DF_out = distance_euclidean(DF1_in, DF2_in, args)

    % CFG HEADER
    d1 = args.d1; % default = 1

    if ~isfield(DF1_in, 'ptr')
        ptr = nexInit_axisPointer(DF1_in.df, DF1_in.ax);
    else
        ptr = DF1_in.ptr;
    end

    axID_d1 = nexOp_findAxByDim(ptr, d1);
    try
        d1_vals = DF1_in.ax.(axID_d1);
    catch
        keyboard
    end
    n_d1    = numel(d1_vals);

    % Items axis — 3rd dim when data is volumetric; absent for 2-D trial DFs
    axID_items = nexOp_findAxByDim(ptr, 3);
    hasItems   = ~isempty(axID_items);
    if hasItems
        ax_items = DF1_in.ax.(axID_items);
        n_items  = numel(ax_items);
    else
        n_items = 1;
    end

    switch isempty(DF2_in)

        case 1  % INTER-DISTANCES — reference item vs all items within DF1
            x1Sel  = args.x1Sel;
            idx_x1 = find(ismember(ax_items, x1Sel));

            x1Slice      = repmat({':'}, 1, ndims(DF1_in.df));
            x1Slice{end} = idx_x1;
            X1_ref = double(DF1_in.df(x1Slice{:}));

            D = zeros(n_d1, n_items);
            for i = 1:n_items
                slice      = repmat({':'}, 1, ndims(DF1_in.df));
                slice{end} = i;
                X2      = double(DF1_in.df(slice{:}));
                D(:, i) = euclid_along(X1_ref, X2, d1, n_d1);
            end

        case 0  % CROSS-DISTANCES — pairwise between DF1 and DF2
            D = zeros(n_d1, n_items);
            if hasItems
                for i = 1:n_items
                    slice      = repmat({':'}, 1, ndims(DF1_in.df));
                    slice{end} = i;
                    X1      = double(DF1_in.df(slice{:}));
                    X2      = double(DF2_in.df(slice{:}));
                    D(:, i) = euclid_along(X1, X2, d1, n_d1);
                end
            else
                X1      = double(DF1_in.df);
                X2      = double(DF2_in.df);
                D(:, 1) = euclid_along(X1, X2, d1, n_d1);
            end

    end

    DF_out.df = D;
    DF_out.ax.(axID_d1) = d1_vals;
    if hasItems
        DF_out.ax.(axID_items) = ax_items;
    end
    DF_out.ptr  = nexInit_axisPointer(D, DF_out.ax);
    DF_out.args = args;

end


% ── Local ─────────────────────────────────────────────────────────────────────

function D = euclid_along(X1, X2, d1, n_d1)
% Euclidean distance at each index along dimension d1.
% Returns a [n_d1 × 1] column vector.
    D = zeros(n_d1, 1);
    S = repmat({':'}, 1, ndims(X1));
    for i = 1:n_d1
        S{d1} = i;
        v1   = X1(S{:});
        v2   = X2(S{:});
        D(i) = norm(v1(:) - v2(:));
    end
end
