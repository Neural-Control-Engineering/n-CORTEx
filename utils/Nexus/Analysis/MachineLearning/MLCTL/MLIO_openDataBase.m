function conn = MLIO_openDataBase(file_db)
    % Open SQLite connection (will create a new DB file)
    % = "index.db";
    if isfile(file_db)
        delete(file_db); % delete if already exists
    end
    conn = sqlite(file_db,"create");
    
    % Extract field names and example values
    % fields = fieldnames(sampleAddress);
    % 
    % colDefs = strings(1, numel(fields));
    % 
    % for i = 1:numel(fields)
    %     val = sampleAddress.(fields{i});
    % 
    %     % Infer SQL type from MATLAB type
    %     if isstring(val) || ischar(val)
    %         sqlType = "TEXT";
    %     elseif isnumeric(val)
    %         if isinteger(val)
    %             sqlType = "INTEGER";
    %         else
    %             sqlType = "REAL";
    %         end
    %     elseif islogical(val)
    %         sqlType = "BOOLEAN";
    %     else
    %         sqlType = "TEXT"; % fallback
    %     end
    % 
    %     % Add UNIQUE constraint
    %     colDefs(i) = fields{i} + " " + sqlType + " UNIQUE";
    % end
    % 
    % % Build CREATE TABLE statement
    % createStmt = "CREATE TABLE index_ds (" + strjoin(colDefs, ", ") + ")";
    % exec(conn, createStmt);
    % 
    % disp("Created table with schema:");
    % disp(createStmt);
end