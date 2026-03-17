function windowCfgEntryChanged(nexObj, ~, nexPanel, editField, ~)
    % Callback for the window parameter panel.
    % Writes the spinner value to STATE.ptr.(axKey).window and re-visualizes.
    % A value of 0 disables the window (full range shown).
    val = nexPanel.editFields.(editField).uiField.Value;
    if isfield(nexObj.STATE, 'ptr') && isfield(nexObj.STATE.ptr, editField)
        nexObj.STATE.ptr.(editField).window = val;
        nexObj.visualize();
    end
end
