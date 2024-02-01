function initCfg = setCtxInitCfg(ops)
    if ~isfield(ops,'npxls'); ops.npxls = struct; end
    if ~isfield(ops.npxls,'EN'); ops.npxls.EN = 1; end
    if ~isfield(ops.npxls,'labelOrder'); ops.npxls.labelOrder = 1; end

    if ~isfield(ops,'genom'); ops.genom = struct; end
    if ~isfield(ops.genom,'EN'); ops.genom.EN = 1; end
    if ~isfield(ops.genom,'labelOrder'); ops.genom.labelOrder = 2; end

    if ~isfield(ops,'photon'); ops.photon = struct; end
    if ~isfield(ops.photon,'EN'); ops.photon.EN = 1; end
    if ~isfield(ops.photon,'labelOrder'); ops.photon.labelOrder = 3; end

    if ~isfield(ops,'vision'); ops.vision = struct; end
    if ~isfield(ops.vision,'EN'); ops.vision.EN = 1; end
    if ~isfield(ops.vision,'labelOrder'); ops.vision.labelOrder = 4; end

    if ~isfield(ops,'piezo'); ops.piezo = struct; end
    if ~isfield(ops.piezo,'EN'); ops.piezo.EN = 1; end
    if ~isfield(ops.piezo,'labelOrder'); ops.piezo.labelOrder = 5; end

    initCfg = ops;


end