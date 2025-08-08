function [specOut, scores] = formatSpecParamOutputs(spec, args)
    aperiodic_params = double(spec.aperiodic_params);
    peak_params = double(spec.peak_params);
    try
        error = spec.error;
        r_squared = spec.r_squared;
    catch
        error = spec.metrics{'error_mae'};
        r_squared = spec.metrics{'gof_rsquared'};
    end
    
    peak_params_row = reshape(peak_params.',[]  ,1)';
    % pad row according to max peaks configured
    numPeaks_max = args.numPeaks_max;
    peak_params_row = [peak_params_row, zeros(1, numPeaks_max*3 - length(peak_params_row))];    
    specOut = [aperiodic_params, peak_params_row];
    scores = [error, r_squared];
end