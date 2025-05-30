function ax = axon(class)
    switch class
        case "command"
            elems(1) = Simulink.BusElement;
            elems(1).Name = 'CMD'
            elems(1).DataType = 'uint'
            ax.CMD
            ax.SZE
        case "stream"            
            ax.SZE
            ax.PYD
    end
end

ax.CMD
ax.SZE
ax.PYD.signal_L
ax.PYD.signal_M
ax.PYD.tag
