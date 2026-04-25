function V = nexDraw_violin(ax, STAT,  S_categories, C_errorBar)

    categories = cellfun(@(f) S_categories.(f), fieldnames(S_categories));
    categories = strrep(categories(~strcmp(categories,"None")),"--","_")';
    [X, xTicks, xLabels] = nexStat_binSTAT(STAT, categories);
    % DRAWING    
    switch class(STAT.df)
        case 'cell'
            Y = cell2mat(STAT.df);
        otherwise
            Y = STAT.df;
    end    
    hold(ax,"on");
    % V.v = violinplot(ax, X, Y, GroupByColor=X);    
    % label bookkeeping
    xLabels_sub = xLabels{1}; xTicks_sub = xTicks{1};
    X = round(X,10); xTicks_sub = round(xTicks_sub,10); % floating point drift
    L = arrayfun(@(x) xLabels_sub(x==xTicks_sub), X, "UniformOutput",true);
    % L = arrayfun(@(x) xLabels_sub(x==xTicks_sub), X, "UniformOutput",false);
    Z = nexOp_accumCols(X, Y, L);
    V.v = violinplot(ax, Z);    
    V.s = nexDraw_scatter(ax, Z, V.v);        
    V.e = nexDraw_error(ax, Z, C_errorBar);
    colorAx_green(ax);
    hold(ax,"off");   
    % axList = [ax];
    axList= [ax];
    gapOffset = 15;
    ax.XRuler.TickLabelGapOffset=0;
    cats = ax.XAxis.Categories;
    for i = 1:size(xTicks,1)
        xTick = xTicks{i,1} + 1; % shift up one to avoid 0 indexing
        if ~isempty(xTick)
            ax_i = axes('Position',ax.Position,"Visible","off");            
            % plot(ax_i, categorical(cats), nan(size(cats)), 'Visible','off');
            plot(ax_i, categorical(cats), nan(size(cats)));
            ax_i.Parent = ax.Parent;
            ax_i.Visible="on";
            ax_i.Box="off";
            ax_i.YTick=[];
            axList = [axList, ax_i];            
            % switch class(xTick)
            %     case "string"
            %         ax_i.XTick = categorical(cats((str2double(xTick))));
            %     otherwise
            %         ax_i.XTick = categorical(xTick);
            % end            
            % ax_i.XTick = (xTick);
            ax_i.XTickLabel = xLabels{i};           
            ax_i.XRuler.TickLabelGapOffset = gapOffset;
            colorAx_green(ax_i);
            gapOffset = gapOffset+20;
        end
    end    
    uistack(ax,"top");
    % ax.XLim = double(ax.XLim);
    % (find(isempty(axList)))
    linkaxes(axList);
    V.axList=axList;

    % hold(ax,"off");
    
    % for i =2:length(axList)
    %     ax_i = axList(i);
    %     ax_i.Box="off";
    %     ax_i.Color
    % end
    % recursively build a nested violin plot, given selections
    % tierID = sprintf("C%d",tier);
    % categoryID = S_categories.(tierID);
    % items = S_items.(tierID);
    % % numItems = length(unique(STAT.(strrep(categoryID,"--","_")))); % relative to tier
    % numItems = length(items);
    % if tier==1
    %     xStep = 15;
    %     numFolds=1;        
    % elseif tier > maxTiers
    % else        
    %     numFolds = length(xTick{end-1,1});
    %     xStep = xTick(1) / (numItems);        
    % end
    % 
    % %% FORMAT LAYOUT
    % % xtick spacing (split by items)
    % xTick_new = [xStep-(xStep/2) : xStep : xStep*numFolds*numItems];
    % categories = [categories; strrep(categoryID,"--","_")];


    %% RECURSE
    % V = nexDraw_violin(ax, STAT, SS, floor(xStep/numItems), tier+1, {xTick; xTick_new});
    %% BASE CASE
    % BINNING
    % X = nexStat_binSTAT(STAT, xTick, categories); % assign bins from all possible category combos
    
end