function selectMethod(nexon, shank, timeCourse)
    fcnHandle = uigetfile();
    fcnHandle = split(fcnHandle,"."); % remove extension
    fcnHandle = fcnHandle{1};        
    defaultArgs = extractMethodCfg(fcnHandle);

    methodCfgValueChangedFcn = str2func("methodCfgEntryChanged");
    methodCfg = nexObj_entryPanel(nexon, defaultArgs, methodCfgValueChangedFcn);
    timeCourse.UserData.methodCfg = methodCfg;
    timeCourse.UserData.methodCfg.UserData.methodFcn = str2func(fcnHandle);

    % timeCourse.UserData.methodCfg.Panel.fh = uifigure("Position",[100,560,500,800],"Color",[0,0,0]);   
    % timeCourse.UserData.methodCfg.Panel.ph = uipanel(timeCourse.UserData.methodCfg.Panel.fh,"Position",[5,5,490,790],"BackgroundColor",[0,0,0]);    
    % timeCourse.UserData.methodCfg.Panel.entryParams = breakoutEditFields(nexon, timeCourse.UserData.methodCfg, defaultArgs, methodCfgValueChangedFcn);
    % % timeCourse.UserData.methodCfg.methodID = 

    
end