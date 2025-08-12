import torch

def residual_percent(y_true, y_pred):    
    # Residual Sum of Squares (RSS) over the whole batch
    rss = torch.abs(torch.sum((y_true - y_pred),-1))
    tss = torch.abs(torch.sum(y_true,-1))
    
    # Residual Percent for the batch
    residual_percent = (rss / tss) * 100
    # print("Residual Percent: ",residual_percent)
    # print("Residual shape: ",residual_percent.shape)
    
    return residual_percent  # Return as a batch vector