function MLIO_insertSample(conn, sampleAddress, DF_smp)
% Inserts a row into SQLite table 'index_ds' dynamically
% conn: sqlite connection object
% sampleAddress: struct of main address fields
% DF_smp.Y: struct of label values (optional)
% DF_smp.fitParams: struct of parameter values (optional)
% uniqueCols: cell array of column names to enforce UNIQUE

tablename = "index_ds";

% Merge all fields for the current row
% allFields = [fieldnames(sampleAddress); fieldnames(DF_smp.Y); fieldnames(DF_smp.fitParams)];
% headerStruct = mergeStructs(sampleAddress, DF_smp.Y);
headerStruct = mergeStructs(DF_smp.Y, DF_smp.fitParams);
headerFields = fieldnames(headerStruct);

% TABLE GEN
% colDefs = strings(1,numel(headerFields));

% 
% createStmt = "CREATE TABLE IF NOT EXISTS index_ds (" + strjoin(colDefs, ", ") + ")";
% 
% exec(conn, createStmt);

% UNIQUE COLS
uniqueCols = fieldnames(sampleAddress); % the "key" fields
uniqueDef = "UNIQUE(" + strjoin(uniqueCols, ", ") + ")";
addrFields = fieldnames(sampleAddress);
for i = 1:numel(addrFields)
    val = sampleAddress.(addrFields{i});

    if isstring(val) || ischar(val)
        sqlType = "TEXT";
    elseif isnumeric(val)
        sqlType = "REAL";
    elseif islogical(val)
        sqlType = "BOOLEAN";
    else
        sqlType = "TEXT";
    end
    colDefs(i) = addrFields{i} + " " + sqlType;
end

createStmt = "CREATE TABLE IF NOT EXISTS " + tablename + " (" + ...
             strjoin(colDefs, ", ") + ", " + uniqueDef + ")";
exec(conn, createStmt);

 data = fetch(conn, "SELECT * FROM " + tablename + " LIMIT 0");
 dataCols = convertCharsToStrings(data.Properties.VariableNames);

% ADD NON-UNIQUE COLS
colDefs = strings(1,numel(headerFields));
for i = 1:numel(headerFields)
    headerField = headerFields{i};
    if ~ismember(headerField, dataCols)
        val = headerStruct.(headerFields{i});
    
        if isstring(val) || ischar(val)
            sqlType = "TEXT";
        elseif isnumeric(val)
            sqlType = "REAL";
        elseif islogical(val)
            sqlType = "BOOLEAN";
        else
            sqlType = "TEXT";
        end
        colDefs(i) = headerFields{i} + " " + sqlType;
        alterStmt = "ALTER TABLE " + tablename + " ADD COLUMN " + colDefs(i);
        exec(conn, alterStmt);
    end
end

data = fetch(conn, "SELECT * FROM " + tablename + " LIMIT 0");
dataCols = convertCharsToStrings(data.Properties.VariableNames);

% --- 2. Build the INSERT statement ---
headerFields = mergeStructs(sampleAddress,headerStruct);
headerFields = fieldnames(headerFields);
vals = strings(1,numel(headerFields));
insertFields = [];
for i = 1:numel(headerFields)
    f = headerFields{i};
    if ismember(f, dataCols)
        insertFields = [insertFields; string(f)];
        if isfield(sampleAddress, f)
            v = sampleAddress.(f);
        elseif isfield(DF_smp.Y, f)
            v = DF_smp.Y.(f);
        elseif isfield(DF_smp.fitParams, f)
            v = DF_smp.fitParams.(f);
        else
            v = NaN;
        end
    
        % Quote strings, cast numbers
        if ischar(v) || isstring(v)
            vals(i) = "'" + string(v) + "'";
        elseif isnumeric(v) || islogical(v)
            vals(i) = string(double(v));
        else
            vals(i) = "NULL";
        end
    end
end

% Build SQL
% insertStmt = "INSERT OR REPLACE INTO " + tablename + " (" + strjoin(headerFields, ", ") + ") VALUES (" + strjoin(vals, ", ") + ")";
insertStmt = "INSERT OR REPLACE INTO " + tablename + " (" + strjoin(insertFields, ", ") + ") VALUES (" + strjoin(vals, ", ") + ")";
try
    exec(conn, insertStmt);
    fprintf("Successfully added sample to %s\n",tablename);
catch e
    disp(getReport(e));
end

end
