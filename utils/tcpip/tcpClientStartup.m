
% address = '128.59.87.69';
% model = 'SSpNeuromod';
% load_system(model);
% mdlWks = get_param(model,'ModelWorkspace');
% model = 'SSpNeuromod_SW';
% load_system(model);
% mdlWks = get_param(model,'ModelWorkspace');
address = '169.254.103.10';
client = tcpclient(address,8001,"Timeout",5)
% writeline(client,"donothing")
% assignin(mdlWks,'client',client)
% save_system(model);