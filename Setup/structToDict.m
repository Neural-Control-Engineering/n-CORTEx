function pyDict = structToDict(matStruct)
            % Returns a matlab struct as a text formatted python dictionary
            % containing struct fields as dict keys and struct values as dict values
            % Converts a MATLAB struct to a text-formatted Python dictionary
    
            % Start with an empty string
            pyDict = '{';
            
            % Loop through the fields of the struct
            fields = fieldnames(matStruct);
            for i = 1:length(fields)
                field = fields{i};
                value = matStruct.(field);
                
                % Convert the field name and value to strings
                fieldStr = sprintf('"%s"', field);
                valueStr = '';
                
                % Check the data type of the value and format it accordingly
                if ischar(value)
                    valueStr = sprintf('"%s"', value);
                elseif isnumeric(value) || islogical(value)
                    valueStr = num2str(value);
                elseif isstruct(value)
                    % Recursively convert nested structs
                    valueStr = structToDict(value);
                elseif isstring(value)
                    valueStr = sprintf('"%s"', value);
                else
                    % Handle other data types as needed
                    error('Unsupported data type in struct.');
                end
                
                % Combine the field and value strings
                pairStr = sprintf('%s: %s', fieldStr, valueStr);
                
                % Add the pair to the dictionary string
                if i < length(fields)
                    pyDict = [pyDict, pairStr, ', '];
                else
                    pyDict = [pyDict, pairStr];
                end
            end
            
            % Close the dictionary
            pyDict = [pyDict, '}'];
            
        end