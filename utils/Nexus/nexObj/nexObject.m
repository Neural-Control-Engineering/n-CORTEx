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

        function domain = inferDomain(nexObj)
            % Canonical domain inference — inherited by all nexObject subclasses.
            % First call (domain.D2 not yet set): auto-infers D2 from 't' axis.
            % Subsequent calls (domain.D2 already set): respects existing D2 and
            % animate, recomputing only D1 as the complement.
            % Subclasses may override for non-standard axis layouts.

            axFields = string(fieldnames(nexObj.DF_postOp.ax))';
            domain.axes = axFields;
            domain.F    = string(nexObj.dfID_source);

            % D2: respect existing if set; otherwise auto-infer ('t' → first axis)
            if isfield(nexObj.domain, 'D2') && ~isempty(nexObj.domain.D2)
                domain.D2 = nexObj.domain.D2;
            else
                tKey = axFields(axFields == "t");
                if ~isempty(tKey)
                    domain.D2 = string(tKey(1));
                else
                    domain.D2 = string(axFields(1));
                end
            end

            % animate: respect existing if still a valid member of D2; else D2(1)
            if isfield(nexObj.domain, 'animate') && ~isempty(nexObj.domain.animate) ...
                    && any(domain.D2 == nexObj.domain.animate)
                domain.animate = nexObj.domain.animate;
            else
                domain.animate = domain.D2(1);
            end

            % D1 always recomputed as complement of full D2 array
            domain.D1 = string(setdiff(axFields, domain.D2, "stable"));
        end

        function setAnimateAxis(nexObj, axKey)
            % Replace D2 with the selected axis and re-run inferDomain for D1.
            % D2 is a string array to support future multi-axis selection via
            % nexObj_selectionBus, but the dropdown replaces rather than accumulates.
            nexObj.domain.D2      = string(axKey);
            nexObj.domain.animate = string(axKey);
            nexObj.domain = nexObj.inferDomain();
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