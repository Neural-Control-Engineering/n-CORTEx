function labels = nex_coIndexAxisLabels()
% Axis fields that are co-indexed LABELS — one value per element of a sibling
% axis — rather than array dimensions of their own. The canonical case is
% per-unit 'chans' on RTS_spk_activity: it is length n_units and rides along the
% 'unit' dimension (which root channel each sorted unit sits on).
%
% The pointer initializers (nexInit_axisPointer / nex_initAxisPointer_v2) use
% this set together with a shared-length test: when such a label shares its
% length with another axis, it yields the shared df dimension to its sibling and
% takes dim=[]. When its length is unique (e.g. 'chans' on an LFP DF, a genuine
% channel dimension) it is treated normally and keeps its own dimension.
    labels = "chans";
end
