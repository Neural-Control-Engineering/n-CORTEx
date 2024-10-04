import torch
import torch.nn as nn
import torch.nn.functional as F
import math
# from Models.Transformer import TransformerModel

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

class LSTM50(nn.Module):
    def __init__(self, input_size=196, output_size=26, hidden_size=50, num_layers=5, dropout_prob=0.1):
        super(LSTM50, self).__init__()

        # LSTM layers
        self.lstm = nn.LSTM(input_size=1, hidden_size=hidden_size, num_layers=num_layers, 
                            batch_first=True, dropout=dropout_prob, bidirectional=False)

        # Fully connected layer to produce the final output
        self.fc = nn.Linear(hidden_size * input_size, output_size)

        # Activation function
        self.relu = nn.ReLU()

    def forward(self, x):
        # Assuming input is (batch_size, 1, input_size)
        # Reshape to (batch_size, input_size, 1) for LSTM
        # x = x.unsqueeze(-1)
        x = x.permute(0, 2, 1)
        # x = x.squeeze(1)
        
        # LSTM forward pass
        lstm_out, (hn, cn) = self.lstm(x)

        # Flatten the LSTM output
        x = lstm_out.contiguous().view(lstm_out.size(0), -1)

        # Fully connected layer
        x = self.fc(x)

        return x.unsqueeze(1)
    
class biLSTM50(nn.Module):
    def __init__(self, input_size=196, output_size=26, hidden_size=50, num_layers=5, dropout_prob=0.1):
        super(biLSTM50, self).__init__()

        # LSTM layers
        self.lstm = nn.LSTM(input_size=1, hidden_size=hidden_size, num_layers=num_layers, 
                            batch_first=True, dropout=dropout_prob, bidirectional=True)

        # Fully connected layer to produce the final output
        self.fc = nn.Linear(hidden_size * input_size * 2, output_size)

        # Activation function
        self.relu = nn.ReLU()

    def forward(self, x):
        # Assuming input is (batch_size, 1, input_size)
        # Reshape to (batch_size, input_size, 1) for LSTM
        # x = x.unsqueeze(-1)
        x = x.permute(0, 2, 1)
        # x = x.squeeze(1)
        
        # LSTM forward pass
        lstm_out, (hn, cn) = self.lstm(x)

        # Flatten the LSTM output
        x = lstm_out.contiguous().view(lstm_out.size(0), -1)

        # Fully connected layer
        x = self.fc(x)

        return x.unsqueeze(1)
    
class resBiLSTM50(nn.Module):
    def __init__(self, input_size=196, output_size=26, hidden_size=50, num_layers=5, dropout_prob=0.1):
        super(resBiLSTM50, self).__init__()

        # Bidirectional LSTM layers with residual connections
        self.num_layers= num_layers
        self.lstm_layers = nn.ModuleList()
        for i in range(num_layers):
            input_dim = 1 if i == 0 else hidden_size * 2  # First layer takes input_size, others take hidden_size * 2
            self.lstm_layers.append(
                nn.LSTM(input_size=input_dim, hidden_size=hidden_size, num_layers=1, 
                        batch_first=True, dropout=dropout_prob, bidirectional=True)
            )
        
        # Fully connected layer to map to the output size
        self.fc = nn.Linear(hidden_size * 2 * input_size, output_size)

        # Activation function
        self.relu = nn.ReLU()
        
    def forward(self, x):
        # Reshape input to (batch_size, input_size, 1)
        # x = x.unsqueeze(-1)  # (batch_size, input_size, 1)
        x = x.permute(0, 2, 1) 

        residual = x  # Save the input for the first residual connection

        # Pass through the LSTM layers with residual connections
        for i in range(self.num_layers):
            lstm_out, _ = self.lstm_layers[i](x)
            # print("LSTM out shape: ", lstm_out.shape)
            
            # Add residual connection (input to the LSTM is added to its output)
            x = lstm_out + residual

            # Update residual for next layer
            residual = x
        
        # Flatten the LSTM output for fully connected layer
        x = x.contiguous().view(x.size(0), -1)

        # Fully connected layer
        x = self.fc(x)

        return x.unsqueeze(1)

class LSTM75(nn.Module):
    def __init__(self, input_size=196, output_size=26, hidden_size=75, num_layers=5, dropout_prob=0.1):
        super(LSTM75, self).__init__()

        # LSTM layers
        self.lstm = nn.LSTM(input_size=1, hidden_size=hidden_size, num_layers=num_layers, 
                            batch_first=True, dropout=dropout_prob, bidirectional=False)

        # Fully connected layer to produce the final output
        self.fc = nn.Linear(hidden_size * input_size, output_size)

        # Activation function
        self.relu = nn.ReLU()

    def forward(self, x):
        # Assuming input is (batch_size, 1, input_size)
        # Reshape to (batch_size, input_size, 1) for LSTM
        # x = x.unsqueeze(-1)
        x = x.permute(0, 2, 1)
        # x = x.squeeze(1)
        
        # LSTM forward pass
        lstm_out, (hn, cn) = self.lstm(x)

        # Flatten the LSTM output
        x = lstm_out.contiguous().view(lstm_out.size(0), -1)

        # Fully connected layer
        x = self.fc(x)

        return x.unsqueeze(1)


# # Example usage
# model = LSTMModel()
# input_tensor = torch.randn(32, 196)  # Batch of 32, PSD of size 196
# output = model(input_tensor)
# print(output.shape)  # Expected output shape: (32, 1, 26)
