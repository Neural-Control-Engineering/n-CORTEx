function mergedObj = mergeObjs(obj1, obj2)
    % mergedStruct = struct();
    
    for i = 1:nargin
        s = varargin{i};
        fields = fieldnames(s);
        for j = 1:numel(fields)
            mergedStruct.(fields{j}) = s.(fields{j});
        end
    end
end