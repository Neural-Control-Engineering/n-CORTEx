function busTest() 
% BUSTEST initializes a set of bus objects in the MATLAB base workspace 

% Bus object: BusObject 
clear elems;
BusObject = Simulink.Bus;
BusObject.HeaderFile = '';
BusObject.Description = '';
BusObject.DataScope = 'Auto';
BusObject.Alignment = -1;
BusObject.PreserveElementDimensions = 0;
assignin('base','BusObject', BusObject);

