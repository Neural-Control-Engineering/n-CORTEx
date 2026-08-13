classdef Nexon < handle
    properties
        classID="nexon"
        console % This will hold any type of data, such as a struct
        Children
        UserData
        settings
    end
    
    methods
        % Constructor
        function obj = Nexon(nexon)
            obj.console=struct();
            obj.UserData = struct(); % Initialize as an empty struct      
            settings=struct();
        end
        
        % Example method to set UserData
        function setUserData(obj, data)
            obj.UserData = data;
        end
        
        % Example method to retrieve UserData
        function data = getUserData(obj)
            data = obj.UserData;
        end

        function saveRegistry(nexon)
            registry = nexon.console.BASE.registry; %#ok<NASGU>
            save(nexon.nexCachePath('registry'), 'registry');
        end

        function loadRegistry(nexon)
            p = nexon.nexCachePath('registry');
            if ~isfile(p)
                warning('Nexon:loadRegistry', 'No registry cache found at %s', p);
                return;
            end
            S = load(p, 'registry');
            nexon.console.BASE.registry = S.registry;
        end

        function p = nexCachePath(nexon, cacheKey)
            % Returns experiment-scoped cache path: Startup/Cache/<key>_<experiment>.mat
            try
                expt = char(nexon.console.BASE.params.experiment);
            catch
                try
                    expt = char(nexon.console.BASE.params.extractCfg.experiment);
                catch
                    expt = 'default';
                end
            end
            expt = matlab.lang.makeValidName(expt);
            p = fullfile(fileparts(which('Nexon')), 'Startup', 'Cache', ...
                         sprintf('%s_%s.mat', cacheKey, expt));
        end

        function appendDiskDTS(nexon, DTS_new)
        % Write DTS_new to the existing disk-backed HDF5 and append the
        % resulting manifest rows to nexon.console.BASE.DTS.
        %
        %   nexon.appendDiskDTS(DTS_new)
        %
        % DTS_new must be an in-memory trial table (same schema as the
        % existing DTS). nexon.console.BASE.DTS must already be disk-backed
        % (h5_path column present).
            DTS_base = nexon.console.BASE.DTS;
            if isempty(DTS_base) || ...
                    ~ismember('h5_path', string(DTS_base.Properties.VariableNames))
                error('Nexon:appendDiskDTS', ...
                    ['nexon.console.BASE.DTS must be disk-backed ' ...
                     '(h5_path column required). Run nexus_exportDTS first.']);
            end
            h5File = char(DTS_base.h5_path(1));
            DTS_manifest_new = nexus_exportDTS(DTS_new, h5File);
            nexon.appendToDTS(DTS_manifest_new);
        end

        function repackDiskDTS(nexon)
        % Repair the disk-backed HDF5 file after a crashed write using h5repack.
        %
        %   nexon.repackDiskDTS()
        %
        % h5repack reads every object it can from the damaged file and writes
        % a clean copy. On success the original is renamed to *_pre_repack.h5
        % as a backup and the clean copy takes its place — h5_path values in
        % the manifest are unchanged.
        %
        % Run this after restarting MATLAB to clear any stale HDF5 file handles
        % left by a crash.
            DTS_base = nexon.console.BASE.DTS;
            if isempty(DTS_base) || ...
                    ~ismember('h5_path', string(DTS_base.Properties.VariableNames))
                error('Nexon:repackDiskDTS', ...
                    'nexon.console.BASE.DTS must be disk-backed (h5_path column required).');
            end

            h5File     = char(DTS_base.h5_path(1));
            [d, n, e]  = fileparts(h5File);
            repackFile = fullfile(d, [n '_repack' e]);
            backupFile = fullfile(d, [n '_pre_repack' e]);

            if isfile(repackFile), delete(repackFile); end

            fprintf('Repacking %s ...\n', h5File);
            % env -u LD_LIBRARY_PATH strips MATLAB's library paths so h5repack
            % uses the system HDF5 libraries rather than MATLAB's libcurl/libhdf5.
            cmd = sprintf('env -u LD_LIBRARY_PATH h5repack "%s" "%s"', h5File, repackFile);
            [status, out] = system(cmd);
            if status ~= 0
                error('Nexon:repackDiskDTS', 'h5repack failed:\n%s', out);
            end

            % Validate before swapping
            try
                h5info(repackFile);
            catch ME
                delete(repackFile);
                error('Nexon:repackDiskDTS', ...
                    'Repacked file failed validation — original untouched.\n%s', ME.message);
            end

            % Swap: backup original, promote repacked copy to original path
            movefile(h5File, backupFile);
            movefile(repackFile, h5File);

            fprintf('Repack complete.\n');
            fprintf('  Active : %s\n', h5File);
            fprintf('  Backup : %s\n', backupFile);
        end

        function migrateDTS(nexon, newPathArg, mode)
        % Migrate the disk-backed HDF5 file to a new location and update h5_path.
        %
        %   nexon.migrateDTS(newPath)          % default: repair + cp + repack
        %   nexon.migrateDTS(newPath, 'fast')  % repair + cp only (skips repack)
        %
        % Pass either a full .h5 destination path or a destination directory
        % (the original filename is preserved).
        %
        % 'fast' mode is appropriate when the source file is already valid (e.g.
        % after a successful superblock repair). h5repack reads and rewrites every
        % byte — for large files the copy alone takes just as long, so skip it
        % unless you specifically need compaction or fragmentation repair.
        %
        % Workflow:
        %   1. Patch superblock EOF if it mismatches actual size (disk-full crash).
        %   2. cp to new path (raw byte copy; works even when source disk is full).
        %   3. h5repack the copy for compaction (skipped in 'fast' mode).
        %   4. Validate new file via h5info before touching the manifest.
        %   5. Update h5_path in nexon.console.BASE.DTS.
        %
        % The original file is NOT deleted — remove it manually after verifying.
        % Persist the updated manifest:
        %   DTS = nexon.console.BASE.DTS;  save('nexDTS_manifest.mat','DTS')
            if nargin < 3, mode = 'full'; end

            DTS = nexon.console.BASE.DTS;
            if isempty(DTS) || ...
                    ~ismember('h5_path', string(DTS.Properties.VariableNames))
                error('Nexon:migrateDTS', ...
                    'nexon.console.BASE.DTS must be disk-backed (h5_path column required).');
            end

            oldH5File = char(DTS.h5_path(1));
            newPathArg = char(newPathArg);

            % Resolve destination — directory or full path
            if isfolder(newPathArg) || ...
                    (~endsWith(newPathArg, '.h5') && ~isfile(newPathArg))
                [~, fname, ext] = fileparts(oldH5File);
                newH5File = fullfile(newPathArg, [fname ext]);
            else
                newH5File = newPathArg;
            end

            if strcmp(oldH5File, newH5File)
                error('Nexon:migrateDTS', 'Destination is the same as the current path.');
            end

            newDir = fileparts(newH5File);
            if ~isempty(newDir) && ~isfolder(newDir)
                mkdir(newDir);
            end
            if isfile(newH5File), delete(newH5File); end

            fprintf('Migrating HDF5:\n  from : %s\n  to   : %s\n', oldH5File, newH5File);

            % Step 1 — repair superblock EOF mismatch from disk-full crash.
            % When H5FD_truncate fails (no disk space), the superblock records a
            % larger EOF than the file actually has, making HDF5 refuse to open it.
            % For superblock v0 (no checksum), we can safely patch offset 40.
            fprintf('  [1/3] superblock repair + h5clear ...\n');
            repairCmd = sprintf(['python3 -c "', ...
                'import os,struct; p=''%s''; ', ...
                'sz=os.path.getsize(p); f=open(p,''rb''); ver=f.read(9)[-1]; f.seek(40); ', ...
                'sb_eof=struct.unpack(''<Q'',f.read(8))[0]; f.close(); ', ...
                'delta=sb_eof-sz; ', ...
                'print(f''  superblock EOF {sb_eof:,}  actual {sz:,}  delta {delta:,}''); ', ...
                '(open(p,''r+b'').seek(40) or True) and (lambda f: (f.seek(40), ', ...
                'f.write(struct.pack(''<Q'',sz)), f.close()) if ver==0 and sb_eof>sz else None)(open(p,''r+b''))"'], ...
                oldH5File);

            % Simpler inline patch (v0 only, patches only if sb_eof > actual size)
            patchScript = sprintf([ ...
                'import os,struct\n', ...
                'p="%s"\n', ...
                'sz=os.path.getsize(p)\n', ...
                'with open(p,"rb") as f:\n', ...
                '    f.seek(8); ver=struct.unpack("B",f.read(1))[0]\n', ...
                '    f.seek(40); sb_eof=struct.unpack("<Q",f.read(8))[0]\n', ...
                'if ver==0 and sb_eof>sz:\n', ...
                '    with open(p,"r+b") as f:\n', ...
                '        f.seek(40); f.write(struct.pack("<Q",sz))\n', ...
                '    print(f"  Patched superblock EOF {sb_eof:,} -> {sz:,}")\n', ...
                'else:\n', ...
                '    print(f"  Superblock OK (ver={ver}, eof={sb_eof:,}, size={sz:,})")\n'], ...
                oldH5File);
            patchFile = [tempname '.py'];
            fid = fopen(patchFile, 'w'); fprintf(fid, '%s', patchScript); fclose(fid);
            [~, pout] = system(sprintf('python3 "%s"', patchFile));
            delete(patchFile);
            fprintf('%s', pout);
            superblockWasPatched = contains(pout, 'Patched');

            [~, ~] = system(sprintf('env -u LD_LIBRARY_PATH h5clear -s "%s"', oldH5File));

            % Step 2 — copy to new path.
            % 'fast' (cp) is only safe when the superblock was already valid.
            % A patched superblock means the file had orphaned metadata from a
            % failed write; cp preserves that metadata, and h5writeSafe's
            % H5L.delete of the orphaned dataset will corrupt the HDF5
            % free-space manager on the copy. h5repack drops unreachable
            % objects and rebuilds metadata cleanly.
            if strcmp(mode, 'fast') && superblockWasPatched
                warning('Nexon:migrateDTS', ...
                    ['fast mode is unsafe after a superblock patch ' ...
                     '(orphaned metadata present) — using h5repack instead.']);
                mode = 'full';
            end

            if strcmp(mode, 'fast')
                fprintf('  [2/3] cp (fast mode) ...\n');
                cmd = sprintf('cp "%s" "%s"', oldH5File, newH5File);
                [status, out] = system(cmd);
                if status ~= 0
                    error('Nexon:migrateDTS', 'cp failed:\n%s', out);
                end
            else
                fprintf('  [2/3] h5repack ...\n');
                cmd = sprintf('env -u LD_LIBRARY_PATH h5repack "%s" "%s"', oldH5File, newH5File);
                [status, out] = system(cmd);
                if status ~= 0
                    error('Nexon:migrateDTS', 'h5repack failed:\n%s', out);
                end
            end

            % Step 3 — validate before touching manifest
            fprintf('  [3/3] validating ...\n');
            try
                h5info(newH5File);
            catch ME
                delete(newH5File);
                error('Nexon:migrateDTS', ...
                    'New file failed HDF5 validation — original untouched.\n%s', ME.message);
            end

            % Update manifest
            nexon.console.BASE.DTS.h5_path(:) = string(newH5File);

            fprintf('Done.\n');
            fprintf('  Active : %s\n', newH5File);
            fprintf('  Old    : %s  (not deleted)\n', oldH5File);
            fprintf('Save manifest:  DTS = nexon.console.BASE.DTS; save(''nexDTS_manifest.mat'',''DTS'')\n');
        end

        function rechunkDTS(nexon, newH5File, chunkTargetBytes, targetDFID, batchSize)
        % Rechunk trial DF data into a new HDF5 file with automatic
        % axis-aware chunking, then update the manifest to point to it.
        %
        %   nexon.rechunkDTS('nexDTS_chunk.h5')
        %   nexon.rechunkDTS('nexDTS_chunk.h5', 256*1024)              % 256 KB chunks
        %   nexon.rechunkDTS('nexDTS_chunk.h5', [], 'fCWT')            % one dfID only
        %   nexon.rechunkDTS('nexDTS_chunk.h5', [], 'fCWT', 1)         % 1 trial/batch
        %
        % batchSize controls peak RAM: batchSize × (bytes per trial).
        % For large dfIDs (e.g. fCWT at ~7 GB/trial) use batchSize=1.
        % Default 50 is only safe for small-to-medium DFs.
        %
        % Original file is not deleted. Save the manifest afterward:
        %   DTS = nexon.console.BASE.DTS; save('nexDTS_manifest.mat','DTS')
            if nargin < 3, chunkTargetBytes = 128*1024; end
            if nargin < 4, targetDFID = ''; end
            if nargin < 5, batchSize = 50; end
            DTS = nexon.console.BASE.DTS;
            if isempty(DTS) || ...
                    ~ismember('h5_path', string(DTS.Properties.VariableNames))
                error('Nexon:rechunkDTS', ...
                    'nexon.console.BASE.DTS must be disk-backed (h5_path required).');
            end
            % Resolve relative newH5File against the source HDF5 directory.
            newH5File = char(newH5File);
            if ~java.io.File(newH5File).isAbsolute()
                srcDir    = fileparts(char(DTS.h5_path(1)));
                newH5File = fullfile(srcDir, newH5File);
            end
            dtsIO_rechunkDTS(DTS, newH5File, chunkTargetBytes, batchSize, targetDFID);
            nexon.console.BASE.DTS.h5_path(:) = string(newH5File);
            fprintf('Manifest updated → %s\n', newH5File);
            fprintf('Save manifest:  DTS = nexon.console.BASE.DTS; save(''nexDTS_manifest.mat'',''DTS'')\n');
        end

        function appendToDTS(nexon, DTS)
            DTS_base = nexon.console.BASE.DTS;
            if isempty(DTS_base)
                DTS_full=DTS;
                nexon.console.BASE.DTS=DTS_full;
                % initialize control panel and subpanels
                nex_panelStartup(nexon);
            else
                DTS_full = mergeT_vertical(DTS_base, DTS);
                % sort by sessionLabel
                DTS_sort = sortrows(DTS_full,["sessionLabel","trialNumber"],"ascend");
                nexon.console.BASE.DTS=DTS_sort;
                % update router selection
                routerCfgParams = initializeRouterCfg(nexon.console.BASE.DTS);
                panelObj = nexon.console.BASE.controlPanel.Figure.panel1;
                updateEntryDropDownFields(panelObj, routerCfgParams);
                % update averaging-bus selection items alongside the router so
                % new trials' subjects/phases/dates/signal tags stay selectable
                try
                    nexon.console.BASE.controlPanel.appendToDTS();
                catch e
                    disp(getReport(e));
                end
            end


        end
    end
end