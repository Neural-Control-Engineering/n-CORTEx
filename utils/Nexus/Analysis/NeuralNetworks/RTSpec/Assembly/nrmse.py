import torch

def nrmse(y_target, y_pred):
    
    
    # Compute the range of the target values
    # print("NDIM: ",y_target.ndim)
    if y_target.ndim == 2:
        rmse = torch.abs(y_target - y_pred)
        y_range = torch.abs(y_target)
    else:
        # Compute the root mean squared error
        rmse = torch.sqrt(torch.mean((y_target - y_pred) ** 2,-1))
        y_range = torch.max(y_target, dim=y_target.ndim-1)[0] - torch.min(y_target, dim=y_target.ndim-1)[0]
    # Compute the normalized root mean squared error
    nrmse = (rmse / y_range) * 100
    # print("NRMSE: ",nrmse)
    # print("NRMSE shape: ",nrmse.shape)
    
    return nrmse  # Return as a float