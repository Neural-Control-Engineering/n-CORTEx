function [DF_ap, DF_pe, DF_fit, specs, kernel_args] = nexFit_specParam_legacy(DF, spcpmArgs)

    % CFG HEADER
    fitMode = spcpmArgs.fitMode; % default = 'multiExp'
    scale = spcpmArgs.scale; % default = 'single'
    keepInput = spcpmArgs.keepInput; % default = 0

    switch scale
        case 'single' % use the DF-ptr to slice and operate on single df
            ax_chans = DF.ptr.chans.indices;
            ax_t = DF.ptr.t.indices;
        case 'volume' % iterate through the volume of the DF
            ax_chans = DF.ax.chans;
            ax_t = DF.ax.t;
    end

    ax_chans_out = [];
    ax_t_out = [];
    ax_f = DF.ax.f;
    dim_chans = DF.ptr.chans.dim;
    dim_t = DF.ptr.t.dim;
    numDims = ndims(DF.df);    
    % parfor i = 1:size(ax_chans)
    for i = 1:length(ax_chans)
         idx = repmat({':'},1,numDims-1);
         idx{dim_chans} = ax_chans(i);
         ax_chans_out = [ax_chans_out, ax_chans(i)];
        for j = 1:size(ax_t)                
            idx{dim_t} = ax_t(j);
            ax_t_out = [ax_t_out, ax_t(j)];                    
            % slice
            df_psd = DF.df(idx{:});
            spcpmArgs = extractMethodCfg('specParam_multiExp');
            [specs, kernel_args, psd_fit] = specParam_multiExp(ax_f, df_psd, spcpmArgs);
            % [args_opt, fit, d] = specParam_jointFit(ax_f, df_psd, kernel_args, true, 1);
            
        end
    end
    
    DF_out = [];
    
end