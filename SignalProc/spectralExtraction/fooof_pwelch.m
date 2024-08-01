function freq =  fooof_pwelch(cfg, ftData)    
    hOT = 1;
    % load("fooof_opt.mat");
    data = (ftData.trial{1}');
    % tic
    win = cfg.win;
    nfft = 2048;
    [PSD, f_psd] = pwelch(data, win, floor(win/2), nfft, cfg.Fs);
    % fCond = find(f_psd>0 & f_psd<50);
    % figure; plot(f(fCond), log10(PSD(fCond,10)))
    % toc

    % tic
    [PMT, f_pmt] = pmtm(data, 10, nfft, cfg.Fs ,'Tapers','sine');
    % fCond = find(f>0 & f<50);
    % figure; plot(f(fCond), log10(PmD(fCond,10)))
    % toc

    % tic
    % n=1025;
    % [F] = fft(ftData.trial{1}',n);
    % f = Fs .* ([0:n/2]) / n;
    % fCond = find(f>0 & f<50);
    % figure; plot(f(fCond), log10(abs(F(fCond,350))))
    % toc

    ss= size(PSD');
    TF = reshape(PSD',[ss(1),1,ss(2)]); %e.g. size 384 x 1 x 175 psd    
    [fs, fg] = process_fooof('FOOOF_matlab', TF, f_psd', cfg.opt, hOT);
    % for i = 1:10:384
    %     figure; 
    %     plot(fs, log10(fg(i).fooofed_spectrum));
    %     hold on
    %     plot(fs, fg(i).power_spectrum);
    %     fCond = find(f_pmt >= min(fs) & f_pmt <= max(fs));
    %     plot(f_pmt(fCond), log10(PMT(fCond,1)));
    % end
    freq.fooofparams = fg';
    freq.freq = fs;
    freq.powspctrm_pmt = PMT;
    freq.powspctrm = PSD;
end