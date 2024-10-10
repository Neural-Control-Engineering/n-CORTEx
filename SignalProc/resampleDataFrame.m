function upsampledDf = resampleDataFrame(psd, nPoints)
    % resampleDataFrame resamples the input PSD matrix to have nPoints columns.
    %
    % Inputs:
    %   psd      - Input PSD matrix of size MxN (M rows, N columns)
    %   nPoints  - Desired number of columns after resampling (default is 195)
    %
    % Outputs:
    %   upsampledPSD - The resampled PSD matrix with M rows and nPoints columns.

    % If nPoints is not provided, default to 195
    if nargin < 2
        nPoints = 195;
    end

    % Get the size of the input PSD
    [nRows, nCols] = size(psd);
    
    % Define the original and new frequency points for interpolation
    originalPoints = linspace(1, nCols, nCols);
    newPoints = linspace(1, nCols, nPoints);
    
    % Preallocate the upsampled PSD matrix
    upsampledDf = zeros(nRows, nPoints);
    
    % Perform interpolation row-wise
    for i = 1:nRows
        upsampledDf(i, :) = interp1(originalPoints, psd(i, :), newPoints, 'linear');
    end
end