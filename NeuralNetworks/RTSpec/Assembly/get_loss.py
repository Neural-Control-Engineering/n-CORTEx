import numpy as np
from composeSpecs import composeSpecs
import torch

def normalize_z_score(psd):
    mean_val = psd.mean(dim=1, keepdim=True)
    std_val = psd.std(dim=1, keepdim=True)
    return (psd - mean_val) / std_val

def get_loss(params, model, criterion, psd, psd_true, specs_label, mode):
    """
    Compute loss for a batch of data
    """
    # Custom weighting for exponent loss vs other parameters loss
    lambda_exp = 2
    lambda_others = 1
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
    # loss = criterion(specs_pred, specs_label)
    # Logarithmic loss for exponent parameter
    exp_pred = specs_pred[:,:,1]
    exp_label = specs_label[:,:,1]
    # print('EXP pred: ',exp_pred)
    # print('EXP lab: ',exp_label)
    # exp_loss = criterion((exp_pred), (exp_label))
    # print('EXP loss: ',exp_loss)
    # Standard loss for other parameters
    other_pred = torch.cat((specs_pred[:,:,2:], specs_pred[:,:,0:1]),dim=2)
    other_label = torch.cat((specs_label[:,:,2:], specs_label[:,:,0:1]),dim=2)
    # other_loss = criterion(other_pred, other_label)
    # psd_pred = []
    # psd_label = []
    # for i in range(0, specs_pred.shape[0]):
    #     psd_pred.append(composeSpecs(params, specs_pred[i, 0, :]))
    #     psd_label.append(composeSpecs(params, specs_label[i, 0, :]))      
    # # psd_pred = torch.tensor(psd_pred).cuda()
    # psd_pred = psd_pred.permute(0, 2, 1)
    # # psd_label = torch.tensor(psd_label).cuda()
    # psd_label = psd_label.permute(0, 2, 1)
    # print('PSD pred: ',psd_pred.shape)  
    # print('PSD lab: ',psd_label.shape)
    # loss = criterion(psd_pred, psd_label)
    # print('Loss: ',loss)

    batch_size = psd.shape[0]
    total_loss = 0
    print('Specs pred: ',specs_pred.shape)
    print('Specs lab: ',specs_label.shape)
    psd_pred = composeSpecs(params, specs_pred)
    psd_label = composeSpecs(params, specs_label)
    print('PSD pred: ',psd_pred.shape)
    print('PSD lab: ',psd_label.shape)
    print("PSD: ",psd.shape)
    print("PSD true: ",psd_true.shape)
    sample_loss = criterion((psd_pred), (psd_label))
    true_loss = criterion((psd_pred), (psd_true.unsqueeze(1).permute(0,2,1)))
    peaks_loss = criterion(specs_pred[:,:,2:], specs_label[:,:,2:])
    exp_loss = criterion(specs_pred[:,:,1], specs_label[:,:,1])
    off_loss = criterion(specs_pred[:,:,0], specs_label[:,:,0])
    loss = (sample_loss) + (peaks_loss + exp_loss + off_loss)
    # for i in range(batch_size):
    #         # Get the predicted and label FOOOF params for sample i
    #         fooof_pred = specs_pred[i, 0, :]  # No detach, keep in PyTorch
    #         fooof_label = specs_label[i, 0, :]  # No detach
            
    #         # Compose the predicted and true PSDs using FOOOF params (ensure composeSpecs works with PyTorch)
    #         psd_pred = composeSpecs(params, fooof_pred)  # Work with PyTorch tensors
    #         psd_label = composeSpecs(params, fooof_label)

    #         # No need to convert to tensor, as they should already be PyTorch tensors
    #         # Compute loss for this sample
  
            
    #         # Accumulate the loss
    #         total_loss += sample_loss
        
    # Normalize by batch size (or sum, depending on your needs)
    avg_loss = total_loss / batch_size        

    # print('Other loss: ',other_loss)
    # Combine the losses with weights
    # loss = lambda_exp * exp_loss + lambda_others * other_loss

    # specs_label = specs_label[-1, 0, :].cpu().detach().numpy()
    # psd = psd[-1, :].cpu().detach().numpy()
    # sig = composeSpecs(params, specs_label).cpu().detach().numpy()
    # rmse = np.sqrt(np.mean(((psd) - sig)**2))
    # # R^2
    # ss_res = np.sum(((psd) - sig)**2)
    # ss_tot = np.sum(((psd) - np.mean((psd)))**2)
    # r2 = 1 - (ss_res / ss_tot)
    return loss, 0, 0