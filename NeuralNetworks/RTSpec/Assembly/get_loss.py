import numpy as np
from composeSpecs import composeSpecs

def get_loss(params, model, criterion, psd, specs_label, mode):
    """
    Compute loss for a batch of data
    """
    # Forward pass
    # print(psd.shape)
    specs_pred = model(psd.float().unsqueeze(1))
    specs_label = specs_label.unsqueeze(1)
    # Compute loss
    # print("Pred \n")
    # print(specs_pred.shape)
    # print("Label \n")
    # print(specs_label.shape)
    # print("PSD \n") 
    # print(psd.shape)
    loss = criterion(specs_pred, specs_label)
    specs_label = specs_label[-1, 0, :].cpu().detach().numpy()
    psd = psd[-1, :].cpu().detach().numpy()
    sig = composeSpecs(params, specs_label)
    rmse = np.sqrt(np.mean(((psd) - sig)**2))
    # R^2
    ss_res = np.sum(((psd) - sig)**2)
    ss_tot = np.sum(((psd) - np.mean((psd)))**2)
    r2 = 1 - (ss_res / ss_tot)
    return loss, rmse, r2