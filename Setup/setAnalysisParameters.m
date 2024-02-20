function [analysis_params] = setAnalysisParameters(opts)
% SETANALYSISPARAMETERS(windows) Define values that will be referenced for analysis
%   For now, no user input provided. Will parameterize in future. For now
%   will set the defaults below:

%% Extraction config
if ~isfield(opts,"extractCfg"); opts.extractCfg = struct; end
if ~isfield(opts.extractCfg,"EN"); opts.extractCfg.EN = struct; end
if ~isfield(opts.extractCfg,"npxls"); opts.extractCfg.npxls = struct; end
if ~isfield(opts.extractCfg.npxls,"numProbes"); opts.extractCfg.npxls.numProbes =2; end
if ~isfield(opts.extractCfg,"LFP"); opts.extractCfg.LFP=struct; end
if ~isfield(opts.extractCfg.LFP,"reset"); opts.extractCfg.LFP.reset=0; end
if ~isfield(opts.extractCfg,"AP"); opts.extractCfg.AP=struct; end
if ~isfield(opts.extractCfg.AP,"reset"); opts.extractCfg.AP.reset=0; end
if ~isfield(opts.extractCfg.AP,"resetTrigs"); opts.extractCfg.AP.resetTrigs=0; end
if ~isfield(opts.extractCfg,"behavior"); opts.extractCfg.behavior = struct; end
if ~isfield(opts.extractCfg,"SLRT"); opts.extractCfg.SLRT = struct; end
if ~isfield(opts.extractCfg.SLRT,"experiment"); opts.extractCfg.SLRT.experiment = "JOLT"; end
if ~isfield(opts.extractCfg.SLRT,"reset"); opts.extractCfg.SLRT.reset = 0; end

%% Check for which input is provided
if ~isfield(opts,'before_event'); opts.before_event = 0.5; end
if ~isfield(opts,'after_event'); opts.after_event = 0.2; end
if ~isfield(opts,'event_baseline'); opts.event_baseline = 0.5; end

%% (2022-12-22) add two new parameters: (1) MA_window change the window when
% using filtfilt to preprocess isosbestic signal(405), with second as unit.
% (2) debug_mode authorize some functions to plot preliminary plots to
% evaluate those functions and processed data 
if ~isfield(opts,'MA_window'); opts.MA_window = 0.1; end
if ~isfield(opts,'debug_mode'); opts.debug_mode = false; end

%% (2023-05-23) Neuropixels Acquisition Metadata
if ~isfield(opts,'aqcuisition'); opts.acquisition = struct; end
if ~isfield(opts.acquisition,'Fs_lfp'); opts.acquisition.Fs_lfp = 2500; end
if ~isfield(opts.acquisition,'Fs_ap'); opts.acquisition.Fs_ap = 30000; end
if ~isfield(opts.acquisition,'chanMap'); opts.acquisition.chanMap = load("neuropixPhase3A_kilosortChanMap.mat",'chanMap').chanMap; end
if ~isfield(opts.acquisition,'connected'); opts.acquisition.connected = load("neuropixPhase3A_kilosortChanMap.mat",'connected').connected; end
if ~isfield(opts.acquisition,'xcoords'); opts.acquisition.xcoords= load("neuropixPhase3A_kilosortChanMap.mat",'xcoords').xcoords; end
if ~isfield(opts.acquisition,'ycoords'); opts.acquisition.ycoords= load("neuropixPhase3A_kilosortChanMap.mat",'ycoords').ycoords; end
if ~isfield(opts.acquisition,'npxWidth'); opts.acquisition.npxWidth = 4; end % npxlMtrx width is 4 channels to a row
if ~isfield(opts.acquisition,'npxLength'); opts.acquisition.npxLength = 384;

%% (2023-05-26) FOOOF Config params
if ~isfield(opts,'fooof_cfg'); opts.fooof_cfg = struct; end
if ~isfield(opts.fooof_cfg,'method'); opts.fooof_cfg.method = 'mtmfft'; end
if ~isfield(opts.fooof_cfg,'output'); opts.fooof_cfg.output = 'fooof'; end
if ~isfield(opts.fooof_cfg,'export'); opts.fooof_cfg.export = 1; end
% if ~isfield(opts.fooof_cfg,'taper'); opts.fooof_cfg.taper = 'dpss'; end
if ~isfield(opts.fooof_cfg,'tapsmofrq'); opts.fooof_cfg.tapsmofrq= 2.857; end
if ~isfield(opts.fooof_cfg,'foilim'); opts.fooof_cfg.foilim= [0.3 40]; end % bandpass 0.3 to 40 Hz
if ~isfield(opts.fooof_cfg,'pad'); opts.fooof_cfg.pad= 2; end

if ~isfield(opts,'sampleLen'); opts.sampleLen = 0.35; end % duration of entire 0.7 second trial baseline in seconds (before activity of interest)
if ~isfield(opts,'sampleRange'); opts.sampleRange = struct; end
if ~isfield(opts.sampleRange,'target'); opts.sampleRange.target = 'baseline'; end
if ~isfield(opts.sampleRange, 'baseline'); opts.sampleRange.baseline = [(1/opts.acquisition.Fs_lfp) 0.35]; end % first 0.35 seconds of trial
if ~isfield(opts.sampleRange, 'stim'); opts.sampleRange.stim = [(0.35 + 1/opts.acquisition.Fs_lfp) 0.7]; end % last 0.35 seconds of trial

%% Toggle visualisations
if ~isfield(opts,'visuals'); opts.visuals = 1; end % assign '1' to visuals to enable plotting of figures

%% Spectral Band Ranges
if ~isfield(opts,'bands'); opts.bands = struct; end % specify frequency band ranges in format [low, high]
if ~isfield(opts.bands,'delta'); opts.bands.delta = [1, 4]; end  % 1 - 4 Hz
if ~isfield(opts.bands,'theta'); opts.bands.theta = [4, 10]; end % 4 - 10 Hz
if ~isfield(opts.bands,'alpha'); opts.bands.alpha = [10, 15]; end % 10 - 15 Hz
if ~isfield(opts.bands,'beta'); opts.bands.beta = [15, 30]; end % 15 - 30 Hz
if ~isfield(opts.bands,'gamma'); opts.bands.gamma = [30, 100]; end % 30 - 100 Hz
if ~isfield(opts,'fcutoff'); opts.fcutoff = 40; end
if ~isfield(opts,'fstart'); opts.fstart = 5; end

%% Channel masking
if ~isfield(opts,'surfaceChannel'); opts.surfaceChannel = 35; end

%% PATH VARIABLES
if ~isfield(opts,'paths'); opts.paths = struct; end
% if ~isfield(opts.paths,'stem'); opts = initializeStaticPaths(opts); end
% if ~isfield(opts.paths,'data'); opts.paths.data = fullfile(opts.paths.stem,'ds001'); end

%% plotting specParam config
if ~isfield(opts, 'specParamCfg'); opts.specParamCfg = struct; end
if ~isfield(opts.specParamCfg, 'channel'); opts.specParamCfg.channel = 250; end

%% Npxls Scope config
if ~isfield(opts, 'scopeCfg'); opts.scopeCfg= struct; end
if ~isfield(opts.scopeCfg, 'state'); opts.scopeCfg.state = 'neuralBands'; end
if ~isfield(opts.scopeCfg, 'winSize'); opts.scopeCfg.winSize = 10; end % window scaling
if ~isfield(opts.scopeCfg, 'trialNum'); opts.scopeCfg.trialNum = 400; end
if ~isfield(opts.scopeCfg, 'overlap'); opts.scopeCfg.overlap = 90; end % window overlap is 90%
if ~isfield(opts.scopeCfg, 'fftSize'); opts.scopeCfg.fftSize = 2; end % scaling factor of fft (relative to sequence length)
if ~isfield(opts.scopeCfg, 'trialAvgWin'); opts.scopeCfg.dayAvgWin = 5; end % number of days worth of trials in a dataStore to collapse by

%% writeNpxlTnsr Config
if ~isfield(opts, 'wNTCfg'); opts.wNTCfg = struct; end
if ~isfield(opts.wNTCfg, 'DSfield'); opts.wNTCfg.DSfield = 'PSDBands'; end % field name to be written to datastore

%% dayWiseNT Config
if ~isfield(opts, 'DWNTCfg'); opts.DWNTCfg = struct; end
if ~isfield(opts.DWNTCfg, 'field'); opts.DWNTCfg.field = 'Exponent'; end
if ~isfield(opts.DWNTCfg, 'daysWin'); opts.DWNTCfg.daysWin = 5; end

%% Gif Config
if ~isfield(opts, 'gifCfg'); opts.gifCfg = struct; end
if ~isfield(opts.gifCfg, 'frameDelay'); opts.gifCfg.frameDelay = 0.2; end % frame delay is 0.2 seconds

%% Data Writing/Saving Cfg
if ~isfield(opts, 'writeCfg'); opts.writeCfg = struct; end
if ~isfield(opts.writeCfg, 'writeDS'); opts.writeCfg.writeDs = 'auto'; end

%% GOOGLE DRIVE PATH
if ~isfield(opts,'paths'); opts.paths = struct; end
% if ~isfield(opts.paths,'gpath'); opts.paths.gpath = '/home/user/NEC_Drive/Project_Neuromodulation-for-Pain'; end

%% viewAnalysis Cfg
if ~isfield(opts, 'viewCfg'); opts.viewCfg = struct; end
if ~isfield(opts.viewCfg, 'viewNT'); opts.viewCfg.viewNT = struct; end
if ~isfield(opts.viewCfg, 'saveFigs') opts.viewCfg.saveFigs = 1; end
if ~isfield(opts.viewCfg.viewNT, 'displayMode'); opts.viewCfg.viewNT.displayMode='staticMono';end % configure for gif making or static side-by-side presentation of discrete temporal blocks (e.g. trials, days, groups of days)
if ~isfield(opts.viewCfg.viewNT, 'tempRes'); opts.viewCfg.viewNT.tempRes = 'days'; end
if ~isfield(opts.viewCfg,'NT_fields'); opts.viewCfg.NT_fields= struct; end
% implement masking of neuropixels tensors to view/display
if ~isfield(opts.viewCfg.NT_fields, 'baseline_Exponent'); opts.viewCfg.NT_fields.baseline_Exponent = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_Offset'); opts.viewCfg.NT_fields.baseline_Offset= 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_DeltaCF'); opts.viewCfg.NT_fields.baseline_DeltaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_DeltaPW'); opts.viewCfg.NT_fields.baseline_DeltaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_DeltaBW'); opts.viewCfg.NT_fields.baseline_DeltaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_ThetaCF'); opts.viewCfg.NT_fields.baseline_ThetaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_ThetaPW'); opts.viewCfg.NT_fields.baseline_ThetaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_ThetaBW'); opts.viewCfg.NT_fields.baseline_ThetaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_AlphaCF'); opts.viewCfg.NT_fields.baseline_AlphaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_AlphaPW'); opts.viewCfg.NT_fields.baseline_AlphaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_AlphaBW'); opts.viewCfg.NT_fields.baseline_AlphaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_BetaCF'); opts.viewCfg.NT_fields.baseline_BetaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_BetaPW'); opts.viewCfg.NT_fields.baseline_BetaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_BetaBW'); opts.viewCfg.NT_fields.baseline_BetaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_GammaCF'); opts.viewCfg.NT_fields.baseline_GammaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_GammaPW'); opts.viewCfg.NT_fields.baseline_GammaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'baseline_GammaBW'); opts.viewCfg.NT_fields.baseline_GammaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_Exponent'); opts.viewCfg.NT_fields.stim_Exponent = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_Offset'); opts.viewCfg.NT_fields.stim_Offset = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_DeltaCF'); opts.viewCfg.NT_fields.stim_DeltaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_DeltaPW'); opts.viewCfg.NT_fields.stim_DeltaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_DeltaBW'); opts.viewCfg.NT_fields.stim_DeltaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_ThetaCF'); opts.viewCfg.NT_fields.stim_ThetaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_ThetaPW'); opts.viewCfg.NT_fields.stim_ThetaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_ThetaBW'); opts.viewCfg.NT_fields.stim_ThetaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_AlphaCF'); opts.viewCfg.NT_fields.stim_AlphaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_AlphaPW'); opts.viewCfg.NT_fields.stim_AlphaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_AlphaBW'); opts.viewCfg.NT_fields.stim_AlphaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_BetaCF'); opts.viewCfg.NT_fields.stim_BetaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_BetaPW'); opts.viewCfg.NT_fields.stim_BetaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_BetaBW'); opts.viewCfg.NT_fields.stim_BetaBW = 0; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_GammaCF'); opts.viewCfg.NT_fields.stim_GammaCF = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_GammaPW'); opts.viewCfg.NT_fields.stim_GammaPW = 1; end
if ~isfield(opts.viewCfg.NT_fields, 'stim_GammaBW'); opts.viewCfg.NT_fields.stim_GammaBW = 0; end
% if ~isfield(opts.viewCfg.NT_fields, 'PSDBands'); opts.viewCfg.NT_fields.PSDBands = 0; end

%% training set Cfg
if ~isfield(opts,'trainSetCfg'); opts.trainSetCfg=struct;end
if ~isfield(opts.trainSetCfg,'SP_fields'); opts.trainSetCfg.SP_fields= struct; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_Exponent'); opts.trainSetCfg.SP_fields.baseline_Exponent = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_Offset'); opts.trainSetCfg.SP_fields.baseline_Offset= 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_DeltaCF'); opts.trainSetCfg.SP_fields.baseline_DeltaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_DeltaPW'); opts.trainSetCfg.SP_fields.baseline_DeltaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_DeltaBW'); opts.trainSetCfg.SP_fields.baseline_DeltaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_ThetaCF'); opts.trainSetCfg.SP_fields.baseline_ThetaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_ThetaPW'); opts.trainSetCfg.SP_fields.baseline_ThetaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_ThetaBW'); opts.trainSetCfg.SP_fields.baseline_ThetaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_AlphaCF'); opts.trainSetCfg.SP_fields.baseline_AlphaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_AlphaPW'); opts.trainSetCfg.SP_fields.baseline_AlphaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_AlphaBW'); opts.trainSetCfg.SP_fields.baseline_AlphaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_BetaCF'); opts.trainSetCfg.SP_fields.baseline_BetaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_BetaPW'); opts.trainSetCfg.SP_fields.baseline_BetaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_BetaBW'); opts.trainSetCfg.SP_fields.baseline_BetaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_GammaCF'); opts.trainSetCfg.SP_fields.baseline_GammaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_GammaPW'); opts.trainSetCfg.SP_fields.baseline_GammaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'baseline_GammaBW'); opts.trainSetCfg.SP_fields.baseline_GammaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_Exponent'); opts.trainSetCfg.SP_fields.stim_Exponent = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_Offset'); opts.trainSetCfg.SP_fields.stim_Offset = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_DeltaCF'); opts.trainSetCfg.SP_fields.stim_DeltaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_DeltaPW'); opts.trainSetCfg.SP_fields.stim_DeltaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_DeltaBW'); opts.trainSetCfg.SP_fields.stim_DeltaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_ThetaCF'); opts.trainSetCfg.SP_fields.stim_ThetaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_ThetaPW'); opts.trainSetCfg.SP_fields.stim_ThetaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_ThetaBW'); opts.trainSetCfg.SP_fields.stim_ThetaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_AlphaCF'); opts.trainSetCfg.SP_fields.stim_AlphaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_AlphaPW'); opts.trainSetCfg.SP_fields.stim_AlphaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_AlphaBW'); opts.trainSetCfg.SP_fields.stim_AlphaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_BetaCF'); opts.trainSetCfg.SP_fields.stim_BetaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_BetaPW'); opts.trainSetCfg.SP_fields.stim_BetaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_BetaBW'); opts.trainSetCfg.SP_fields.stim_BetaBW = 0; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_GammaCF'); opts.trainSetCfg.SP_fields.stim_GammaCF = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_GammaPW'); opts.trainSetCfg.SP_fields.stim_GammaPW = 1; end
if ~isfield(opts.trainSetCfg.SP_fields, 'stim_GammaBW'); opts.trainSetCfg.SP_fields.stim_GammaBW = 0; end

%% plot Npxls Tnsr Cfg
if ~isfield(opts, 'pltNTCfg'); opts.pltNTCfg = struct; end
if ~isfield(opts.pltNTCfg,'mode'); opts.pltNTCfg.mode = 'dayWise'; end
% if ~isfield(opts.pltNTCfg, 'days2show'); opts.pltNTCfg.days2show = [1:5]; end
if ~isfield(opts.pltNTCfg, 'grps2show'); opts.pltNTCfg.grps2show = [1:5]; end
if ~isfield(opts.pltNTCfg, 'preGrps2show'); opts.pltNTCfg.preGrps2show = [1:5]; end
if ~isfield(opts.pltNTCfg, 'figAspctRatio'); opts.pltNTCfg.figAspctRatio = [4, 12]; end

analysis_params = opts;


% Number of properties to include in the combined processed data
analysis_params.num_of_properties = 30;



end

