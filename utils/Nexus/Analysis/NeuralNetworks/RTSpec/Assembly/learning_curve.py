import os
import numpy as np
import matplotlib.pyplot as plt

def learning_curve(params, best_epoch, train_global_losses, val_global_losses):
    fig, ax1 = plt.subplots(figsize=(12,8))
    ax1.set_xlabel('Epochs')
    ax1.set_xticks(np.arange(0, int(len(train_global_losses) + 1), 10))
    
    ax1.set_ylabel('Loss')
    ax1.plot(train_global_losses, '-r', label='Training loss', markersize=3)
    ax1.plot(val_global_losses, '-b', label='Validation loss', markersize=3)
    ax1.axvline(best_epoch, color='m', lw=4, alpha=0.5, label='Best epoch')
    ax1.legend(loc='upper left')
    save_name = os.path.join(params['checkpoint_dir'],('Learning_curve_'+params['modelName']+'.png'))
    plt.savefig(save_name)