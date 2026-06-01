function specs = spcpmIO_multiSpecs2vector(SPEC)
    rows = size(SPEC,1);
    specs = [];
    s_AP = [];
    s_PE = [];
    s_FC = [];
    s_OFF = [];
    for i = 1:rows
        r = SPEC(i,:);
        % OFFSET
        if i == 1
            s_OFF =r(1);
        end
        % EXPONENT
        s_AP = [s_AP, r(2)];
        % PERIODIC
        r_PE = r(3:end-1);
        r_PE = r_PE(r_PE~=0);
        s_FC = [s_FC, r(end)];
        s_PE = [s_PE, r_PE];
    end
    if rows < 3
        s_AP=[s_AP,0];
        s_FC=[s_FC,249];
    end
    specs = [s_OFF, s_AP, s_FC, s_PE];
end