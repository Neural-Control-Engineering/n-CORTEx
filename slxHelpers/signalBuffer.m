function buffer_out = signalBuffer(dim, buffer_in, val)
    buffer_out = buffer_in(2:end);
    buffer_out = cat(dim, buffer_out, val);
end