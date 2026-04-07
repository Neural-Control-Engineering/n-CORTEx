function domain = nexInit_domain(DF_postOp, D1)
    % nexInit_domain  Build a domain struct from a DF_postOp axis layout.
    %
    % Usage
    %   domain = nexInit_domain(DF_postOp)          % D1 defaults to "t"
    %   domain = nexInit_domain(DF_postOp, "f")     % explicit D1 override
    %
    % Output fields
    %   domain.D1   — primary axis name (string scalar); "t" for all mdlObjects
    %   domain.D2   — full complement of D1: setdiff(allAxes, D1)
    %   domain.FTR  — feature selection within D2; initialized empty, set by caller
    %
    % D2 is the complete set of non-primary axes.  FTR is a caller-defined
    % subset of D2 used by mdlObjects to select which feature axis to operate
    % on (e.g. "chans", "f") — it need not cover all of D2.
    % Pass [] as DF_postOp to get a stub domain when the Origin DF is not
    % yet available; D2 and FTR will be empty and filled in later.

    if nargin < 2 || isempty(D1)
        D1 = "t";
    end
    D1 = string(D1);

    domain.D1  = D1;
    domain.D2  = string.empty(1, 0);
    domain.FTR = string.empty(1, 0);

    if (isempty(DF_postOp) || ~isstruct(DF_postOp) || ~isfield(DF_postOp, 'ax')) && ~strcmp(class(DF_postOp),"nexObj_DF")
        return;
    end

    axNames    = string(fieldnames(DF_postOp.ax))';
    domain.D2  = setdiff(axNames, D1, "stable");
    domain.FTR = domain.D2;   % backward-compat alias used by applyDomainBus / initReducer
end
