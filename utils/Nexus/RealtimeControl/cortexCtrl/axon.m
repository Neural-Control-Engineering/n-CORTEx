classdef axon < Simulink.Bus
    methods
        function obj = axon(class)
            obj = axon_build(class);
        end
    end
end

% ax.CMD
% ax.SZE
% ax.PYD.signal_L
% ax.PYD.signal_M
% ax.PYD.tag
