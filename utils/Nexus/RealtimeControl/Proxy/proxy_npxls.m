classdef proxy_npxls < handle
    properties
        proxon
        nCORTEx
        proxyID = "npxls";  
        type=2
        Server      
        compCfg
        nexFigures % handles to interactive figures
        stream
        writeBuffer
        readBuffer
        captureBuffer
        EN_capStream
        EN_rtStream
        controlPanel
        % --- capture state (bracket + single-fetch; see REALTIME_CAPTURE_STREAM_DESIGN.md) ---
        probeIndex = 0      % imec probe index (js=2)
        preBuffLen = 3.5    % seconds of pre-trial lead-in to include (mirrors extLFP)
        niInsertChan = 2    % NI channel carrying the speedgoat insert (trigger mark); mirrors nidq.dataArray(2,:) offline
        niSyncChan   = 9    % NI channel carrying the 1Hz pulser (NI↔imec calibration); mirrors nidq.dataArray(9,:)
        capAlignGuard = 0.5 % extra pre-buffer (s) grabbed so the insert can be cropped back to preBuffLen despite latency
        capNiFs             % NI stream sample rate at capture start
        capInsertOffset = NaN % insert time (s) from the window start, measured at arm time; consumed by the stopCapture crop
        capAlignLog = []    % per-trial [trialNum, insertOffset_s, latency_ms] from the NI insert edge
        lfTargetFs = 500    % LFP decimation target (Hz), matches offline extLFP
        streamWindowLen = 15000 % FetchLatest window (samples) for readData
        capStartSamp        % ring-buffer sample index marked at startCapture
        capReadHead         % next unread sample index (advances as drainCapture runs)
        capChanCounts       % [nAP, nLF, nSY] from GetStreamAcqChans at capture start
        capFs               % imec stream sample rate at capture start
        capTrialNum         % trial number for the active capture (DTS row address)
        maxTrialAssigned = 0 % monotonic floor: highest trial index handed out this session
        maxTrialSL = ""      % sessionLabel that maxTrialAssigned belongs to
        discardedTrials = [] % trial numbers whose capture sink must be skipped (discard-before-sink race)
        capTimer            % drain safety timer (fires only for long captures)
        ringBufferSec = 8   % conservative estimate of SpikeGLX stream buffer depth (s)
        capDrainSafety = 0.5 % drain interval = ringBufferSec*this (keep buffer < half full)
        % --- RTSort sidecar (Phase 2) ---
        pyExe = "C:\Users\Primus\miniconda3\envs\nexus\python.EXE"
        rtSortPort = 5665
        rtSortClient        % tcpclient to the persistent RTSort sidecar
        rtSortAutoLaunch = true  % false → don't spawn; attach to a manually-run sidecar
        spkBin_s = 0.005    % SPK bin width (s), matches offline formatSpk_toDTS
        spkSigma_s = 0.025  % SPK rate-smoothing sigma (s)
        spkStatic           % cached static spk_struct (templates/spatial/locs/... — built once)
        sorterReady = false % true once a sorter is built (detectSequences) or loaded (loadSorter)
        sorterDir           % on-disk dir of the active sorter (rt_sort.pickle + rtsort_results.mat)
        detectDurSec = 60   % training window duration (s) accumulated for detectSequences
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_npxls(serverIP, nCORTEx)
            startSGL();
            % SpikeGL('start');
            % application handle
            proxObj.nCORTEx = nCORTEx;
            proxObj.Server = SpikeGL(char(serverIP)); % spikeGL            
            proxObj.writeBuffer = timer("ExecutionMode","fixedRate","BusyMode","queue","Period",0.1,"TimerFcn",@(~,~)proxObj.readData);                        
        end

        % Fetch data
        function df = readData(proxObj)
            df = FetchLatest(proxObj.Server, 2, 0, proxObj.streamWindowLen);
            % computation during fetching
            % visualize during fetching
            % return template data if server does not exist
        end

        function updateSessionLabel(proxObj, SL)
            % remove gate suffix
            ungatedSL = split(SL,'_');
            ungatedSL = ungatedSL(1:end-1);
            ungatedSL = string(join(ungatedSL,'_'));
            % SpikeGLX won't accept a run name until its run parameters have
            % been verified once (the console's Detect/Verify step). Clear
            % that gate here with a scratch name so the real SetRunName below
            % succeeds without a manual pass through the console.
            if ~IsRunning(proxObj.Server)
                % proxObj.validateRunParameters();
                SetRunName(proxObj.Server, char(ungatedSL));
            end
        end

        function ok = validateRunParameters(proxObj)
            % Reproduce the SpikeGLX console "validate" step over the remote
            % API: set a scratch run name, then round-trip the last-used run
            % parameters through the server. SetParams validates server-side
            % and errors on a bad param, so a clean return means the run is
            % verified and ready to accept the real run name.
            ok  = false;
            srv = proxObj.Server;
            if IsRunning(srv), return; end                 % can't set params mid-run
            if ~IsInitialized(srv)
                warning("proxy_npxls:notInitialized", ...
                    "SpikeGLX not finished initializing; skipping run-parameter validation.");
                return;
            end
            try
                % SetRunName(srv, '_validate_tmp');          % scratch name satisfies the validate gate
                % load default params
                load(fullfile(proxObj.nCORTEx.params.paths.repo_path,"Setup/","npxls/","sglxparams.mat"))
                % SetParams(srv, GetParams(srv));            % force server-side parameter validation
                SetParams(srv, sglxparams);            % force server-side parameter validation
                % If a bare SetParams round-trip proves insufficient at the
                % rig (probe not detected), swap the line above for a momentary
                % StartRun(srv); StopRun(srv); on the scratch name to force a
                % full detect+verify.
                ok = true;
            catch e
                warning("proxy_npxls:validateFailed", ...
                    "Run-parameter validation failed: %s", e.message);
            end
        end

        function captureDataStream_npxls(proxObj, pyd, sze)
            % buffer lfp data (with time-stamp)
            % for pyd-designated seconds
            duration_capture = pyd(1);
            t_start_slrt = pyd(2);
            subModSel = pyd(3); % ap or lfp or both
            for i = 1:duration_capture
                if i ==1 % keep 3.5 seconds prior
                else
                end
            end
            % write back
            DF.df=captureData;
            DF.ax=[];
            DF.label=[];
            proxObj.proxon.proxObjs.nexus_1.writeCapture(DF);
            % RelayToParentProxies(proxObj,"writeCapture",DF,[]);
        end

        function startCapture_ap(proxObj, pyd, sze)

        end

        function openControlPanel(proxObj, pyd, sze)
            proxObj.controlPanel = nexObj_controlPanel_npxls([],proxObj.nCORTEx);
        end

        % --- ad-hoc capture: SLRT relays startCapture/stopCapture (ctrlKey 3/4) ---
        function n = nextTrialNum(proxObj)
            % Host-owned trial counter: next index for the active session.
            % Base = max existing trialNumber for this sessionLabel in the DTS
            % (survives proxy reconstruction, stays aligned with offline rows),
            % but FLOORED by maxTrialAssigned — the highest index handed out this
            % session — so a discard that deletes the top row (dropping the DTS
            % max) does NOT roll the counter back and reuse a number the host has
            % already advanced past. The floor applies only within the same
            % sessionLabel; a new session starts fresh from the DTS.
            SL = "";
            try, SL = string(proxObj.nCORTEx.params.sessionLabel); catch, end
            dtsMax = 0;
            try
                nexon = proxObj.proxon.nexon;
                DTS   = nexon.console.BASE.DTS;
                if istable(DTS) ...
                        && ismember('sessionLabel', DTS.Properties.VariableNames) ...
                        && ismember('trialNumber',  DTS.Properties.VariableNames)
                    m = DTS.trialNumber(string(DTS.sessionLabel) == SL);
                    m = m(~isnan(m));
                    if ~isempty(m), dtsMax = double(max(m)); end
                end
            catch e
                disp(getReport(e));
            end
            floorVal = 0;
            if strlength(SL) > 0 && SL == proxObj.maxTrialSL
                floorVal = proxObj.maxTrialAssigned;
            end
            n = max(dtsMax, floorVal) + 1;
        end

        function startCapture(proxObj, pyd, sze)
            % Mark the imec ring-buffer head (minus pre-buffer) as the capture
            % window start and arm the drain safety timer. pyd(1) = trial number
            % from the speedgoat — honored when it carries a valid (>0) index;
            % otherwise the host auto-assigns the next trial for the active
            % session so back-to-back captures advance the DTS row instead of
            % overwriting trial 0.
            if nargin < 2, pyd = []; end
            trialNum = 0;
            if ~isempty(pyd), trialNum = double(pyd(1)); end
            if ~(isscalar(trialNum) && isfinite(trialNum) && trialNum > 0)
                trialNum = proxObj.nextTrialNum();
            end
            ip = proxObj.probeIndex;
            Fs   = GetStreamSampleRate(proxObj.Server, 2, ip);
            head = GetStreamSampleCount(proxObj.Server, 2, ip);
            % Grab preBuffLen + capAlignGuard of lead. The guard is cropped back
            % out in stopCapture once the NI insert pin-points the true trigger,
            % leaving exactly preBuffLen of pre-trigger context regardless of the
            % LAN/scheduling latency between the host trigger and this call.
            proxObj.capStartSamp  = max(0, head - round((proxObj.preBuffLen + proxObj.capAlignGuard) * Fs));
            proxObj.capReadHead   = proxObj.capStartSamp;
            proxObj.captureBuffer = [];                                         % samples x channels (int16)
            proxObj.capChanCounts = GetStreamAcqChans(proxObj.Server, 2, ip);   % [nAP, nLF, nSY]
            proxObj.capFs         = Fs;
            proxObj.capTrialNum   = trialNum;
            % Insert-based alignment (the speedgoat insert lives on NIDQ, not
            % imec). Locate it NOW from the freshest NI samples — the insert fired
            % just before this call — and store its offset for the stopCapture
            % crop. NI absent → capInsertOffset stays NaN and alignment is skipped
            % (nominal guard-only crop).
            proxObj.capNiFs         = [];
            proxObj.capInsertOffset = NaN;
            try
                niFs   = GetStreamSampleRate(proxObj.Server, 0, 0);
                niHead = GetStreamSampleCount(proxObj.Server, 0, 0);
                proxObj.capNiFs = niFs;
                % Locate the insert NOW, from the freshest NI samples (it fired
                % just before this call). Doing it here — not at stopCapture —
                % avoids reaching back past the NI ring depth ("FETCH: Too late").
                proxObj.detectInsertOffset(niHead);
            catch e
                disp(getReport(e));
            end
            % Advance the monotonic per-session floor so a later discard of the
            % top row can't make nextTrialNum reuse this index (covers both the
            % speedgoat-pyd and auto-assigned paths).
            capSL = "";
            try, capSL = string(proxObj.nCORTEx.params.sessionLabel); catch, end
            if capSL ~= proxObj.maxTrialSL
                proxObj.maxTrialSL       = capSL;
                proxObj.maxTrialAssigned = 0;
                proxObj.discardedTrials  = [];   % new session — clear stale discard flags
            end
            proxObj.maxTrialAssigned = max(proxObj.maxTrialAssigned, trialNum);
            proxObj.EN_capStream  = true;
            % Drain safety timer. It fires only if the capture outlives one drain
            % interval (kept below the ring-buffer depth), so short trial-scale
            % captures pay zero steady overhead — the timer never fires and
            % stopCapture does a single Fetch (the bracket). Long captures get
            % drained into captureBuffer before the ring buffer can overrun.
            proxObj.capTimer = timer("ExecutionMode","fixedRate","BusyMode","drop", ...
                "Period", max(0.05, proxObj.ringBufferSec * proxObj.capDrainSafety), ...
                "TimerFcn", @(~,~)proxObj.drainCapture);
            start(proxObj.capTimer);
        end

        function drainCapture(proxObj)
            % Fetch every sample acquired since capReadHead into captureBuffer and
            % advance the read pointer. Called periodically by capTimer (long
            % captures) and once by stopCapture (final flush — and the sole fetch
            % for short captures, where it reduces to the bracket single-Fetch).
            ip = proxObj.probeIndex;
            head = GetStreamSampleCount(proxObj.Server, 2, ip);
            n = head - proxObj.capReadHead;
            if n <= 0, return; end
            [chunk, headCt] = Fetch(proxObj.Server, 2, ip, proxObj.capReadHead, n, [-1]);
            if headCt > proxObj.capReadHead
                warning("npxls:capOverrun", ...
                    "drain lost %d samples (ring buffer overran) — raise capDrainSafety cadence or ringBufferSec", ...
                    headCt - proxObj.capReadHead);
            end
            proxObj.captureBuffer = [proxObj.captureBuffer; chunk];   % append along samples
            proxObj.capReadHead   = headCt + size(chunk,1);          % next unread sample
        end

        function stopCapture(proxObj, pyd, sze)
            % Stop draining, flush the tail, then slice AP/LF/SY, build the LFP +
            % SPK DFs, and store them to the Nexus DTS under the trial row.
            if ~isequal(proxObj.EN_capStream, true)
                disp("stopCapture: no active capture");
                return
            end
            if ~isempty(proxObj.capTimer) && isvalid(proxObj.capTimer)
                stop(proxObj.capTimer); delete(proxObj.capTimer);
            end
            proxObj.capTimer = [];
            proxObj.drainCapture();                 % final flush (or the only fetch, short captures)
            mat = proxObj.captureBuffer;            % samples x channels
            proxObj.captureBuffer = [];
            proxObj.EN_capStream  = false;
            if isempty(mat)
                disp("stopCapture: empty capture window");
                return
            end
            % Re-align the window to the speedgoat insert (NIDQ) BEFORE splitting
            % AP/LF, so LFP and SPK inherit the same corrected window. Crops the
            % guard so the trigger sits at exactly preBuffLen; logs latency.
            mat = proxObj.alignCaptureToInsert(mat);

            % imec stream columns are ordered [AP, LF, SY]
            cc  = proxObj.capChanCounts;
            nAP = cc(1); nLF = cc(2);
            lfMat = mat(:, nAP + (1:nLF));          % LF band (samples x nLF)
            apMat = mat(:, 1:nAP);                  % AP band (samples x nAP)
            T = size(mat,1) / proxObj.capFs;        % window duration (s)

            % --- SINK address: (sessionLabel, trialNumber), mirror offline DTS ---
            SL = string(proxObj.nCORTEx.params.sessionLabel);
            dtsIdx = struct('sessionLabel', SL, 'trialNumber', proxObj.capTrialNum);

            % --- LFP DF ---
            % preBuffLen shifts t so 0 = the (re-aligned) trigger, pre-context negative.
            DF_lfp = npxlsCapture_toLFP(lfMat, proxObj.capFs, proxObj.lfTargetFs, proxObj.preBuffLen);
            noiseRmArgs = extractMethodCfg('nex_pcaNoiseRm');
            DF_lfp = nex_pcaNoiseRm(DF_lfp, noiseRmArgs);
            proxObj.storeToDTS(DF_lfp, "lfp", dtsIdx);

            % --- SPK DFs (RTSort sidecar → formatSpk_toDTS schema) ---
            try
                proxObj.buildSPK_DF(apMat, T, dtsIdx);
            catch e
                warning("npxls:spkFailed", "SPK build failed: %s", e.message);
            end

            % --- route the scene to the just-written trial, then launch figures ---
            % Re-route first so any figure launched this call reads the new trial
            % at construction; nex_routeToTrial also refreshes already-open ones.
            try
                nexon = proxObj.proxon.nexon;
                if ~isempty(nexon)
                    nex_routeToTrial(nexon, SL, proxObj.capTrialNum);
                    nexLaunch_auto(nexon, "stopCapture");
                end
            catch e
                warning("npxls:autoLaunch", "auto-launch/route failed: %s", e.message);
            end
        end

        function detectInsertOffset(proxObj, niHead)
            % Locate the speedgoat insert pulse in the NIDQ stream AT capture-arm
            % time, from a short window ending at the current stream head (niHead).
            %
            % WHY HERE (not stopCapture): the insert fired just BEFORE this call —
            % it's what triggered the capture — so it sits within ~latency of the
            % head, i.e. the freshest samples in the ring buffer. Fetching it now
            % never reaches past the NI ring depth, so it can't hit SpikeGLX
            % "FETCH: Too late" the way a retrospective stopCapture fetch does.
            %
            % Result → capInsertOffset: the insert's time (s) from the (extended)
            % window start, consumed later by alignCaptureToInsert to crop the imec
            % window. NaN if not found. Also logs [trialNum, offset_s, latency_ms].
            proxObj.capInsertOffset = NaN;
            niFs = proxObj.capNiFs;

            % Head-anchored window: capAlignGuard (the max latency we can correct)
            % plus a small margin so a slightly-over-guard latency is still seen
            % (and reported) rather than silently missed.
            nFetch = round((proxObj.capAlignGuard + 0.25) * niFs);
            fStart = max(0, niHead - nFetch);
            nFetch = niHead - fStart;                        % clamp near stream start
            if nFetch <= 0, return; end

            % Pull the insert channel (all channels, then column niInsertChan —
            % mirrors the offline nidq.dataArray(2,:) indexing).
            insert = [];
            try
                [niChunk, ~] = Fetch(proxObj.Server, 0, 0, fStart, nFetch, [-1]);
                if ~isempty(niChunk) && size(niChunk,2) >= proxObj.niInsertChan
                    insert = double(niChunk(:, proxObj.niInsertChan));
                end
            catch e
                disp(getReport(e));
                return
            end
            if isempty(insert), return; end

            % First rising edge, thresholded at the channel's mid-level so it works
            % regardless of the pulse's absolute amplitude/units.
            lo = min(insert); hi = max(insert);
            if hi - lo < eps, return; end                    % flat → no pulse in window
            above  = insert > (lo + 0.5*(hi - lo));
            eLocal = find(above(2:end) & ~above(1:end-1), 1, 'first') + 1;  % low→high
            if isempty(eLocal), return; end

            % Latency L = distance from the insert edge to the head. eLocal is a
            % 1-based index; the edge is (eLocal-1) samples after fStart, and the
            % head is nFetch samples after fStart, so the gap is nFetch-(eLocal-1)
            % samples. That is exactly how "late" this call ran vs the true trigger.
            L = (nFetch - (eLocal - 1)) / niFs;              % seconds

            % Express as offset from the extended window start so the imec crop can
            % place it at preBuffLen: the window start is (preBuffLen+guard) before
            % the head, the insert is L before the head → (preBuffLen+guard - L) in.
            proxObj.capInsertOffset = (proxObj.preBuffLen + proxObj.capAlignGuard) - L;
            proxObj.capAlignLog = [proxObj.capAlignLog; ...
                                   proxObj.capTrialNum, proxObj.capInsertOffset, L*1000];
            fprintf("capAlign trial %d: insert %.1f ms before head (%.4fs into window)\n", ...
                    proxObj.capTrialNum, L*1000, proxObj.capInsertOffset);
        end

        function mat = alignCaptureToInsert(proxObj, mat)
            % Crop the captured imec window so the speedgoat insert lands at
            % EXACTLY preBuffLen from the start, using the offset detectInsertOffset
            % measured at capture-arm time. This removes the per-trial LAN/
            % scheduling latency AND the extra capAlignGuard lead, leaving the fixed
            % pre-trigger context the LFP/SPK DFs (and offline extLFP) assume, so
            % realtime + offline trials pool. Runs BEFORE the AP/LF split in
            % stopCapture, so LFP and SPK share one aligned window.
            Fs        = proxObj.capFs;                        % imec stream rate (Hz)
            guardSamp = round(proxObj.capAlignGuard * Fs);    % guard length in imec samples

            % Default when the insert wasn't found (NI off, flat, no edge): just
            % drop the guard we added, leaving a nominal (unaligned) preBuffLen
            % window rather than one carrying the extra lead. `lead` = front trim.
            lead    = guardSamp;
            tInsert = proxObj.capInsertOffset;

            if ~isnan(tInsert)
                % #samples between the window start and where we want the insert
                % (preBuffLen). Positive → trim that many off the front so the
                % insert moves back to preBuffLen. Negative means the insert is
                % earlier than preBuffLen even with the guard (latency > guard) —
                % we can't manufacture pre-context, so keep the guard-only crop.
                leadAligned = round((tInsert - proxObj.preBuffLen) * Fs);
                if leadAligned >= 0
                    lead = leadAligned;
                else
                    warning("npxls:capAlign", ...
                        "trial %d: latency exceeds guard %.0f ms — not fully aligned (raise capAlignGuard)", ...
                        proxObj.capTrialNum, proxObj.capAlignGuard*1000);
                end
            else
                warning("npxls:capAlign", ...
                    "trial %d: insert not found at arm time — window not re-aligned", proxObj.capTrialNum);
            end

            % Apply the front trim. Guarded so a degenerate lead never empties it.
            if lead > 0 && lead < size(mat,1)
                mat = mat(lead+1:end, :);
            end
        end

        function flagDiscardTrial(proxObj, trialNum)
            % Mark a trial so its capture sink is skipped (storeToDTS checks
            % this). Set by proxy_ncortex.discardTrial when the operator discards
            % before the neural data has finished sinking. Flags persist for the
            % session (trial numbers are monotonic, never reused) and are cleared
            % on session change in startCapture.
            proxObj.discardedTrials = union(proxObj.discardedTrials, double(trialNum));
        end

        function storeToDTS(proxObj, DF, dfID, dtsIdx)
            % Sink stage (capture mode): write a DF into the Nexus DTS at the
            % trial row address. Kept sink-agnostic so start/stopDataStream can
            % swap this for an axon-TX sink (REALTIME_CAPTURE_STREAM_DESIGN.md, C).
            % Skip if this trial was discarded before the sink ran — the operator
            % can discard faster than a capture sinks, so discardTrial flags the
            % trial and every DF of it is dropped here.
            if isstruct(dtsIdx) && isfield(dtsIdx, 'trialNumber') ...
                    && ismember(double(dtsIdx.trialNumber), proxObj.discardedTrials)
                return
            end
            nexon = proxObj.proxon.nexon;        % populated by nexusCtrl_startNexus
            if isempty(nexon)
                warning("npxls:noNexon", "no nexon bound to proxon; DF not stored");
                return
            end
            dtsIO_writeDF(nexon, DF, dfID, dtsIdx, true);  % forceMem: stay in-memory until explicit sink
            try
                nexon.console.BASE.updateControlPanel();
            catch e
                disp(getReport(e));
            end
        end

        function closeAllRealtimeThreads(proxObj, pyd, sze)
            % Host relays this on shutdown (proxy_ncortex.closeAllRealtimeThreads
            % → relayToTargetProxies fans it to every target proxy). Tear down
            % everything this proxy runs off the main thread so nothing keeps
            % firing on a torn-down Server / leaked socket:
            %   - writeBuffer timer (fixedRate readData → FetchLatest); this is
            %     the timer that otherwise errors "socket address in use" once
            %     the Server is gone.
            %   - capTimer (capture drain) + capture state, if a capture is live.
            %   - rtSort sidecar client socket.
            if ~isempty(proxObj.writeBuffer) && isvalid(proxObj.writeBuffer)
                try, stop(proxObj.writeBuffer);   catch, end
                try, delete(proxObj.writeBuffer); catch, end
            end
            proxObj.writeBuffer = [];
            if ~isempty(proxObj.capTimer) && isvalid(proxObj.capTimer)
                try, stop(proxObj.capTimer);   catch, end
                try, delete(proxObj.capTimer); catch, end
            end
            proxObj.capTimer     = [];
            proxObj.EN_capStream = false;
            proxObj.rtSortClose();
        end

        % ================= RTSort sidecar (Phase 2) =================
        % Build the sorter ONCE (detectSequences or loadSorter), then run_sort
        % each captured trial IN MEMORY over the socket — no per-trial disk, no
        % re-detection. See REALTIME_CAPTURE_STREAM_DESIGN.md (decision E).

        % ---- build-once (button-triggered from the nCORTEx target app) ----
        function detectSequences(proxObj, durSec)
            % Accumulate a training window from the live ring buffer (async,
            % non-destructive) and have the sidecar build the sorter from it. The
            % one-time static fields (templates/spatial/locs/...) are foliated with
            % the existing offline path and cached as spkStatic.
            if nargin < 2 || isempty(durSec), durSec = proxObj.detectDurSec; end
            apTrain = proxObj.accumulateAP(durSec);
            sessDir = proxObj.rtSortInitDetect(apTrain);      % builds + warms the sorter
            extract_rtsort(char(sessDir));                    % → rtsort_results.mat (native, no py)
            proxObj.spkStatic  = loadRTSort_spk(fullfile(char(sessDir), "rtsort_results.mat"));
            proxObj.sorterDir  = string(sessDir);
            proxObj.sorterReady = true;
            fprintf("RTSort sorter built: %d units\n", numel(proxObj.spkStatic.unit_ids));
        end

        function loadSorter(proxObj, picklePath)
            % Load a pre-built sorter: <picklePath> (the rt_sort.pickle) warms the
            % sidecar for running_sort; the rtsort_results.mat sitting alongside it
            % supplies the static per-unit DF fields for MATLAB (matched pair — see
            % saveSorter, which archives the pair in a dated subfolder). With no arg,
            % prompt for the pickle; results is always the sibling fixed name, so
            % pointing at any save subfolder's rt_sort.pickle pulls its own results.
            if nargin < 2 || isempty(picklePath)
                [f, p] = uigetfile("*.pickle", "Select rt_sort pickle");
                if isequal(f, 0), return; end
                picklePath = fullfile(p, f);
            end
            picklePath = char(picklePath);
            sorterDir = fileparts(picklePath);
            proxObj.rtSortInitLoad(picklePath);
            resultsPath = char(fullfile(sorterDir, "rtsort_results.mat"));
            if isfile(resultsPath)
                proxObj.spkStatic = loadRTSort_spk(resultsPath);
            else
                warning("npxls:noResults", ...
                    "%s not found — templates/amps unavailable in SPK DFs", resultsPath);
                proxObj.spkStatic = [];
            end
            proxObj.sorterDir  = string(sorterDir);
            proxObj.sorterReady = true;
        end

        function saveDir = saveSorter(proxObj, baseDir)
            % Persist the active sorter into a DATE-STAMPED SUBFOLDER of the
            % experiment's npxls module folder, tied to the subject:
            %   <experimentModules>/<experiment>/npxls/<subject>/<Y_M_D>/
            %       rt_sort.pickle  +  rtsort_results.mat   (plain, matched pair)
            % The pickle+results are a matched pair from one detection (cluster ids
            % index the results' unit metadata), so they're archived TOGETHER per
            % save — never sharing one results across differently-detected pickles.
            % loadSorter points at the subfolder's pickle and reads its sibling
            % rtsort_results.mat. Base is derived from nCORTEx.params (experiment
            % module path + experiment) and the subj tag parsed from sessionLabel.
            if ~isequal(proxObj.sorterReady, true) || isempty(proxObj.sorterDir)
                error("npxls:noSorter", "no active sorter to save — build or load one first");
            end
            if nargin < 2 || isempty(baseDir)
                params  = proxObj.nCORTEx.params;
                subject = parseSessionLabel(string(params.sessionLabel), "subj");
                if strlength(subject) == 0
                    error("npxls:noSubject", "no subj tag in sessionLabel '%s'", params.sessionLabel);
                end
                baseDir = fullfile(params.paths.experimentModules, params.experiment, "npxls", subject);
            end
            t = datetime("now");
            stamp = sprintf("%d_%d_%d", year(t), month(t), day(t));
            saveDir = fullfile(baseDir, stamp);
            if ~isfolder(saveDir), mkdir(saveDir); end
            srcDir = char(proxObj.sorterDir);
            % Source filenames are plain for a freshly-built sorter, or plain inside
            % a prior dated subfolder — match by prefix and take the first.
            pk = dir(fullfile(srcDir, "rt_sort*.pickle"));
            if isempty(pk)
                error("npxls:noPickle", "no rt_sort*.pickle in %s", srcDir);
            end
            copyfile(fullfile(srcDir, pk(1).name), fullfile(char(saveDir), "rt_sort.pickle"));
            rs = dir(fullfile(srcDir, "rtsort_results*.mat"));
            if ~isempty(rs)
                copyfile(fullfile(srcDir, rs(1).name), fullfile(char(saveDir), "rtsort_results.mat"));
            end
            proxObj.sorterDir = string(saveDir);   % subfolder holds the plain pair
            fprintf("RTSort sorter saved to %s\n", saveDir);
        end

        function apTrain = accumulateAP(proxObj, durSec)
            % Drain durSec of AP-band data from the ring buffer into RAM. Reuses
            % the drain pointer discipline (Fetch-returned headCt) so no samples
            % gap/overlap. Blocks for ~durSec — fine for a button-triggered detect.
            ip = proxObj.probeIndex;
            Fs = GetStreamSampleRate(proxObj.Server, 2, ip);
            cc = GetStreamAcqChans(proxObj.Server, 2, ip); nAP = cc(1);
            readHead = GetStreamSampleCount(proxObj.Server, 2, ip);
            target = round(durSec * Fs);
            buf = zeros(0, nAP, 'int16');
            while size(buf, 1) < target
                head = GetStreamSampleCount(proxObj.Server, 2, ip);
                n = head - readHead;
                if n <= 0, pause(0.05); continue; end
                [chunk, headCt] = Fetch(proxObj.Server, 2, ip, readHead, n, [-1]);
                buf = [buf; chunk(:, 1:nAP)];         % AP band only for training
                readHead = headCt + size(chunk, 1);
            end
            apTrain = buf(1:target, :);
        end

        % ---- per-trial run (called from stopCapture) ----
        function buildSPK_DF(proxObj, apMat, T, dtsIdx)
            % Sort the captured AP window with the warm sorter (running_sort, in
            % memory), merge the dynamic spikes into the cached static fields, and
            % foliate via formatSpk_toDTS into the RTS_ SPK DFs.
            if ~isequal(proxObj.sorterReady, true)
                disp("buildSPK_DF: no sorter — run detectSequences or loadSorter first");
                return
            end
            dyn = proxObj.rtSortRun(apMat);            % in-memory spikes: times/clusters/amps
            spk = proxObj.spkStatic;
            spk.spike_times_s    = dyn.times(:);
            spk.spike_clusters   = dyn.clusters(:);
            spk.spike_amplitudes = dyn.amps(:);
            dts = formatSpk_toDTS(spk, 0, T, proxObj.spkBin_s, proxObj.spkSigma_s);
            % Match the LFP axis: shift bin-centre times so 0 = the re-aligned
            % trigger (insert at preBuffLen from the window start), pre-context
            % negative. Binning is unchanged — this only relabels ax_t.
            dts.ax_t = dts.ax_t - proxObj.preBuffLen;
            npxlsCapture_writeSPK(proxObj, dts, dtsIdx);
        end

        % ---- sidecar transport ----
        function rtSortLaunch(proxObj)
            % Launch (once) and connect to the persistent RTSort sidecar. The
            % server binds before loading the model, so the client connects
            % quickly; the first request blocks while the model loads.
            % Reuse a live client; otherwise drop any stale/deleted handle (a
            % sidecar from a prior panel that was closed/killed) so we reconnect
            % below instead of writing to a dead object.
            if ~isempty(proxObj.rtSortClient)
                isLive = false;
                try, isLive = isvalid(proxObj.rtSortClient); catch, end
                if isLive
                    return
                end
                proxObj.rtSortClient = [];
            end
            % 1. attach to an already-running sidecar if there is one (quick). This
            %    avoids spawning a duplicate that would now fail the sidecar's
            %    exclusive port bind (SO_EXCLUSIVEADDRUSE).
            proxObj.rtSortClient = proxObj.rtSortConnect(2);
            if ~isempty(proxObj.rtSortClient)
                fprintf("attached to running rtSort sidecar on port %d\n", proxObj.rtSortPort);
                return
            end
            % 2. spawn one if allowed
            if proxObj.rtSortAutoLaunch
                serverPy = fullfile(fileparts(mfilename('fullpath')), "npxls", "rtSortServer.py");
                npxlsDir = fileparts(which('extract_rtsort'));   % dir holding runRTSort.py
                workDir  = fullfile(tempdir, "rtsort_rt");
                if ~isfolder(workDir), mkdir(workDir); end
                % Visible console via `cmd /k` — the window stays open on crash so
                % model-load / detection errors are readable during bring-up. Set
                % rtSortAutoLaunch=false to run the sidecar yourself and just attach.
                cmd = sprintf('start "rtSortServer" cmd /k ""%s" "%s" %d "%s" "%s""', ...
                    proxObj.pyExe, serverPy, proxObj.rtSortPort, npxlsDir, workDir);
                system(cmd);
                fprintf("rtSort sidecar launching (npxlsDir=%s)\n", npxlsDir);
            end
            % 3. connect, retrying while it binds + loads the model
            fprintf("connecting to rtSort sidecar on port %d ...\n", proxObj.rtSortPort);
            proxObj.rtSortClient = proxObj.rtSortConnect(120);
            if isempty(proxObj.rtSortClient)
                error("npxls:rtSortLaunch", "RTSort sidecar did not come up on port %d", proxObj.rtSortPort);
            end
        end

        function cl = rtSortConnect(proxObj, timeoutSec)
            % Try to connect to the sidecar, retrying until timeoutSec. Returns []
            % if nothing is listening (connection refused throws immediately).
            cl = [];
            t0 = tic;
            while toc(t0) < timeoutSec
                try
                    cl = tcpclient("127.0.0.1", proxObj.rtSortPort, "Timeout", 1800);
                    cl.ByteOrder = "little-endian";
                    return
                catch
                    pause(0.5);
                end
            end
        end

        function sendAPWindow(proxObj, mtype, apMat, fs)
            % Frame: [u8 mtype][u32 nsamp][u32 nchan][f64 fs][int16 traces C-order].
            cl = proxObj.rtSortClient;
            ap = int16(apMat);                        % samples x channels
            [nsamp, nchan] = size(ap);
            write(cl, uint8(mtype));
            write(cl, uint32(nsamp));
            write(cl, uint32(nchan));
            write(cl, double(fs));
            write(cl, reshape(ap.', 1, []));          % C-order (nsamp,nchan): sample0 all-chans, ...
        end

        function [rtype, payload] = recvFrame(proxObj)
            % Reply frame: [u8 rtype][u32 len][payload]. rtype 3 = OK, 4 = error.
            cl = proxObj.rtSortClient;
            rtype = read(cl, 1, "uint8");
            rlen  = read(cl, 1, "uint32");
            if rlen > 0, payload = read(cl, double(rlen), "uint8"); else, payload = uint8([]); end
        end

        function sessDir = rtSortInitDetect(proxObj, apMat)
            proxObj.rtSortLaunch();
            fs = GetStreamSampleRate(proxObj.Server, 2, proxObj.probeIndex);
            proxObj.sendAPWindow(1, apMat, fs);       % 1 = INIT_DETECT
            [rtype, payload] = proxObj.recvFrame();
            if rtype ~= 3, error("npxls:rtSort", "detect failed: %s", char(payload)); end
            sessDir = string(char(payload));
        end

        function rtSortInitLoad(proxObj, picklePath)
            proxObj.rtSortLaunch();
            cl = proxObj.rtSortClient;
            p = unicode2native(char(picklePath), "UTF-8");
            write(cl, uint8(2));                      % 2 = INIT_LOAD
            write(cl, uint32(numel(p)));
            write(cl, uint8(p));
            [rtype, payload] = proxObj.recvFrame();
            if rtype ~= 3, error("npxls:rtSort", "load failed: %s", char(payload)); end
        end

        function dyn = rtSortRun(proxObj, apMat)
            % 3 = RUN. Reply payload (little-endian):
            %   [u32 n][f64 times(n)][i32 clusters(n)][f64 amps(n)]
            proxObj.rtSortLaunch();
            proxObj.sendAPWindow(3, apMat, proxObj.capFs);
            [rtype, payload] = proxObj.recvFrame();
            if rtype ~= 3, error("npxls:rtSort", "run failed: %s", char(payload)); end
            p = uint8(payload(:).');
            n = double(typecast(p(1:4), "uint32"));
            off = 4;
            dyn.times    = typecast(p(off + (1:8*n)), "double");        off = off + 8*n;
            dyn.clusters = double(typecast(p(off + (1:4*n)), "int32")); off = off + 4*n;
            dyn.amps     = typecast(p(off + (1:8*n)), "double");
        end

        function rtSortClose(proxObj)
            % Tell the sidecar to shut down and drop the client. Wire into
            % closeProxies when proxy teardown is formalized.
            if ~isempty(proxObj.rtSortClient) && isvalid(proxObj.rtSortClient)
                try, write(proxObj.rtSortClient, uint8(5)); catch, end  % 5 = QUIT
            end
            proxObj.rtSortClient = [];
        end
    end

end