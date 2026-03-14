classdef nexObject < handle

    properties
        classID
        Parent
        Partners
        Children
        Origin
        nexon
        DF
        dfID_source
        DF_postOp
        dfID_target
        collector
        domain
        pointer
        Figure
        UserData
        cfg=struct
    end

    methods
        function nexObj = nexObject(nexon, Parent, dfID_source)
            nexObj.nexon = nexon;
            nexObj.Parent = Parent;
            nexObj.dfID_source = dfID_source;
        end

        function setAnimateAxis(nexObj, axKey)
            % Set domain.D2 + animate, recompute D1 as the complement,
            % and update display orientation to reflect new D1.
            nexObj.domain.D2      = string(axKey);
            nexObj.domain.animate = string(axKey);
            nexObj.domain.D1      = string(setdiff(nexObj.domain.axes, axKey, "stable"));
            if ~isempty(nexObj.domain.D1)
                nexObj.domain.display.rows = string(nexObj.domain.D1(1));
                nexObj.domain.display.cols = string(nexObj.domain.D1(min(2, end)));
            end
        end

        function stepAnimate(nexObj, args)
            % CFG HEADER
            stride = args.stride; % default = 1
            % Advance the animation pointer by stride steps along
            % domain.animate, then call visualize(). Wraps around at
            % axis length. Inherited by all nexObject subclasses.
            % domain.animate is written by the UI axSelDropDown so that
            % the axis being stepped is dynamically selectable.
            axSel = nexObj.domain.animate;
            r     = nexObj.DF_postOp.ptr.(axSel).range;   % [start, end] indices
            span  = r(2) - r(1) + 1;
            axVal = r(1) + mod(nexObj.DF_postOp.ptr.(axSel).value - r(1) + stride, span);
            nexObj.DF_postOp = nex_setAxisPointer_v2(nexObj.DF_postOp, axSel, axVal);
            nexObj.visualize();
        end
    end

end