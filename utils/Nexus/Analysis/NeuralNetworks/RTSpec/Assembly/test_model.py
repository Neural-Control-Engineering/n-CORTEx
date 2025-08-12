import time
import torch
import torch.nn as nn 
import numpy as np
import os
from learning_curve import learning_curve
from get_loss import get_loss
from adjust_learning_rate import adjust_learning_rate
from plotSpectralFit import plotSpectralFit

def test_model(params, model, testLoader, criterion):
    model.eval()
    test_losses = []    
    test_r2_prct_off = []
    test_resid_prct_off = []
    test_nrmse_off = []
    test_r2_prct_exp = []
    test_resid_prct_exp = []
    test_nrmse_exp = []
    test_r2_prct_CF = []
    test_resid_prct_CF = []
    test_nrmse_CF = []
    test_r2_prct_BW = []
    test_resid_prct_BW = []
    test_nrmse_BW = []
    test_r2_prct_PW = []
    test_resid_prct_PW = []
    test_nrmse_PW = []
    test_r2_prct_total = []
    test_resid_total = []
    test_nrmse_total = []

    with torch.no_grad():
        for i, data in enumerate(testLoader):
            # Pass next sample                
            psd = data['PSD']
            psd_z = data['PSD_z']
            psd_z = psd_z.cuda(params['local_rank'], non_blocking=True)
            psd = psd.cuda(params['local_rank'], non_blocking=True)
            specs_label = data['label']
            specs_label = specs_label.cuda(params['local_rank'], non_blocking=True)
            # Compute loss / Calculate Metrics
            loss, rmse, r2, r2_prct_off, resid_prct_off, nrmse_off, r2_prct_exp, resid_prct_exp, nrmse_exp, r2_prct_CF, resid_prct_CF, nrmse_CF, r2_prct_BW, resid_prct_BW, nrmse_BW, r2_prct_PW, resid_prct_PW, nrmse_PW, r2_prct_total, resid_total, nrmse_total = get_loss(params, model, criterion, psd_z, psd, specs_label, 'test')
            # print("Validation loss: ", loss.item())
            # print("RESID SINGLE SHAPE", resid_prct_off.shape)
            # print("NRMS SINGLE SHAPE", nrmse_off.shape)
            # print("RESID SINGLE SHAPE CF", resid_prct_CF.shape)
            # print("NRMS SINGLE SHAPE CF", nrmse_CF.shape)
            test_losses.append(loss.item())            
            test_r2_prct_off.append(r2_prct_off)
            test_resid_prct_off.append(resid_prct_off)
            test_nrmse_off.append(nrmse_off)
            test_r2_prct_exp.append(r2_prct_exp)
            test_resid_prct_exp.append(resid_prct_exp)
            test_nrmse_exp.append(nrmse_exp)
            test_r2_prct_CF.append(r2_prct_CF)
            test_resid_prct_CF.append(resid_prct_CF)
            test_nrmse_CF.append(nrmse_CF)
            test_r2_prct_BW.append(r2_prct_BW)
            test_resid_prct_BW.append(resid_prct_BW)
            test_nrmse_BW.append(nrmse_BW)
            test_r2_prct_PW.append(r2_prct_PW)
            test_resid_prct_PW.append(resid_prct_PW)
            test_nrmse_PW.append(nrmse_PW)         
            test_r2_prct_total.append(r2_prct_total)
            test_resid_total.append(resid_total)
            test_nrmse_total.append(nrmse_total)                                       
            # print("Total NRMSE SHAPE", len(test_nrmse_total))
            # print("Total RESID SHAPE", len(test_resid_total))
            # VISUALIZE OUTPUTS
            specs_pred = model(psd_z.float().unsqueeze(1))
            # print("PRED: ", specs_pred.shape)        
            specs_label = specs_label.unsqueeze(1)
            # print("LABEL: ",specs_label.shape)        
            if np.mod(i, 500) == 0:
                plotSpectralFit(params, specs_label.cpu().detach().numpy()[:, :, :], psd.cpu().detach().numpy()[:,:],"LABEL")
                plotSpectralFit(params, specs_pred.cpu().detach().numpy()[:, :, :], psd.cpu().detach().numpy()[:,:], "PREDICTION") 
    
    # Bar plots of error metrics for all params
    test_resid_prct_off = torch.cat(test_resid_prct_off,0)
    test_resid_prct_exp = torch.cat(test_resid_prct_exp,0)
    test_resid_prct_CF = torch.cat(test_resid_prct_CF,0)
    test_resid_prct_BW = torch.cat(test_resid_prct_BW,0)
    test_resid_prct_PW = torch.cat(test_resid_prct_PW,0)
    test_resid_total = torch.cat(test_resid_total,0)
    # print("test_resid_off: ",test_resid_prct_CF.shape)
    test_nrmse_off = torch.cat(test_nrmse_off,0)
    test_nrmse_exp = torch.cat(test_nrmse_exp,0)
    test_nrmse_CF = torch.cat(test_nrmse_CF,0)
    test_nrmse_BW = torch.cat(test_nrmse_BW,0)
    test_nrmse_PW = torch.cat(test_nrmse_PW,0)    
    test_nrmse_total = torch.cat(test_nrmse_total,0)
    # mean_r2_off = np.mean(test_r2_prct_off)
    # std_r2_off = np.std(test_r2_prct_off) / np.sqrt(len(test_r2_prct_off))
    # mean_r2_exp = np.mean(test_r2_prct_exp)
    # std_r2_exp = np.std(test_r2_prct_exp) / np.sqrt(len(test_r2_prct_exp))
    # mean_r2_CF = np.mean(test_r2_prct_CF)
    # std_r2_CF = np.std(test_r2_prct_CF) / np.sqrt(len(test_r2_prct_CF))
    # mean_r2_BW = np.mean(test_r2_prct_BW)
    # std_r2_BW = np.std(test_r2_prct_BW) / np.sqrt(len(test_r2_prct_BW))
    # mean_r2_PW = np.mean(test_r2_prct_PW)
    # std_r2_PW = np.std(test_r2_prct_PW) / np.sqrt(len(test_r2_prct_PW))
    # mean_r2_total = np.mean(test_r2_prct_total)
    # std_r2_total = np.std(test_r2_prct_total) / np.sqrt(len(test_r2_prct_total))
    # Residuals
    mean_resid_off = torch.mean(test_resid_prct_off)
    std_resid_off = torch.std(test_resid_prct_off) / torch.sqrt(torch.tensor(len(test_resid_prct_off), dtype=torch.float32))
    mean_resid_exp = torch.mean(test_resid_prct_exp)
    std_resid_exp = torch.std(test_resid_prct_exp) / torch.sqrt(torch.tensor(len(test_resid_prct_exp), dtype=torch.float32))
    mean_resid_CF = torch.mean(test_resid_prct_CF)
    std_resid_CF = torch.std(test_resid_prct_CF) / torch.sqrt(torch.tensor(len(test_resid_prct_CF), dtype=torch.float32))
    mean_resid_BW = torch.mean(test_resid_prct_BW)
    std_resid_BW = torch.std(test_resid_prct_BW) / torch.sqrt(torch.tensor(len(test_resid_prct_BW), dtype=torch.float32))
    mean_resid_PW = torch.mean(test_resid_prct_PW)
    std_resid_PW = torch.std(test_resid_prct_PW) / torch.sqrt(torch.tensor(len(test_resid_prct_PW), dtype=torch.float32))
    mean_resid_total = torch.mean(test_resid_total)
    std_resid_total = torch.std(test_resid_total) / torch.sqrt(torch.tensor(len(test_resid_total), dtype=torch.float32))
    # NRMSE
    mean_nrmse_off = torch.mean(test_nrmse_off)
    std_nrmse_off = torch.std(test_nrmse_off) / torch.sqrt(torch.tensor(len(test_nrmse_off), dtype=torch.float32))
    mean_nrmse_exp = torch.mean(test_nrmse_exp)
    std_nrmse_exp = torch.std(test_nrmse_exp) / torch.sqrt(torch.tensor(len(test_nrmse_exp), dtype=torch.float32))
    mean_nrmse_CF = torch.mean(test_nrmse_CF)
    std_nrmse_CF = torch.std(test_nrmse_CF) / torch.sqrt(torch.tensor(len(test_nrmse_CF), dtype=torch.float32))
    mean_nrmse_BW = torch.mean(test_nrmse_BW)
    std_nrmse_BW = torch.std(test_nrmse_BW) / torch.sqrt(torch.tensor(len(test_nrmse_BW), dtype=torch.float32))
    mean_nrmse_PW = torch.mean(test_nrmse_PW)
    std_nrmse_PW = torch.std(test_nrmse_PW) / torch.sqrt(torch.tensor(len(test_nrmse_PW), dtype=torch.float32))
    mean_nrmse_total = torch.mean(test_nrmse_total)
    std_nrmse_total = torch.std(test_nrmse_total) / torch.sqrt(torch.tensor(len(test_nrmse_total), dtype=torch.float32))
    # Print metrics
    # print("R2 Off: ", mean_r2_off, "+/-", std_r2_off)
    # print("R2 Exp: ", mean_r2_exp, "+/-", std_r2_exp)
    # print("R2 CF: ", mean_r2_CF, "+/-", std_r2_CF)
    # print("R2 BW: ", mean_r2_BW, "+/-", std_r2_BW)
    # print("R2 PW: ", mean_r2_PW, "+/-", std_r2_PW)
    # print("R2 Total: ", mean_r2_total, "+/-", std_r2_total)
    print("Resid Off: ", mean_resid_off, "+/-", std_resid_off)
    print("Resid Exp: ", mean_resid_exp, "+/-", std_resid_exp)
    print("Resid CF: ", mean_resid_CF, "+/-", std_resid_CF)
    print("Resid BW: ", mean_resid_BW, "+/-", std_resid_BW)
    print("Resid PW: ", mean_resid_PW, "+/-", std_resid_PW)
    print("Resid Total: ", mean_resid_total, "+/-", std_resid_total)
    print("NRMSE Off: ", mean_nrmse_off, "+/-", std_nrmse_off)
    print("NRMSE Exp: ", mean_nrmse_exp, "+/-", std_nrmse_exp)
    print("NRMSE CF: ", mean_nrmse_CF, "+/-", std_nrmse_CF)
    print("NRMSE BW: ", mean_nrmse_BW, "+/-", std_nrmse_BW)
    print("NRMSE PW: ", mean_nrmse_PW, "+/-", std_nrmse_PW)   
    print("NRMSE Total: ", mean_nrmse_total, "+/-", std_nrmse_total)
    
    return test_losses, mean_resid_off, std_resid_off, mean_resid_exp, std_resid_exp, mean_resid_CF, std_resid_CF, mean_resid_BW, std_resid_BW, mean_resid_PW, std_resid_PW, mean_nrmse_off, std_nrmse_off, mean_nrmse_exp, std_nrmse_exp, mean_nrmse_CF, std_nrmse_CF, mean_nrmse_BW, std_nrmse_BW, mean_nrmse_PW, std_nrmse_PW, mean_resid_total, mean_nrmse_total, std_resid_total, std_nrmse_total