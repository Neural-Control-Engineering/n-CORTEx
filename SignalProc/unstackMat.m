function [bins, label] = unstackMat(x)
    % separate each layer/row/col into
    sz = size(x);    
    bins = mat2cell(x,ones(1,sz(1)),sz(2));
    label = [1:sz(1)]';
    label = num2cell(label);
end