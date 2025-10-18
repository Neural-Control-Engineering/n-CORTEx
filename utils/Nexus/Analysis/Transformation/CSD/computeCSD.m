function csd = computeCSD(data, spacing)
    % Compute current source density from extracellular potentials
    % Inputs:
    %   data    - matrix (channels x time) of potential data
    %   spacing - distance between electrodes (scalar)
    % Output:
    %   csd     - matrix of current source density values (channels-2 x time)
    
    % Ensure data has at least three electrodes (rows) to compute second derivative
    assert(size(data, 1) >= 3, 'Data must have at least three electrodes');
    
    % Compute second spatial derivative (Laplacian) across electrodes
    csd = (data(3:end, :) - 2 * data(2:end-1, :) + data(1:end-2, :)) / spacing^2;
end
