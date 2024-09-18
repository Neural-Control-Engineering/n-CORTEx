import torch
import torch.nn as nn
import torch.nn.functional as F
import math
from Models.Transformer import TransformerModel

class specLSTM(nn.Module):
    def __init__(self, input_dim=195, output_dim=26, hidden_dim=128, num_layers=6, dropout=0.1):
        super(specLSTM, self).__init__()
        
        # LSTM layer
        self.lstm = nn.LSTM(input_size=input_dim, hidden_size=hidden_dim, num_layers=num_layers, batch_first=True, dropout=dropout)
        
        # Fully connected layer
        self.fc = nn.Linear(hidden_dim, output_dim)

    def forward(self, x):
        # LSTM forward pass
        lstm_out, (hn, cn) = self.lstm(x)
        
        # Take the last output from the LSTM (many-to-one)
        last_lstm_out = lstm_out[:, -1, :]
        
        # Fully connected layer
        output = self.fc(last_lstm_out)
        print("Output shape: ", output.unsqueeze(1).shape)
        return output.unsqueeze(1)  