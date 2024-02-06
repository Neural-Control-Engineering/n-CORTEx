address = '128.59.87.69';
modality = 'photon';
readDataFcnHandle = str2func(sprintf('readDataFcn_%s',modality));
server = tcpserver(address, 5000);
configureCallback(server,"terminator",readDataFcnHandle);
configureTerminator(server,"CR/LF");