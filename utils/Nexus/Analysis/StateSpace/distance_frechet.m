function distance_frechet(DF_in, args)
    
    % CFG HEADER
    d1 = args.d1; % default = 1

    % select baseline trajectory
    x1Sel = args.x1Sel;    

    shapely = py.importlib.import_module("shapely");
    frechet = shapely.frechet_distance;

    D = frechet(X1, X2);
end