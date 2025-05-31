function zCell_new = pv_updateZCell(zCell, z_new)
    % position z special formatting
    % zCell = spt(idx_stagePositionSelection,:).z;
    zCell_split = split(zCell,",");
    zCell_split{1} = num2str(z_new);
    zCell_new = join(zCell_split,",");
    % spt(idx_stagePositionSelection,:).z = zCell_new;
end