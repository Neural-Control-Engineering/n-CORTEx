function arr = string2array(str)
    % cite: https://www.mathworks.com/matlabcentral/answers/461019-how-to-input-numeric-array-into-edit-filed-using-app-designer#answer_1247609
    str = erase(str, {'[', ']'});
    str = split(str, {' ', ',', ';'});
    arr = str2double(str);
    arr = arr(~isnan(arr));
end