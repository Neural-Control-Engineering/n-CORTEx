function router = setupRouter(obj, nexon, DTS)
    routerCfgParams = initializeRouterCfg(DTS);
    % nexon.console.BASE.router.Panel.fh = uifigure("Position",[100,1260,500,800],"Color",[0,0,0]);   
    % nexon.console.BASE.router.Panel.ph = uipanel(nexon.console.BASE.router.Panel.fh,"Position",[5,5,490,790],"BackgroundColor",[0,0,0]);      
    valueChangedFcn = str2func("routerEntryChanged");
    router = nexObj_entryPanel(nexon,[],routerCfgParams,valueChangedFcn,5,10);
    obj.UserData.prevRouter.entryParams=router.entryParams; % save previous router
    % nexon.console.BASE.router = breakoutEditFields(nexon, nexon.console.BASE.router, routerCfgParams, valueChangedFcn);
end