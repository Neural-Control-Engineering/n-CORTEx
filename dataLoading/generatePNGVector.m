function generatePNGVector(pngDir)
    pngs = dir(pngDir);
    pngs = struct2table(pngs);
    pngs = pngs(contains(pngs.name,".png"),:);
    pngFiles = sort(convertCharsToStrings(pngs.name));
    
end