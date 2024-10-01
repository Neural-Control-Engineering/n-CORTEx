import torch

def collectPeakParam(y, peakParam, numPeaks):
    if peakParam == 'CF':
        startIdx = 2
    elif peakParam == 'PW':
        startIdx = 3
    elif peakParam == 'BW':
        startIdx = 4
    else:
        print("Invalid peak parameter")
        return None
    peakParams= []
    for i in range(numPeaks):
        ptrIdx = startIdx + i*3
        # Append the entire flattened tensor for that peak
        # print("sliceShape: ",y[:,:,ptrIdx].shape)
        peakParams.append(y[:,:,ptrIdx])
    
    peakParams = torch.stack(peakParams)  # Convert the list to a tensor if needed
    # print("Peak Parameters: ", peakParam, "\n", peakParams)
    # print("Peak Parameters shape: ", peakParams.shape)
    
    return peakParams.permute(1,2,0)