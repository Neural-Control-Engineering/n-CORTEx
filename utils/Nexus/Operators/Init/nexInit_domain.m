function domain = nexInit_domain(DF_postOp, DN)
    % nexInit_domain  Build a domain struct from a DF_postOp axis layout.
    %
    % Usage
    %   domain = nexInit_domain(DF_postOp)            % DN defaults to "t"
    %   domain = nexInit_domain(DF_postOp, "f")       % explicit DN override
    %   domain = nexInit_domain(DF_postOp, ["t","f"]) % multi-axis training domain
    %
    % Output fields
    %   domain.DN   — training-domain axis name(s) (string array). "t" alone
    %                 is the common single-axis case every mdlObject defaults
    %                 to. Multiple entries mean the model trains/is scored
    %                 jointly across those physical axes (e.g. time AND
    %                 frequency) — scoring itself is not yet generalized for
    %                 the multi-axis case (still resolves against DN(1)).
    %   domain.D2   — full complement of DN: setdiff(allAxes, DN)
    %   domain.FTR  — feature selection within D2; initialized empty, set by caller
    %
    % D2 is the complete set of non-DN axes.  FTR is a caller-defined
    % subset of D2 used by mdlObjects to select which feature axis to operate
    % on (e.g. "chans", "f") — it need not cover all of D2.
    % Pass [] as DF_postOp to get a stub domain when the Origin DF is not
    % yet available; D2 and FTR will be empty and filled in later.

    if nargin < 2 || isempty(DN)
        DN = "t";
    end
    DN = string(DN);

    domain.DN  = DN;
    domain.D2  = string.empty(1, 0);
    domain.FTR = string.empty(1, 0);
    domain.REG = "None";

    if (isempty(DF_postOp) || ~isstruct(DF_postOp) || ~isfield(DF_postOp, 'ax')) && ~strcmp(class(DF_postOp),"nexObj_DF")
        return;
    end

    axNames    = string(fieldnames(DF_postOp.ax))';
    domain.D2  = setdiff(axNames, DN, "stable");
    domain.FTR = domain.D2;   % backward-compat alias used by applyDomainBus / initReducer
end
