import numpy as np

def adjust_learning_rate(optimizer, epoch, max_epoch, init_lr, power=0.9):
    """Sets the learning rate to the initial LR decayed by 10 every 30 epochs"""
    # lr = init_lr * (1 - epoch / max_epoch) ** power
    lr = round(init_lr * np.power(1 - (epoch / max_epoch), power), 8)
    for param_group in optimizer.param_groups:
        param_group['lr'] = lr    