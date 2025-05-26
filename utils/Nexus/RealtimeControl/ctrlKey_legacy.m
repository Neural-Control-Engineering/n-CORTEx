classdef ctrlKey_legacy < Simulink.IntEnumType
    enumeration
        % NEUROPIXELS COMMANDS
        startDataStream_npxls (1)
        stopDataStream_npxls(2)
        startCapture_npxls (3)
        stopCapture_npxls (4)
        % 2-PHOTON COMMANDS
        startDataStream_photon (5)
        stopDataStrean_photon (6)
        startCapture_photon (7)
        stopCapture_photon(8)
        homeObjective_photon (9)
        % SIMULINK REALTIME COMMANDS
        startDataStream_slrt (10)
        stopDataStream_slrt (11)
        startCapture_slrt (12)
        stopCapture_slrt (13)        
        endOfTrial (14)
    end
end