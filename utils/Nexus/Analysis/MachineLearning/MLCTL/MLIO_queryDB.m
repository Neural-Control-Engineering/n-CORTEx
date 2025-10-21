function value_query =  MLIO_queryDB(conn, sampleAddress, ID_query)
    % use sampleAddress to locate unique row of data in the index_ds.db -
    % handled by 'conn'
    % return the value under the column identified by ID_query (ID_query is
    % a string)
    % If a row indexed by the fields in sampleAddress cannot be found,
    % return an empty value
    % 

       % MLIO_queryDB - Query a single value from a SQLite database using struct conditions
    %
    % value_query = MLIO_queryDB(conn, sampleAddress, ID_query)
    %   conn          : sqlite connection object
    %   sampleAddress : struct with fieldnames = column names, values = query values
    %   ID_query      : column name string of the value you want to retrieve
    %
    % Example:
    %   addr.Subject = "S01";
    %   addr.Session = 2;
    %   val = MLIO_queryDB(conn, addr, "SignalValue");

    % --- Build WHERE clause dynamically from sampleAddress struct ---
    fields = fieldnames(sampleAddress);
    values = struct2cell(sampleAddress);

    whereClauses = strings(numel(fields),1);
    for i = 1:numel(fields)
        val = values{i};
        if isnumeric(val) || islogical(val)
            whereClauses(i) = sprintf('%s = %g', fields{i}, val);
        elseif isstring(val) || ischar(val)
            whereClauses(i) = sprintf('%s = "%s"', fields{i}, val);
        else
            error('Unsupported field type in sampleAddress for field %s', fields{i});
        end
    end
    whereStr = strjoin(whereClauses, ' AND ');

    % --- Build query ---
    sql = sprintf('SELECT %s FROM index_ds WHERE %s;', ID_query, whereStr);

    % --- Execute query ---
    result = fetch(conn, sql);

    % --- Return handling ---
    if isempty(result)
        value_query = [];   % No match found
    else
        value_query = result{1,1}; % Return the first match (assumes unique row)
    end
end