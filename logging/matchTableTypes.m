function newTable = matchTableTypes(sourceTable, targetTable)
    % Ensure the tables have the same number of variables
    assert(width(sourceTable) == width(targetTable), 'Number of variables must be the same');

    % Initialize the new table with the same variable names
    % Create an empty table with variable names and data types based on the source table
    newTable = array2table(zeros(size(sourceTable)));
    newTable.Properties.VariableNames = sourceTable.Properties.VariableNames

    % Convert data types dynamically
    for col = 1:width(sourceTable)
        % Get the variable name
        varName = sourceTable.Properties.VariableNames{col};

        % Get the data type from the target table
        targetType = class(targetTable.(varName));

        % Convert the column to the data type of the source table
        switch targetType
            case 'cell'
                newTable.(varName) = {sourceTable.(varName)};
            otherwise
                newTable.(varName) = cast(cell2mat(sourceTable.(varName)), targetType);
                % switch sourceType
                %     case
                %         newTable.(varName) = cast(sourceTable.(varName), targetType);
                %     otherwise
                %         newTable.(varName) = cast(sourceTable.(varName), targetType);
                % end
                
        end
    end
end