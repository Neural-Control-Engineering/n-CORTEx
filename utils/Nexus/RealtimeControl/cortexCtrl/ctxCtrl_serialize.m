function ctx_srl = ctxCtrl_serialize(axElem,elemID)
    switch elemID
        case "CMD"
            ctx_srl = axElem';
        case "PYD"
            ctx_srl = zeros(1,size(axElem,2)*size(axElem,));
            for i = 1
            end
        case "SZE"
    end
end