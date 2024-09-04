import time
import torch
import torch.nn as nn 
import os

def train(params, model, trainLoader, validLoader, criterion, optimizer):

    # Defaults:
    # criterion = nn.MSELoss(reduction='sum')
    # optimizer = torch.optim.A
    start_time = time.time()
    train_global_losses = []
    val_global_losses = []


    for epoch in range(params.startEpoch, params.endEpoch):
        train_epoch_losses = []
        val_epoch_losses = []
        val_epoch_pcorr = []
        start_epoch = time.time()
        # training mode
        model.train()
        # counter
        count = 0
        for i, data in enumerate(trainLoader):
            adjust_learning_rate(optimizer, epoch, params.endEpoch, params.lr)
            # Pass next sample
            psd = data['PSD']
            psd = psd.cuda(params.local_rank, non_blocking=True)
            specs_label = data['label']
            specs_label = specs_label.cuda(params.local_rank, non_blocking=True)
            # Compute loss
            loss = compute_loss(model, criterion, psd, specs_label, 'train')
            train_epoch_losses.append(loss.item())
            # Gradient propagation
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
        
        # validation mode
        model.eval()
        with torch.no_grad():
            for i, data in enumerate(validLoader):
                # Pass next sample                
                psd = data['PSD']
                psd = psd.cuda(params.local_rank, non_blocking=True)
                specs_label = data['label']
                specs_label = specs_label.cuda(params.local_rank, non_blocking=True)
                # Compute loss
                loss = compute_loss(model, criterion, psd, specs_label, 'val')
                val_epoch_losses.append(loss.item())
                # Calculate Metrics
        
        end_epoch = time.time()

        # Report Epoch-wise average metrics
        train_net_loss = sum(train_epoch_losses)/len(train_epoch_losses)
        val_net_loss = sum(val_epoch_losses)/len(val_epoch_losses)
        train_global_losses.append(train_net_loss)
        val_global_losses.append(val_net_loss)

        # Checkpoint
        if val_global_losses[-1] == min(val_global_losses):
            print('saving model at the end of epoch ' + str(epoch))
            file_name = os.path.join(params.checkpoint_dir, 'model_{}_epoch_{}_val_loss_{}.pth'.format(params.modelName, epoch, val_global_losses[-1]))
            best_epoch = epoch
            if epoch > 1:
                torch.save({
                    'epoch': epoch,
                    'state_dict': model.state_dict(),
                    'optim_dict': optimizer.state_dict(),
                },                
                file_name)
   
    
    end_time = time.time()
    total_time = (end_time - start_time) / 3600
    print('Total training time: {:.2f} hours'.format(total_time))
    print('------------------ TRAINING COMPLETE ------------------')
    # Log results
    log_name = os.path.join(params.log_dir, 'loss_log.txt')
    with open(log_name, "a") as log_file:
        now = time.strftime("%c")
        log_file.write('============ Loss (%s) ============\n' % now)
        log_file.write('best_epoch: ' + str(best_epoch) + '\n')
        log_file.write('train_losses: ')
        log_file.write('%s\n' % train_global_losses)
        log_file.write('validation losses: ')
        log_file.write('%s\n' % val_global_losses)
        log_file.write('training time: ' + str(total_time))
    
    learning_curve(best_epoch, train_global_losses, val_global_losses)

    return model
        
