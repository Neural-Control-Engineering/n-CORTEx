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
    % violinplot.m never accepts an axes handle as an argument -- it only
    % ever operates on gca internally (set(gca,...) throughout) -- so ax
    % must be made current first, not passed positionally (passing it
    % positionally silently becomes violinplot's DATA argument instead,
    % which then fails downstream trying to brace-index an axes handle).
    axes(ax);
    % Deliberately NOT passing 'ShowData',false here: Violin.m's own
    % "no explicit ViolinColor given" default-color branch unconditionally
    % references args.scpltBool, a field that is never actually assigned
    % anywhere in Violin.m (confirmed by direct search) -- reachable
    % specifically when ShowData=false short-circuits the scatter-plot
    % creation that branch otherwise falls back on. Left at its default
    % (true) to avoid that broken path entirely; violinplot's own internal
    % scatter (MarkerSize=36) is hidden post-hoc below instead, since
    % nexDraw_scatter already draws a second, consistently-styled (size
    % 100) layer and both rendering at once looks like two overlapping
    % sets of different-sized circles.
    V.v = violinplot(Z);
    for vi = 1:numel(V.v)
        % EdgeColor defaults to a hardcoded grey ([0.5 0.5 0.5], Violin.m's
        % own default) regardless of each violin's own fill color -- sync
        % it to match so the outline reads as part of the same patch
        % rather than a mismatched grey ring.
        V.v(vi).EdgeColor = V.v(vi).ViolinColor{1};
        try
            V.v(vi).ScatterPlot.Visible = 'off';
        catch
        end
    end
    V.s = nexDraw_scatter(ax, Z, V.v);
    V.e = nexDraw_error(ax, Z, C_errorBar);
    colorAx_green(ax);
    hold(ax,"off");   
    % axList = [ax];
    axList= [ax];
    gapOffset = 15;
    ax.XRuler.TickLabelGapOffset=0;
    % violinplot.m sets group labels via plain set(gca,'XTick',...,
    % 'XTickLabels',...) on a numeric axis, not by converting to a true
    % categorical ruler -- ax.XAxis stays a NumericRuler, which has no
    % .Categories property (that only exists on a CategoricalRuler).
    % The actual labels live in .TickLabels regardless of ruler type.
    cats = ax.XAxis.TickLabels;
    % Only build the nested stacked-label overlay axes when there's
    % actually a SECOND tier to nest -- for a single active category,
    % violinplot's own XTick/XTickLabels on ax already show the right
    % thing, and this loop's ax_i = plot(ax_i, categorical(cats), ...)
    % creates a CATEGORICAL-ruler axis that can't linkaxes() against ax's
    % numeric ruler (mismatched limit types), which only matters once
    % there's a second axis in axList to link against in the first place.
    if size(xTicks,1) > 1
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