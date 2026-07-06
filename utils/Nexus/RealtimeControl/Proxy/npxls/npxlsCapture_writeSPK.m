function npxlsCapture_writeSPK(proxObj, dts, dtsIdx)
% npxlsCapture_writeSPK  Store the 5 RTSort SPK DFs (+ quality) for one captured
% trial into the Nexus DTS, mirroring extSPK's RTS_ prefixed schema.
%
% npxlsCapture_writeSPK(proxObj, dts, dtsIdx)
%   proxObj — proxy_npxls (uses its storeToDTS sink)
%   dts     — formatSpk_toDTS output (activity/spatial/templates/probe/units + axes)
%   dtsIdx  — struct row address (sessionLabel, trialNumber)
%
% Each DF is written FLAT ({df + axis fields}, no nested .ax) so it foliates as
% RTS_spk_<base>_<stub> through dtsIO_writeDF (both new-row compileDTS and
% existing-row writeDF paths) and reads back via dtsIO_composeDF. The unit-quality
% cellstr is folded into the units DF as a non-axis field so it lands as the bare
% sibling column RTS_spk_units_quality (matches extSPK), not a data DF.

    p = "RTS_spk_";

    % activity  (unit x t x measure)
    proxObj.storeToDTS( ...
        struct('df', dts.activity, 'unit', dts.ax_unit, 't', dts.ax_t, 'measure', dts.ax_measure), ...
        p + "activity", dtsIdx);

    % spatial  (unit x chan)
    proxObj.storeToDTS( ...
        struct('df', dts.spatial, 'unit', dts.ax_unit, 'chans', dts.ax_chans), ...
        p + "spatial", dtsIdx);

    % templates  (wf x unit)
    proxObj.storeToDTS( ...
        struct('df', dts.templates, 'wf', dts.ax_wf, 'unit', dts.ax_unit), ...
        p + "templates", dtsIdx);

    % probe  (t x chan)
    proxObj.storeToDTS( ...
        struct('df', dts.probe, 't', dts.ax_t, 'chans', dts.ax_chans), ...
        p + "probe", dtsIdx);

    % units  (unit x factor) + quality sibling. Build with dot-assignment: a cell
    % value in struct(...) would create a struct array, so set quality after.
    U = struct('df', dts.units, 'unit', dts.ax_unit, 'factor', dts.ax_factor);
    U.quality = dts.unit_quality;
    proxObj.storeToDTS(U, p + "units", dtsIdx);
end
