% address = '128.59.87.69';
address = '169.254.149.124';
% address = '192.168.8.10';
modality = 'npxls';
readDataFcnHandle = str2func(sprintf('readDataFcn_%s',modality));
server = tcpserver(address, 5000);
configureCallback(server,"terminator",readDataFcnHandle);
configureTerminator(server,"CR/LF");


% ETHERNET
% Create a TCP/IP object
% tcpipObj = tcpip(address, 8080); % Specify the IP address and port number of the device you want to connect to
% 
% % Set properties of the TCP/IP object
% set(tcpipObj, 'InputBufferSize', 1024); % Set the size of the input buffer
% set(tcpipObj, 'Timeout', 10); % Set the timeout value in seconds
% 
% % Open the connection
% fopen(tcpipObj);
% 
% % Read data from the connection
% data = fread(tcpipObj, tcpipObj.BytesAvailable);
% 
% % Close the connection
% fclose(tcpipObj);