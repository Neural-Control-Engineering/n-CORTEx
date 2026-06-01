function [specOut, scores] = formatSpecParamOutputs(spec, args)
    
    if isprop(spec,'aperiodic_params')
        aperiodic_params = double(spec.aperiodic_params);
    elseif isprop(spec, 'aperiodic_fit')
        aperiodic_params = double(spec.aperiodic_fit);        
    elseif isfield(spec,'aperiodic_params')
        aperiodic_params = double(spec.aperiodic_params.params);
    end
    if isprop(spec,'peak_params')
        peak_params = double(spec.peak_params);
    elseif isprop(spec,'peak_fit')
        peak_params = double(spec.peak_fit);
    elseif isfield(spec,'periodic_params')
        peak_params = double(spec.periodic_params.params);
    end
    
    try
        error = spec.error;
        r_squared = spec.r_squared;
    catch
        try
            error = spec.metrics{'error_mae'};
            r_squared = spec.metrics{'gof_rsquared'};
        catch
            error = spec.metrics.results{'error_mae'};
            r_squared = spec.metrics.results{'gof_rsquared'};
        end
    end
    
    peak_params_row = reshape(peak_params.',[]  ,1)';
    % pad row according to max peaks configured
    numPeaks_max = args.numPeaks_max;
    peak_params_row = [peak_params_row, zeros(1, numPeaks_max*3 - length(peak_params_row))];    
    specOut = [aperiodic_params, peak_params_row];
    scores = [error, r_squared];
end