function subjectNames = getSubjectName(sessionNames, subjects)
    % Initialize subjectNames array
    subjectNames = cell(size(sessionNames));
    
    % Iterate through sessionNames
    for i = 1:length(sessionNames)
        sessionName = sessionNames{i};
        
        % Find the subject that matches the sessionName
        matchingSubjects = subjects(contains(sessionName, string(subjects)));
        
        % Check if there is a matching subject
        if ~isempty(matchingSubjects)
            % Use the first matching subject (modify as needed)
            subjectNames{i} = matchingSubjects{1};
        end
    end
    
    % Remove empty entries from subjectNames
    subjectNames = subjectNames(~cellfun('isempty', subjectNames));
end