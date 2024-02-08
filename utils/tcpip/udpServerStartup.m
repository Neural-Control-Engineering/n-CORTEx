address = '169.254.103.3';
% address = '192.168.8.10';
modality = 'photon';
readDataFcnHandle = str2func(sprintf('readDataFcn_%s',modality));
u = udpport("LocalHost",address)
configureCallback(u,"terminator",readDataFcnHandle);
configureTerminator(u,"CR/LF");