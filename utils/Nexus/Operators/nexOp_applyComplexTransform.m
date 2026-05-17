function [df_out, sem_out] = nexOp_applyComplexTransform(df_in, sem_in, component, scale)
% Apply component then scale transforms in sequence.
%
%   component : 'radial'  → abs(df)      (magnitude)
%               'angular' → angle(df)    (phase, rad); SEM zeroed
%               otherwise → identity (real(df) if complex)
%   scale     : 'log'     → 10*log10(|df|+eps)  SEM via delta method
%               otherwise → identity
%
% sem_in may be [] — sem_out will match.
% Component is only applied when df_in is complex; real data passes through.

    sem_out = sem_in;

    % Step 1: component transform (complex → real)
    if ~isreal(df_in)
        switch lower(char(component))
            case 'radial'
                df_out = abs(df_in);
                if ~isempty(sem_in)
                    sem_out = abs(sem_in);
                end
            case 'angular'
                df_out  = angle(df_in);
                sem_out = [];
            otherwise
                df_out = real(df_in);
        end
    else
        df_out = df_in;
    end

    % Step 2: scale transform
    if strcmpi(scale, 'log')
        linearDF = abs(df_out) + eps;
        if ~isempty(sem_out)
            sem_out = (10 / log(10)) * abs(sem_out) ./ linearDF;
        end
        df_out = 10 * log10(linearDF);
    end
end
