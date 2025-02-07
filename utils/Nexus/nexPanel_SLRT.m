classdef nexPanel_SLRT < handle
    properties
        signals
        config
    end

    methods

        function obj = nexPanel_SLRT(nexon)
            obj.config = struct;
            dfID = ["stimTrace_raw";"stimTrace_lowess_span2"]; % temporary; will be dynamically allocated by GUI or cfg
            dataFrame = compileDataFrames(nexon, dfID); % return cell array of dataframes by dfIDs
            obj.signals = nexObj_slrtTimeCourse(nexon, dataFrame, dfID);
        end

    end


end
