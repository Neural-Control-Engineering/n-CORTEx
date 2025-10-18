function DF_out = fCWT(DF_in, args)
    
    % CFG HEADER
    chanRange_start = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384       

    Fs = args.Fs;
    try
        preBuffLen = args.preBuffLen;
    catch
        preBuffLen = 0;
    end
    % fcwt = py.importlib.import_module('fcwt');
    chans = [chanRange_start: chanRange_end];
    % Calculate CWT without plotting...
    df = DF_in.df;
    S = {};    
    F = {};    
    parfor i = chans

        Fs = args.Fs; % default = 500

        f0 = py.int(args.fRange_start);
        f1 = py.int(args.fRange_end);
        fn = f1-f0;
        chans = [chanRange_start: chanRange_end];
        Fs = py.int(Fs);

        df_slice = df(i, :, :);
        df_slice = py.numpy.array(df_slice,pyargs('dtype','float64'));
        fcwt_mod = py.importlib.import_module('fcwt');
        out = fcwt_mod.cwt(df_slice, Fs, f0, f1, fn);
        df_out = flip(double(out{2}),1);
        % df_out = double(out{2});
        freqs = flip(double(out{1}),2);
        F{i} = freqs;
        % f = single(out{1});
        % s = struct('first', double(out{1}), 'second', double(out{2}));
        S{i} = df_out;
    end

    % assemble result
    df_out = cat(3, S{:});
    df_out = permute(df_out, [3, 1, 2]);
    DF_out.df=df_out;
    try
        DF_out.ax = DF_in.ax;
    catch e
        disp(getReport(e));
    end
    DF_out.ax.f = F{1};
    DF_out.ax.t = [1:size(df_out,3)] ./ Fs - preBuffLen;
    DF_out.ax.chans = chans;
end