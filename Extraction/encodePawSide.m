function pawEnum = encodePawSide(pawSide)
    % Left = 1
    % Right = 2
    % None = 3
    switch  string(pawSide)
        case 'L'
            pawEnum = 1;
        case 'R'
            pawEnum = 2;
        otherwise
            pawEnum = 3;
    end
end