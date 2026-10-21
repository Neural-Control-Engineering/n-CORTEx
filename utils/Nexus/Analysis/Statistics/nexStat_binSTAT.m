function [X, xTicks, xLabels] = nexStat_binSTAT(STAT, categories, orderMap)
    % orderMap (optional): struct keyed by category name -> explicit
    % ordered value list for that column's bar/tier position (e.g. region
    % names deep->shallow from nexOp_regionDepthOrder, or a time axis's
    % own chronological order) instead of the default plain unique(),
    % which sorts alphabetically/ascending regardless of any real-world
    % ordinance. A category absent from orderMap (or orderMap omitted
    % entirely) keeps today's behavior unchanged. Only values actually
    % present in this category's data get a slot — the explicit order is
    % filtered down to unique(Y_category), never assumed to cover more
    % than what's here; anything present but somehow missing from the
    % explicit order (shouldn't normally happen) is appended at the end
    % in encounter order rather than silently dropped.
    if nargin < 3, orderMap = struct(); end
    % Y_category = [];
    X = zeros(height(STAT),1);
    % tier = 1;
    % numItems_prev = 1;
    quantPrev = 2;
    numItems_prev = 1;
    xTicks = [];
    xLabels = [];
    dimsPrev = [1];
    % categories(:)' forces a row regardless of caller orientation --
    % `for x = V` iterates COLUMNS of V, so a column-shaped `categories`
    % (e.g. nexObj_violin's bus.selKeys.CTG, built with a trailing
    % transpose) makes the WHOLE column a single iteration value instead
    % of one category per iteration, once more than one category is
    % selected -- confirmed directly as "Table variable names must be
    % strings or character vectors" the moment a 2nd CTG column was
    % picked (a 1-element "column" is indistinguishable from a scalar, so
    % selecting exactly one never surfaced this).
    for category = categories(:)'
        % disp(category);
        Y_category = STAT.(category);
        if isfield(orderMap, char(category)) && ~isempty(orderMap.(char(category)))
            Y_unique = resolveOrderedUnique(Y_category, orderMap.(char(category)));
        else
            Y_unique = unique(Y_category);
        end
        numItems = length(Y_unique);
        Y_enum = arrayfun(@(itm) find(ismember(Y_unique,itm)), Y_category, "UniformOutput", true)-1;
        % Y_category = [Y_category, STAT.(category)];
        % scale by tier
        Y_add = quantPrev .* ((Y_enum ./numItems));
        % try
        X = X + Y_add;
        % catch
            % keyboard
        % end
        %
        % numItems_prev = numItems;
        % update quantization for next layer
        quant = (diff(unique(Y_add))); % quantization level
        if ~isempty(quant)
            quantPrev=quant(1); %otherwise continue to next
            quant = quant(1); % scalar-ize
        else
            continue
        end
        % Axis bookkeeping
        % xLabel = repmat(Y_unique', 1, numItems_prev);
        % xTick = [0:quant:quant*(numItems*numItems_prev-1)];
        % xLabel = repmat(Y_unique', 1, numItems*prod(dimsPrev));
        % xTick = [0:quant:quant*(numItems*prod(dimsPrev))];
        xLabel = repmat(Y_unique', 1, prod(dimsPrev));
        xTick = [0:quant:quant*((prod(dimsPrev))*numItems-1)];
        xLabels = [xLabels; {xLabel}];
        xTicks = [xTicks; {xTick}];
        numItems_prev = numItems;
        dimsPrev = [dimsPrev, numItems_prev];

    end
    % X_out =
    % if isempty(X_in)
    % else
    % end
end

function Y_unique = resolveOrderedUnique(Y_category, explicitOrder)
% Filter explicitOrder down to values actually present in Y_category,
% preserving explicitOrder's order; append any present value explicitOrder
% didn't cover, in encounter order, so every present value still gets a
% slot. String-coerced comparison so it works whether Y_category is
% string/cellstr/categorical/char.
    presentVals = unique(Y_category);
    presentStr  = string(presentVals);
    orderStr    = string(explicitOrder(:))';
    keep        = orderStr(ismember(orderStr, presentStr));
    missing     = presentStr(~ismember(presentStr, keep));
    orderedStr  = [keep, missing(:)'];
    % Map back to presentVals' own native values (not just their string
    % form) so downstream ismember(Y_unique, itm) against the ORIGINAL
    % Y_category type still matches correctly.
    [~, loc] = ismember(orderedStr, presentStr);
    Y_unique = presentVals(loc);
end
