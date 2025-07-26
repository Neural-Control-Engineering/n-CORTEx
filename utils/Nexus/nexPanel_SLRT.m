classdef nexPanel_SLRT < handle
    properties
        nexon
        signals
        config
    end

    methods

        function nexObj = nexPanel_SLRT(nexon)
            nexon.console.SLRT=nexObj;
            nexObj.nexon=nexon;
            nexObj.config = struct;
            % dfID = ["stimTrace_raw";"stimTrace_lowess_span2"]; % temporary; will be dynamically allocated by GUI or cfg
            % dfID = ["stimOnset_aligned_stimLowess"];
            dfID = ["stimLowess"];
            % dataFrame = compileDataFrames(nexon, dfID); % return cell array of dataframes by dfIDs
            nexObj.signals = nexObj_slrtTimeCourse(nexObj, dfID);
        end

    end


end
