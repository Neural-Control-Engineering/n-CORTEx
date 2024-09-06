def get_loss(model, criterion, psd, specs_label, mode):
    """
    Compute loss for a batch of data
    """
    # Forward pass
    specs_pred = model(psd)
    # Compute loss
    loss = criterion(specs_pred, specs_label)
    return loss