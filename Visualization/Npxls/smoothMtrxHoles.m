function smthMtrx = smoothMtrxHoles(Mtrx)
    % fills gaps in matrix with average of nearest neighbors
    % holes expected to have value NaN

    smthMtrx = Mtrx;
    kernel = ones(3,3); % smoothing with distance d = 1
    kernel(round(size(kernel,1)/2),round(size(kernel,2)/2))=0;% put 0 at center of kernel
    MtrxMsk = zeros(size(Mtrx,1),size(Mtrx,2));
    
    MtrxMsk(isnan(Mtrx)) = 1;
    
    % apply smoothing
    Mtrx(isnan(Mtrx)) = 0;
    numSurrounding = conv2(~MtrxMsk,kernel,'same'); % store sum of surrounding elements in a matrix
    avgMtrx = conv2(Mtrx,kernel,'same') ./ numSurrounding;
    
    % apply mask
    smthMtrx(isnan(smthMtrx)) = avgMtrx(isnan(smthMtrx));
end