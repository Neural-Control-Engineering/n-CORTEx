function saveExtData(extModPath, extData, extMod)
    extMod = extData;
    assignin("caller",extMod,extData);
    save
end