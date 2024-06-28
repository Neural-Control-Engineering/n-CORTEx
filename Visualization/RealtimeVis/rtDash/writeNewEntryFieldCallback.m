function value = writeNewEntryFieldCallback(panel, rtStream, fieldRef)    
    value = panel.(fieldRef).uiField.Value;
    switch class(value)
        case "double"
            if size(value,2) == 1
                panel.(fieldRef).editField = value;
                rtStream.streamCfg.(fieldRef) = value;
            elseif size(value,2) > 1
                panel.(fieldRef).editField = string2array(value);
                rtStream.streamCfg.(fieldRef) = string2array(value);
            end
        case "char"
            try                
                rtStream.streamCfg.(fieldRef) = string2array(value);
            catch e
                disp(e);
            end
    end
end