function axon()
    elems(1) = Simulink.BusElement;
    elems(1).Name = 'CMD'
    elems(1).DataType = 'uint'
end