import time
import torch
import torch.nn as nn 
import os
from learning_curve import learning_curve
from get_loss import get_loss
from adjust_learning_rate import adjust_learning_rate
from plotSpectralFit import plotSpectralFit
from savePredictionToGif import savePredictionToGif

def train(params, model, trainLoader, validLoader, criterion, optimizer, scheduler):

    # Defaults:
    # criterion = nn.MSELoss(reduction='sum')
    # optimizer = torch.optim.A
    start_time = time.time()
    train_global_losses = []
    val_global_losses = []
    train_global_rmse = []
    val_global_rmse = []
    train_global_r2 = []
    val_global_r2 = []
    # Enable gradient calculation for training
    torch.set_grad_enabled(True)
    model.cuda(params['local_rank'])

    # make training itr directory
    os.makedirs(params['checkpoint_dir'], exist_ok=True)
    # save params
    torch.save(params, os.path.join(params['checkpoint_dir'], 'params.pth'))


    for epoch in range(params['startEpoch'], params['endEpoch']):
        train_epoch_losses = []
        train_epoch_rmse = []
        train_epoch_r2 = []
        val_epoch_losses = []
        val_epoch_rmse = []
        val_epoch_r2 = []        

        start_epoch = time.time()
        # training mode
        model.train()
        # counter
        count = 0
        for i, data in enumerate(trainLoader):
            adjust_learning_rate(optimizer, epoch, params['endEpoch'], params['learningRate'], 0.9)
            # Pass next sample
            psd = data['PSD']
            psd_z = data['PSD_z']
            psd_z = psd_z.cuda(params['local_rank'], non_blocking=True)
            psd = psd.cuda(params['local_rank'], non_blocking=True)
            specs_label = data['label']
            specs_label = specs_label.cuda(params['local_rank'], non_blocking=True)
            # Compute loss
            loss, rmse, r2, r2_prct_off, resid_prct_off, nrmse_off, r2_prct_exp, resid_prct_exp, nrmse_exp, r2_prct_CF, resid_prct_CF, nrmse_CF, r2_prct_BW, resid_prct_BW, nrmse_BW, r2_prct_PW, resid_prct_PW, nrmse_PW, r2_prct_total, resid_total, nrmse_total = get_loss(params, model, criterion, psd_z, psd, specs_label, 'train')
            # print("Training loss: ", loss.item())
            train_epoch_losses.append(loss.item())            
            train_epoch_rmse.append(rmse)
            train_epoch_r2.append(r2)
            # Gradient propagation
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            # scheduler.step()
            # print(f"Epoch {epoch+1}/{params['endEpoch']}, Learning Rate: {scheduler.get_last_lr()[0]}, Loss: {loss.item()}")
        
        # validation mode
        model.eval()
        with torch.no_grad():
            for i, data in enumerate(validLoader):
                # Pass next sample                
                psd = data['PSD']
                psd_z = data['PSD_z']
                psd_z = psd_z.cuda(params['local_rank'], non_blocking=True)
                psd = psd.cuda(params['local_rank'], non_blocking=True)
                specs_label = data['label']
                specs_label = specs_label.cuda(params['local_rank'], non_blocking=True)
                # Compute loss
                loss, rmse, r2, r2_prct_off, resid_prct_off, nrmse_off, r2_prct_exp, resid_prct_exp, nrmse_exp, r2_prct_CF, resid_prct_CF, nrmse_CF, r2_prct_BW, resid_prct_BW, nrmse_BW, r2_prct_PW, resid_prct_PW, nrmse_PW, r2_prct_total, resid_total, nrmse_total  = get_loss(params, model, criterion, psd_z, psd, specs_label, 'val')                
                # print("Validation loss: ", loss.item())
                val_epoch_losses.append(loss.item())
                val_epoch_rmse.append(rmse)
                val_epoch_r2.append(r2)
                # Calculate Metrics
        
        end_epoch = time.time()
        
        # plot validation comparison
        specs_pred = model(psd_z.float().unsqueeze(1))
        # print("PRED: ", specs_pred.shape)        
        specs_label = specs_label.unsqueeze(1)
        # print("LABEL: ",specs_label.shape)        
        plotSpectralFit(params, specs_label.cpu().detach().numpy()[:, :, :], psd.cpu().detach().numpy()[:,:],"LABEL")
        plotSpectralFit(params, specs_pred.cpu().detach().numpy()[:, :, :], psd.cpu().detach().numpy()[:,:], "PREDICTION")   
        # GENERATE GIF (LEARNING PROGRESS)
        # savePredictionToGif(params, specs_label.cpu().detach().numpy()[:, :, :], psd.cpu().detach().numpy()[:,:], specs_pred.cpu().detach().numpy()[:, :, :])      
        # Report Epoch-wise average metrics
        train_net_loss = sum(train_epoch_losses)/len(train_epoch_losses)
        val_net_loss = sum(val_epoch_losses)/len(val_epoch_losses)
        train_net_rmse = sum(train_epoch_rmse)/len(train_epoch_rmse)
        val_net_rmse = sum(val_epoch_rmse)/len(val_epoch_rmse)
        train_net_r2 = sum(train_epoch_r2)/len(train_epoch_r2)
        val_net_r2 = sum(val_epoch_r2)/len(val_epoch_r2)
        # Global metrics
        train_global_losses.append(train_net_loss)
        val_global_losses.append(val_net_loss)
        train_global_rmse.append(train_net_rmse)
        val_global_rmse.append(val_net_rmse)
        train_global_r2.append(train_net_r2)
        val_global_r2.append(val_net_r2)

        # Print epoch-wise metrics
        print('Epoch: {} | Train Loss: {} | Val Loss: {} | Train RMSE: {} | Val RMSE {} | Train R2: {} | Val R2: {}'.format(epoch, train_net_loss, val_net_loss, train_net_rmse, val_net_rmse, train_net_r2, val_net_r2))

        # Checkpoint
        if val_global_losses[-1] == min(val_global_losses):
            print('saving model at the end of epoch ' + str(epoch))
            file_name = os.path.join(params['checkpoint_dir'], 'model_{}_epoch_{}_val_loss_{}.pth'.format(params['modelName'], epoch, val_global_losses[-1]))
            best_epoch = epoch
            if epoch > 1:
                torch.save({
                    'epoch': epoch,
                    'state_dict': model.state_dict(),
                    'optim_dict': optimizer.state_dict(),
                    'modelType': params['modelName'],
                },                
                file_name)
        # elif val_global_rmse[-1] == min(val_global_rmse):
        #     print('saving model at the end of epoch ' + str(epoch))
        #     file_name = os.path.join(params['checkpoint_dir'], 'model_{}_epoch_{}_val_rmse_{}.pth'.format(params['modelName'], epoch, val_global_rmse[-1]))
        #     best_epoch = epoch
        #     if epoch > 1:
        #         torch.save({
        #             'epoch': epoch,
        #             'state_dict': model.state_dict(),
        #             'optim_dict': optimizer.state_dict(),
        #         },                
        #         file_name)
        # elif val_global_r2[-1] == max(val_global_r2):
        #     print('saving model at the end of epoch ' + str(epoch))
        #     file_name = os.path.join(params['checkpoint_dir'], 'model_{}_epoch_{}_val_r2_{}.pth'.format(params['modelName'], epoch, val_global_r2[-1]))
        #     best_epoch = epoch
        #     if epoch > 1:
        #         torch.save({
        #             'epoch': epoch,
        #             'state_dict': model.state_dict(),
        #             'optim_dict': optimizer.state_dict(),
        #         },                
        #         file_name)
        
   
    
    end_time = time.time()
    total_time = (end_time - start_time) / 3600
    print('Total training time: {:.2f} hours'.format(total_time))
    print('------------------ TRAINING COMPLETE ------------------')
    # Log results
    log_name = os.path.join(params['log_dir'], 'loss_log.txt')
    with open(log_name, "a") as log_file:
        now = time.strftime("%c")
        log_file.write('============ Loss (%s) ============\n' % now)
        log_file.write('best_epoch: ' + str(best_epoch) + '\n')
        log_file.write('train_losses: ')
        log_file.write('%s\n' % train_global_losses)
        log_file.write('validation losses: ')
        log_file.write('%s\n' % val_global_losses)
        log_file.write('training time: ' + str(total_time))
    
    learning_curve(params, best_epoch, train_global_losses, val_global_losses)

    return model
        
