function shankConfigEntryChanged(nexon, entryPanel, entryfield)
    % update parameters and update relevant shank scopes
     value = entryPanel.Panel.(entryfield).uiField.Value;
     entryPanel.entryParams.(entryfield) = value;
     if strcmp(entryfield,"bandSel")
         shankList = fieldnames(nexon.console.NPXLS.shanks);
         for i = 1:length(shankList)
             shankID = shankList{i};
             shank = nexon.console.NPXLS.shanks.(shankID);
             timeCourse = nexon.console.NPXLS.shanks.(shankID).scope.timeCourse1;
             loadPSDTimeCourse(nexon, shank, timeCourse);
         end
     end
end