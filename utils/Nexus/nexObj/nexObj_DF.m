classdef nexObj_DF < handle & dynamicprops
    properties (SetObservable)
        df
        ax
        ptr
        sem
        % cfg_DF
    end

    methods

        function nexDF = nexObj_DF(DF)
            nexDF = assignFromStruct(nexDF, DF, true);
        end

        function obj = assignFromStruct(obj, S, makeObservable)
            if nargin < 3
                makeObservable = false;
            end

            if ~isstruct(S)
                error('Input must be a struct');
            end

            f = fieldnames(S);

            for k = 1:numel(f)
                name  = f{k};
                value = S.(name);

                % Add property if it doesn't exist
                if ~isprop(obj, name)
                    p = addprop(obj, name);
                    if makeObservable
                        p.SetObservable = true;
                    end
                end

                % Assign value
                obj.(name) = value;
            end        
        end

        % function DF_postOp = operate(DF)
        %     % DF_postOp = DF.cfg_DF.opFcn(DF);
        % end

        % function update(DF)
        % end
    
    end
end