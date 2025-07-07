function longPath = getLongPathName(shortPath)
    % Insert empty string path if missing
    if count(py.sys.path,'') == 0
        insert(py.sys.path,int32(0),'');
    end
    
    import py.ctypes.*

    % Load kernel32
    kernel32 = py.ctypes.WinDLL('kernel32');

    % Set argtypes and restype on GetLongPathNameW
    kernel32.GetLongPathNameW.argtypes = py.tuple({py.ctypes.c_wchar_p, py.ctypes.c_wchar_p, py.ctypes.c_uint});
    kernel32.GetLongPathNameW.restype = py.ctypes.c_uint;

    % Create output buffer (260 chars max)
    bufSize = int32(260);
    buf = py.ctypes.create_unicode_buffer(bufSize);

    % Call GetLongPathNameW
    n = kernel32.GetLongPathNameW(shortPath, buf, bufSize);

    % Check result
    if int32(n) == 0
        error('GetLongPathNameW failed for: %s', shortPath);
    end

    % Convert buffer to MATLAB char
    longPath = char(buf.value);
end
