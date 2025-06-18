function photonCtrl_initializeMicroscope(nexObj)
    prxObj_photon = nexObj.proxon.index_type2.photon_1;
    ncortex = nexObj.nCORTEx;

    % Play sound
    try
        soundPath = fullfile(ncortex.nCORTEx_repo,"utils/assets/audio/","TT_ThisCouldBeFun.wav");
        [y, fs] = audioread(soundPath);
        player = audioplayer(y, fs);
        play(player);
        res = 1;
    catch
        res = 0;
    end

    % Do something while audio plays
    photonCtrl_locatePhysicalHome(prxObj_photon);
    % for i = 1:20
    %     disp(i);
    %     pause(1)
    % end

    % Stop audio when done
    if res
        stop(player);
    end
end
