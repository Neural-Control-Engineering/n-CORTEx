import torch

def r2_percent(y_true, y_pred):
    # Mean of all true values across the batch
    y_mean = torch.mean(y_true,0)
    
    # Total Sum of Squares (TSS) over the whole batch
    tss = torch.sum((y_true - y_mean) ** 2,0)
    # print("TSS",tss.shape)
    
    # Residual Sum of Squares (RSS) over the whole batch
    rss = torch.sum((y_true - y_pred) ** 2,0)
    # print("RSS",rss.shape)
    
    # R^2 Score for the batch
    r2 = (1 - (rss / tss)) * 100

    # print("R^2 Percent: ",r2)
    # print("R^2 shape: ",r2.shape)
    
    return torch.mean(r2,-1)  # Return as a float
