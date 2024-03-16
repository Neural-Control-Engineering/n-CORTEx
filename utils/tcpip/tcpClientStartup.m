
% address = '128.59.87.69';
% model = 'SSpNeuromod';
% load_system(model);
% mdlWks = get_param(model,'ModelWorkspace');
% model = 'SSpNeuromod_SW';
% load_system(model);
% mdlWks = get_param(model,'ModelWorkspace');
address = "164.254.103.10";
client = tcpclient(address,8001)
% writeline(client,"donothing")
% assignin(mdlWks,'client',client)
% save_system(model);
tcpclient('128.59.87.29',5000)