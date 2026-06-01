function rgb = nexVis_hexToRGB(hexStr)
% Convert a 6-char hex color string (with or without '#') to [1×3] RGB in [0 1].
    hexStr = strrep(char(hexStr), '#', '');
    if numel(hexStr) == 6
        rgb = [hex2dec(hexStr(1:2)), hex2dec(hexStr(3:4)), hex2dec(hexStr(5:6))] / 255;
    else
        rgb = [0, 1, 0.25];   % cyber-green fallback
    end
end
