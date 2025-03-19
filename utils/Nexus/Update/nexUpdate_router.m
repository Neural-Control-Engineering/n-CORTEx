function nexUpdate_router(nexon, sessionLabel, labelFields)    

    labelFields = move2end(labelFields,"date");
    labelFields = move2end(labelFields,"phase");
    labelFields = move2end(labelFields,"trial");
    labelFields(labelFields=="subj")="subject"; % TEMPORARY
    sessionLabel = strrep(sessionLabel,"subj","subject"); % TEMPORARY
    % labelFields = move2end(labelFields,"subj"); % do subj last for special lines in routerEntryChanged method

    % update router entry params
    for i = 1:length(labelFields)
        labelField = labelFields(i);
        if isfield(nexon.console.BASE.router.Panel,labelField)
            newVal = parseSessionLabel(sessionLabel,labelField);                                             
            nexon.console.BASE.router.entryParams.(labelField) = newVal; % update entry param value (corresp.) / simulate routerEntryChanged 
        end
    end    
    % update router items
    nex_refindRouterItems(nexon);
    % update router values
    for i = 1:length(labelFields)
        labelField = labelFields(i);
        if isfield(nexon.console.BASE.router.Panel,labelField)
            newVal = parseSessionLabel(sessionLabel,labelField);                                             
            if strcmp(labelField,"trial")
                try
                    nexon.console.BASE.router.Panel.(labelField).uiField.Value = char(newVal); % update entry field value                                                     
                catch e
                    nexon.console.BASE.router.Panel.(labelField).uiField.Value = [' ',char(newVal)]; % update entry field value                                                     
                end
            else
                nexon.console.BASE.router.Panel.(labelField).uiField.Value = char(newVal); % update entry field value                                                     
            end            
        end
    end

    try
        % nexon.console.BASE.router.entryParams.subj = newVal; % update entry param value (corresp.)
        % nexon.console.BASE.router.Panel.subj.uiField.Value = newVal;
        % notify(nexon.console.BASE.router.Panel.subj.uiField,'ValueChanged'); % use routerEntryChanged
        % nexon.console.BASE.router.Panel.subj.uiField.ValueChangedFcn(nexon, nexon.console.BASE.router.Panel,"subj");
        routerEntryChanged(nexon, nexon.console.BASE.router.Panel,"subj");
    catch
        % nexon.console.BASE.router.entryParams.subject = newVal; % update entry param value (corresp.)
        % nexon.console.BASE.router.Panel.subject.uiField.Value = newVal;
        % notify(nexon.console.BASE.router.Panel.subject.uiField,'ValueChanged'); % use routerEntryChanged
        % nexon.console.BASE.router.Panel.subject.uiField.ValueChangedFcn(nexon, nexon.console.BASE.router.Panel, "subject");
        routerEntryChanged(nexon, nexon.console.BASE.router,"subject");
    end
end   

