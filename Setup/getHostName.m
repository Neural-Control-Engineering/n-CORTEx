function hostName = getHostName()
    if ispc
        hostName = getenv('USERNAME');
    elseif isunix
        hostName = getenv('USER');
    else
        hostName = [];
    end

end