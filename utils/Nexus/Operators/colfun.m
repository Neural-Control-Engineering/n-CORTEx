function varargout = colfun(fun, C)
% COLFUN Apply a function column-wise to an N×B cell array or numeric array
%
% [out1, out2, ...] = colfun(@fun, C)
% fun should accept a column vector and return multiple outputs
% C is N×B
% Each output is returned as a B-column cell array (one column per original column)

B = size(C,2);               % number of columns
nout = nargout;               % number of outputs requested

% preallocate outputs as cell arrays
varargout = cell(1, nout);
for k = 1:nout
    varargout{k} = cell(1,B);
end

% iterate over columns
for b = 1:B
    [tmp{1:nout}] = fun(C(:,b));   % call your function
    for k = 1:nout
        varargout{k}{b} = tmp{k};  % store each output
    end
end
end

% function C = colfun(fun, C)
%     C = arrayfun(@(b) fun(C(:,b)), ...
%                  1:size(C,2), ...
%                  'UniformOutput', false);
%     % C = [C{:}];
%     C = [C(:)];
% end