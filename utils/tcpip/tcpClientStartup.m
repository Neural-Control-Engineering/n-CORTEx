
address = '128.59.87.69';
model = 'SSpNeuromod';
load_system(model);
mdlWks = get_param(model,'ModelWorkspace');

address = '169.254.103.10';
% model = 'SSpNeuromod_SW';
% load_system(model);
% mdlWks = get_param(model,'ModelWorkspace');

client = tcpclient(address,5000,"Timeout",5)
% writeline(client,"donothing")
assignin(mdlWks,'client',client)
save_system(model);