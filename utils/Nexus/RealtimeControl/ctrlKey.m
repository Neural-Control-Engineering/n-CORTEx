classdef ctrlKey < Simulink.IntEnumType
    enumeration
        startDataStream_npxls (1)
        stopDataStream_npxls(2)
        startDataStream_photon (3)
        stopDataStrean_photon (4)
        startCapture_rx (5)
        stopCapture_rx(6)
        startCapture_tx (7)
        stopCapture_tx (8)
        homeObjective (9)
        endOfTrial (10)
    end
end