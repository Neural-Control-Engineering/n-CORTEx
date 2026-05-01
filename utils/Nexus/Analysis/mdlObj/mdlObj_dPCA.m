classdef mdlObj_dPCA < mdlObject
% dPCA model object.
%
% Parent must be a nexObj_categorical whose dfID_source holds SSM (or other)
% latent trajectories compiled by compileSTAT into STAT.df cells (T × N_lat).
%
% Requires the Kobak dPCA MATLAB library on the MATLAB path:
%   dpca(), dpca_optimizeLambda(), dpca_explainedVariance()
%   https://github.com/machenslab/dPCA

    properties
    end

    methods
        function mdlObj = mdlObj_dPCA(Parent, Origin, dfID_source, headline)
            if nargin < 4, headline = []; end
            mdlObj = mdlObj@mdlObject(Parent, Origin, "dpca", dfID_source, [], headline);
            mdlObj.cfg.dmCfg.format = "dpca";
            mdlObj.domain.FTR       = mdlObj.domain.D2(1);
        end

        function [STAT, idxSel, drop] = compileSTAT(mdlObj)
            [STAT, idxSel, drop] = compileSTAT@mdlObject(mdlObj);
            if isempty(mdlObj.UserData), mdlObj.UserData = struct(); end
            % idxSel marks all selected DTS rows; drop marks which of those were
            % empty and removed by nexOp_compileSTAT. Surviving rows = selected
            % minus dropped, so the index vector stays aligned with STAT rows.
            allIdx = find(idxSel);
            if ~isempty(drop) && numel(drop) == numel(allIdx)
                mdlObj.UserData.idxSel_rows = allIdx(~drop);
            else
                mdlObj.UserData.idxSel_rows = allIdx;
            end
        end

        function getDesignMatrix(mdlObj)
            % Compute training-subset DTS indices before stat2dm_dpca needs them.
            if isfield(mdlObj.UserData, 'idxSel_rows') && ~isempty(mdlObj.UserData.idxSel_rows)
                if ~isempty(mdlObj.trainMask)
                    mdlObj.UserData.idxSel_train = ...
                        mdlObj.UserData.idxSel_rows(mdlObj.trainMask == 1);
                else
                    mdlObj.UserData.idxSel_train = mdlObj.UserData.idxSel_rows;
                end
            end
            getDesignMatrix@mdlObject(mdlObj);
        end

        function DF_Z = transform(mdlObj, DF_X)
            % Project latent trajectory through dPCA decoder W.
            % DF_X.df : (T × N_latents)
            % DF_Z.df : (T × nComp)
            X = DF_X.df;
            if isempty(X) || isempty(mdlObj.W)
                DF_Z = [];
                return;
            end
            Z = X * mdlObj.W.W;          % (T × nComp), W is (N_latents × nComp)
            DF_Z = rmfield(DF_X, {'ptr', 'ax'});
            DF_Z.df  = Z;
            DF_Z.ax.(mdlObj.domain.D1) = DF_X.ax.(mdlObj.domain.D1);
            DF_Z.ax.latent = 1:size(Z, 2);
            DF_Z = nex_initAxisPointer_v2(DF_Z);
        end

        function saveFit(mdlObj, uniqueID)
            nexon   = mdlObj.nexon;
            rootDir = nexon.console.BASE.params.paths.Data.FTR.local;
            fitDir  = fullfile(rootDir, sprintf("mdlObj_dpca_%s", uniqueID));
            mkdir(fitDir);
            W = mdlObj.W; %#ok<NASGU>
            save(fullfile(fitDir, "dpca_weights.mat"), "W");
            mdlObj.fitPath = fitDir;
            fprintf("[mdlObj_dPCA] saved: %s\n", fitDir);
        end

        function loadFit(mdlObj, fitDir)
            if nargin < 2 || isempty(fitDir)
                fitDir = uigetdir(pwd, "Select dPCA fit folder");
                if isequal(fitDir, 0), return; end
            end
            S = load(fullfile(fitDir, "dpca_weights.mat"), "W");
            mdlObj.W = S.W;
            mdlObj.fitPath = fitDir;
            fprintf("[mdlObj_dPCA] loaded: %s\n", fitDir);
        end
    end
end
