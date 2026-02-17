function [X, xTicks, xLabels] = nexStat_binSTAT(STAT, categories)
    % Y_category = [];
    X = zeros(height(STAT),1);
    % tier = 1;
    % numItems_prev = 1;
    quantPrev = 2;
    numItems_prev = 1;
    xTicks = [];
    xLabels = [];
    dimsPrev = [1];
    for category = categories
        % disp(category);
        Y_category = STAT.(category);
        Y_unique = unique(Y_category);        
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