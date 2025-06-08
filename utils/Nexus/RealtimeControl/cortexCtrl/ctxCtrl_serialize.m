function ctx_serial = ctxCtrl_serialize(axElem,elemID)
    nDims = 3;
    len_pyd = 10;
    switch elemID
        case "CMD"
            ctx_serial = axElem';
        case "PYD"
            % ctx_serial = uint8(zeros(1,size(axElem,2)*size(axElem,1))); % serialize transmission
            % ptr = 1; % serial vector pointer
            % for i = 1:size(axElem,1)
            %     pyd = axElem(i,:);                
            %     % pyd = pyd_i(pyd_i~=0); % remove 0 elements
            %     if ~isempty(pyd)
            %         % ctx_serial(ptr:ptr+length(pyd)-1)=pyd;
            %         % ptr = ptr+length(pyd);                
            %         ctx_serial(ptr:ptr+len_pyd-1)=pyd;
            %         ptr = ptr+len_pyd;                
            %     end
            % end
            ctx_serial = reshape(axElem',1,size(axElem,1)*len_pyd);
            % ctx_serial = ctx_serial(ctx_serial~=0);
        case "SZE"
            % ctx_serial = zeros(1,size(axElem,2)*size(axElem,1)); % serialize transmission
            ctx_serial = reshape(axElem',1,size(axElem,1)*size(axElem,2));
            % ptr = 1; % serial vector pointer
            % for i = 1:size(axElem,1)
            %     pyd_i = axElem(i,:);
            %     pyd = pyd_i(pyd_i~=0); % remove 0 elements
            %     if ~isempty(pyd)
            %         ctx_serial(ptr:ptr+length(pyd)-1)=pyd;
            %         ptr = ptr+length(pyd);                
            %     end
            % end
            % ctx_serial = ctx_serial(ctx_serial~=0);
    end
end