function MLIO_writeDF2HDF5(DF, filename)
% writeHDF5 - Save a DF struct to HDF5
%
% DF: struct with fields
%       - df : N-D numeric array
%       - ax : struct of axis vectors (any number)
% filename: string, path to .h5 file

if nargin < 2
    filename = 'DF.h5';
end

% Delete existing file if it exists
if exist(filename, 'file')
    delete(filename);
end

%% Write main tensor
h5create(filename, '/df', size(DF.df));
h5write(filename, '/df', DF.df);

%% Write axes
axFields = fieldnames(DF.ax);
for i = 1:numel(axFields)
    axName = axFields{i};
    axData = DF.ax.(axName);
    
    % Convert row vectors to column to standardize
    if isrow(axData)
        axData = axData(:);
    end
    
    h5create(filename, ['/ax/', axName], size(axData));
    h5write(filename, ['/ax/', axName], axData);
end

end