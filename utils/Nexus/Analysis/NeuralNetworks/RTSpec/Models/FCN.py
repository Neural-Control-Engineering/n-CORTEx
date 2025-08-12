import torch
import torch.nn as nn
import torch.nn.functional as F
import math
from Models.Transformer import TransformerModel

class specFCN(nn.Module):
    def __init__(self, input_dim=195, output_dim=26, hidden_dims=[256, 128, 64]):
        super(specFCN, self).__init__()
        
        # Define layers
        self.fc1 = nn.Linear(input_dim, hidden_dims[0])
        self.fc2 = nn.Linear(hidden_dims[0], hidden_dims[1])
        self.fc3 = nn.Linear(hidden_dims[1], hidden_dims[2])
        self.fc4 = nn.Linear(hidden_dims[2], output_dim)
        
        # Activation function
        self.relu = nn.ReLU()

    def forward(self, x):
        x = self.relu(self.fc1(x))
        x = self.relu(self.fc2(x))
        x = self.relu(self.fc3(x))
        x = self.fc4(x)  # Final layer without activation for regression
        return x   

class specFCN2(nn.Module):
    def __init__(self, input_size=195, output_size=26, hidden_size=128):
        super(specFCN2, self).__init__()
        
        # Define 6 layers with batch normalization and residual connections
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.bn1 = nn.BatchNorm1d(1)
        
        self.fc2 = nn.Linear(hidden_size, hidden_size)
        self.bn2 = nn.BatchNorm1d(1)
        
        self.fc3 = nn.Linear(hidden_size, hidden_size)
        self.bn3 = nn.BatchNorm1d(1)
        
        self.fc4 = nn.Linear(hidden_size, hidden_size)
        self.bn4 = nn.BatchNorm1d(1)
        
        self.fc5 = nn.Linear(hidden_size, hidden_size)
        self.bn5 = nn.BatchNorm1d(1)

        self.fc6 = nn.Linear(hidden_size, hidden_size)
        self.bn6 = nn.BatchNorm1d(1)

        self.fc4 = nn.Linear(hidden_size, hidden_size)
        self.bn4 = nn.BatchNorm1d(1)
        
        self.fc5 = nn.Linear(hidden_size, hidden_size)
        self.bn5 = nn.BatchNorm1d(1)

        self.fc6 = nn.Linear(hidden_size, hidden_size)
        self.bn6 = nn.BatchNorm1d(1)

        self.fc4 = nn.Linear(hidden_size, hidden_size)
        self.bn4 = nn.BatchNorm1d(1)
        
        self.fc5 = nn.Linear(hidden_size, hidden_size)
        self.bn5 = nn.BatchNorm1d(1)

        self.fc6 = nn.Linear(hidden_size, hidden_size)
        self.bn6 = nn.BatchNorm1d(1)
        
        self.output_layer = nn.Linear(hidden_size, output_size)
        self.relu = nn.ReLU()

    def forward(self, x):
        residual = x
        print(x.shape)
        x = self.fc1(x)
        print(x.shape)
        x = self.bn1(x)
        print(x.shape)
        x = self.relu(x)
        print(x.shape)

        # First residual block (2 layers)
        residual = x
        x = self.fc2(x)
        x = self.bn2(x)
        x = self.relu(x)
        x = self.fc3(x)
        x = self.bn3(x)
        x += residual  # Add residual connection
        x = self.relu(x)

        # Second residual block (2 layers)
        residual = x
        x = self.fc4(x)
        x = self.bn4(x)
        x = self.relu(x)
        x = self.fc5(x)
        x = self.bn5(x)
        x += residual  # Add residual connection
        x = self.relu(x)

        # Sixth layer (without residual)
        x = self.fc6(x)
        x = self.bn6(x)
        x = self.relu(x)

        # Output layer
        x = self.output_layer(x)
        return x    

class specFCN3(nn.Module):
    def __init__(self, input_size=195, output_size=26, hidden_size=128):
        super(specFCN3, self).__init__()
        
        # Define 12 fully connected layers with batch normalization and residual connections
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.bn1 = nn.BatchNorm1d(1)

        self.fc2 = nn.Linear(hidden_size, hidden_size)
        self.bn2 = nn.BatchNorm1d(1)

        self.fc3 = nn.Linear(hidden_size, hidden_size)
        self.bn3 = nn.BatchNorm1d(1)

        self.fc4 = nn.Linear(hidden_size, hidden_size)
        self.bn4 = nn.BatchNorm1d(1)

        self.fc5 = nn.Linear(hidden_size, hidden_size)
        self.bn5 = nn.BatchNorm1d(1)

        self.fc6 = nn.Linear(hidden_size, hidden_size)
        self.bn6 = nn.BatchNorm1d(1)

        self.fc7 = nn.Linear(hidden_size, hidden_size)
        self.bn7 = nn.BatchNorm1d(1)

        self.fc8 = nn.Linear(hidden_size, hidden_size)
        self.bn8 = nn.BatchNorm1d(1)

        self.fc9 = nn.Linear(hidden_size, hidden_size)
        self.bn9 = nn.BatchNorm1d(1)

        self.fc10 = nn.Linear(hidden_size, hidden_size)
        self.bn10 = nn.BatchNorm1d(1)

        self.fc11 = nn.Linear(hidden_size, hidden_size)
        self.bn11 = nn.BatchNorm1d(1)

        self.fc12 = nn.Linear(hidden_size, hidden_size)
        self.bn12 = nn.BatchNorm1d(1)

        # Output layer
        self.output_layer = nn.Linear(hidden_size, output_size)
        self.relu = nn.ReLU()

    def forward(self, x):
        # First layer (no residual)
        x = self.fc1(x)
        x = self.bn1(x)
        x = self.relu(x)

        # First residual block (2 layers)
        residual = x
        x = self.fc2(x)
        x = self.bn2(x)
        x = self.relu(x)
        x = self.fc3(x)
        x = self.bn3(x)
        x += residual  # Add residual connection
        x = self.relu(x)

        # Second residual block (2 layers)
        residual = x
        x = self.fc4(x)
        x = self.bn4(x)
        x = self.relu(x)
        x = self.fc5(x)
        x = self.bn5(x)
        x += residual  # Add residual connection
        x = self.relu(x)

        # Third residual block (2 layers)
        residual = x
        x = self.fc6(x)
        x = self.bn6(x)
        x = self.relu(x)
        x = self.fc7(x)
        x = self.bn7(x)
        x += residual  # Add residual connection
        x = self.relu(x)

        # Fourth residual block (2 layers)
        residual = x
        x = self.fc8(x)
        x = self.bn8(x)
        x = self.relu(x)
        x = self.fc9(x)
        x = self.bn9(x)
        x += residual  # Add residual connection
        x = self.relu(x)

        # Fifth residual block (2 layers)
        residual = x
        x = self.fc10(x)
        x = self.bn10(x)
        x = self.relu(x)
        x = self.fc11(x)
        x = self.bn11(x)
        x += residual  # Add residual connection
        x = self.relu(x)

        # Final layer (without residual)
        x = self.fc12(x)
        x = self.bn12(x)
        x = self.relu(x)

        # Output layer
        x = self.output_layer(x)
        return x

# added dropout

import torch
import torch.nn as nn

class specFCN4(nn.Module):
    def __init__(self, input_size=195, output_size=26, hidden_size=128, dropout_prob=0.1):
        super(specFCN4, self).__init__()
        
        # Define 12 fully connected layers with batch normalization and residual connections
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.bn1 = nn.BatchNorm1d(1)
        
        self.fc2 = nn.Linear(hidden_size, hidden_size)
        self.bn2 = nn.BatchNorm1d(1)

        self.fc3 = nn.Linear(hidden_size, hidden_size)
        self.bn3 = nn.BatchNorm1d(1)

        self.fc4 = nn.Linear(hidden_size, hidden_size)
        self.bn4 = nn.BatchNorm1d(1)

        self.fc5 = nn.Linear(hidden_size, hidden_size)
        self.bn5 = nn.BatchNorm1d(1)

        self.fc6 = nn.Linear(hidden_size, hidden_size)
        self.bn6 = nn.BatchNorm1d(1)

        self.fc7 = nn.Linear(hidden_size, hidden_size)
        self.bn7 = nn.BatchNorm1d(1)

        self.fc8 = nn.Linear(hidden_size, hidden_size)
        self.bn8 = nn.BatchNorm1d(1)

        self.fc9 = nn.Linear(hidden_size, hidden_size)
        self.bn9 = nn.BatchNorm1d(1)

        self.fc10 = nn.Linear(hidden_size, hidden_size)
        self.bn10 = nn.BatchNorm1d(1)

        self.fc11 = nn.Linear(hidden_size, hidden_size)
        self.bn11 = nn.BatchNorm1d(1)

        self.fc12 = nn.Linear(hidden_size, hidden_size)
        self.bn12 = nn.BatchNorm1d(1)

        # Output layer
        self.output_layer = nn.Linear(hidden_size, output_size)

        # Activation and Dropout
        self.relu = nn.ReLU()
        self.dropout = nn.Dropout(p=dropout_prob)

    def forward(self, x):
        # First layer (no residual)
        x = self.fc1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.dropout(x)

        # First residual block (2 layers)
        residual = x
        x = self.fc2(x)
        x = self.bn2(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc3(x)
        x = self.bn3(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Second residual block (2 layers)
        residual = x
        x = self.fc4(x)
        x = self.bn4(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc5(x)
        x = self.bn5(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Third residual block (2 layers)
        residual = x
        x = self.fc6(x)
        x = self.bn6(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc7(x)
        x = self.bn7(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Fourth residual block (2 layers)
        residual = x
        x = self.fc8(x)
        x = self.bn8(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc9(x)
        x = self.bn9(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Fifth residual block (2 layers)
        residual = x
        x = self.fc10(x)
        x = self.bn10(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc11(x)
        x = self.bn11(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Final layer (without residual)
        x = self.fc12(x)
        x = self.bn12(x)
        x = self.relu(x)
        x = self.dropout(x)

        # Output layer
        x = self.output_layer(x)
        return x
    
    import torch
import torch.nn as nn

class specFCN5(nn.Module):
    def __init__(self, input_size=195, output_size=26, hidden_size=128, conv_out_channels=64, kernel_size=10, dropout_prob=0.3):
        super(specFCN5, self).__init__()
        
        # Convolutional layer (1D) to process the PSD input before the FCN
        self.conv1d = nn.Conv1d(in_channels=1, out_channels=conv_out_channels, kernel_size=kernel_size, padding=(kernel_size // 2))
        self.conv_bn = nn.BatchNorm1d(conv_out_channels)
        
        # Adjust the input size for the FCN after convolutional layer
        self.fc_input_size = conv_out_channels * input_size
        
        # Define 10 fully connected layers with batch normalization and residual connections
        self.fc1 = nn.Linear(self.fc_input_size, hidden_size)
        self.bn1 = nn.BatchNorm1d(1)

        self.fc2 = nn.Linear(hidden_size, hidden_size)
        self.bn2 = nn.BatchNorm1d(1)

        self.fc3 = nn.Linear(hidden_size, hidden_size)
        self.bn3 = nn.BatchNorm1d(1)

        self.fc4 = nn.Linear(hidden_size, hidden_size)
        self.bn4 = nn.BatchNorm1d(1)

        self.fc5 = nn.Linear(hidden_size, hidden_size)
        self.bn5 = nn.BatchNorm1d(1)

        self.fc6 = nn.Linear(hidden_size, hidden_size)
        self.bn6 = nn.BatchNorm1d(1)

        self.fc7 = nn.Linear(hidden_size, hidden_size)
        self.bn7 = nn.BatchNorm1d(1)

        self.fc8 = nn.Linear(hidden_size, hidden_size)
        self.bn8 = nn.BatchNorm1d(1)

        self.fc9 = nn.Linear(hidden_size, hidden_size)
        self.bn9 = nn.BatchNorm1d(1)

        self.fc10 = nn.Linear(hidden_size, hidden_size)
        self.bn10 = nn.BatchNorm1d(1)

        # Output layer
        self.output_layer = nn.Linear(hidden_size, output_size)

        # Activation and Dropout
        self.relu = nn.ReLU()
        self.dropout = nn.Dropout(p=dropout_prob)

    def forward(self, x):
        # Reshape input to be compatible with 1D convolution (batch_size, channels, input_size)
        x = x.unsqueeze(1)
        
        # Convolutional layer
        x = self.conv1d(x)
        x = self.conv_bn(x)
        x = self.relu(x)
        
        # Flatten the output for the fully connected layers
        x = x.view(x.size(0), -1)

        # First layer (no residual)
        x = self.fc1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.dropout(x)

        # First residual block (2 layers)
        residual = x
        x = self.fc2(x)
        x = self.bn2(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc3(x)
        x = self.bn3(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Second residual block (2 layers)
        residual = x
        x = self.fc4(x)
        x = self.bn4(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc5(x)
        x = self.bn5(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Third residual block (2 layers)
        residual = x
        x = self.fc6(x)
        x = self.bn6(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc7(x)
        x = self.bn7(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Fourth residual block (2 layers)
        residual = x
        x = self.fc8(x)
        x = self.bn8(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc9(x)
        x = self.bn9(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Final layer (without residual)
        x = self.fc10(x)
        x = self.bn10(x)
        x = self.relu(x)
        x = self.dropout(x)

        # Output layer
        x = self.output_layer(x)
        return x

class specFCN6(nn.Module):
    def __init__(self, input_size=196, output_size=26, hidden_size=128, dropout_prob=0.1):
        super(specFCN6, self).__init__()
        
        # Define 12 fully connected layers with batch normalization and residual connections
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.bn1 = nn.BatchNorm1d(1)
        
        self.fc2 = nn.Linear(hidden_size, hidden_size)
        self.bn2 = nn.BatchNorm1d(1)

        self.fc3 = nn.Linear(hidden_size, hidden_size)
        self.bn3 = nn.BatchNorm1d(1)

        self.fc4 = nn.Linear(hidden_size, hidden_size)
        self.bn4 = nn.BatchNorm1d(1)

        self.fc5 = nn.Linear(hidden_size, hidden_size)
        self.bn5 = nn.BatchNorm1d(1)

        self.fc6 = nn.Linear(hidden_size, hidden_size)
        self.bn6 = nn.BatchNorm1d(1)

        self.fc7 = nn.Linear(hidden_size, hidden_size)
        self.bn7 = nn.BatchNorm1d(1)

        self.fc8 = nn.Linear(hidden_size, hidden_size)
        self.bn8 = nn.BatchNorm1d(1)

        self.fc9 = nn.Linear(hidden_size, hidden_size)
        self.bn9 = nn.BatchNorm1d(1)

        self.fc10 = nn.Linear(hidden_size, hidden_size)
        self.bn10 = nn.BatchNorm1d(1)

        self.fc11 = nn.Linear(hidden_size, hidden_size)
        self.bn11 = nn.BatchNorm1d(1)

        self.fc12 = nn.Linear(hidden_size, hidden_size)
        self.bn12 = nn.BatchNorm1d(1)

        # Output layer
        self.output_layer = nn.Linear(hidden_size, output_size)

        # Activation and Dropout
        self.relu = nn.ReLU()
        self.dropout = nn.Dropout(p=dropout_prob)

    def forward(self, x):
        # First layer (no residual)
        x = self.fc1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.dropout(x)

        # First residual block (2 layers)
        residual = x
        x = self.fc2(x)
        x = self.bn2(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc3(x)
        x = self.bn3(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Second residual block (2 layers)
        residual = x
        x = self.fc4(x)
        x = self.bn4(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc5(x)
        x = self.bn5(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Third residual block (2 layers)
        residual = x
        x = self.fc6(x)
        x = self.bn6(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc7(x)
        x = self.bn7(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Fourth residual block (2 layers)
        residual = x
        x = self.fc8(x)
        x = self.bn8(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc9(x)
        x = self.bn9(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Fifth residual block (2 layers)
        residual = x
        x = self.fc10(x)
        x = self.bn10(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc11(x)
        x = self.bn11(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Final layer (without residual)
        x = self.fc12(x)
        x = self.bn12(x)
        x = self.relu(x)
        x = self.dropout(x)

        # Output layer
        x = self.output_layer(x)
        return x

class specFCN15(nn.Module):
    def __init__(self, input_size=196, output_size=26, hidden_size=128, dropout_prob=0.1):
        super(specFCN15, self).__init__()
        
        # Define 15 fully connected layers with batch normalization, skip connections, and layer normalization
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.bn1 = nn.BatchNorm1d(1)
        
        self.fc2 = nn.Linear(hidden_size, hidden_size)
        self.bn2 = nn.BatchNorm1d(1)

        self.fc3 = nn.Linear(hidden_size, hidden_size)
        self.bn3 = nn.BatchNorm1d(1)

        self.fc4 = nn.Linear(hidden_size, hidden_size)
        self.bn4 = nn.BatchNorm1d(1)

        self.fc5 = nn.Linear(hidden_size, hidden_size)
        self.bn5 = nn.BatchNorm1d(1)

        self.fc6 = nn.Linear(hidden_size, hidden_size)
        self.bn6 = nn.BatchNorm1d(1)

        self.fc7 = nn.Linear(hidden_size, hidden_size)
        self.bn7 = nn.BatchNorm1d(1)

        self.fc8 = nn.Linear(hidden_size, hidden_size)
        self.bn8 = nn.BatchNorm1d(1)

        self.fc9 = nn.Linear(hidden_size, hidden_size)
        self.bn9 = nn.BatchNorm1d(1)

        self.fc10 = nn.Linear(hidden_size, hidden_size)
        self.bn10 = nn.BatchNorm1d(1)

        self.fc11 = nn.Linear(hidden_size, hidden_size)
        self.bn11 = nn.BatchNorm1d(1)

        self.fc12 = nn.Linear(hidden_size, hidden_size)
        self.bn12 = nn.BatchNorm1d(1)

        self.fc13 = nn.Linear(hidden_size, hidden_size)
        self.bn13 = nn.BatchNorm1d(1)

        self.fc14 = nn.Linear(hidden_size, hidden_size)
        self.bn14 = nn.BatchNorm1d(1)

        self.fc15 = nn.Linear(hidden_size, hidden_size)
        self.bn15 = nn.BatchNorm1d(1)

        # Output layer
        self.output_layer = nn.Linear(hidden_size, output_size)

        # Activation and Dropout
        self.relu = nn.ReLU()
        self.dropout = nn.Dropout(p=dropout_prob)

        # Layer Normalization (optional, for extra stability in deeper networks)
        self.layer_norm = nn.LayerNorm(hidden_size)

    def forward(self, x):
        # First layer (no residual)
        x = self.fc1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.dropout(x)

        # First residual block (2 layers)
        residual = x
        x = self.fc2(x)
        x = self.bn2(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc3(x)
        x = self.bn3(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Second residual block (2 layers)
        residual = x
        x = self.fc4(x)
        x = self.bn4(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc5(x)
        x = self.bn5(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Third residual block (2 layers)
        residual = x
        x = self.fc6(x)
        x = self.bn6(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc7(x)
        x = self.bn7(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Fourth residual block (2 layers)
        residual = x
        x = self.fc8(x)
        x = self.bn8(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc9(x)
        x = self.bn9(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Fifth residual block (2 layers)
        residual = x
        x = self.fc10(x)
        x = self.bn10(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc11(x)
        x = self.bn11(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Sixth residual block (2 layers)
        residual = x
        x = self.fc12(x)
        x = self.bn12(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc13(x)
        x = self.bn13(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Seventh residual block (2 layers)
        residual = x
        x = self.fc14(x)
        x = self.bn14(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc15(x)
        x = self.bn15(x)
        x += residual  # Add residual connection
        x = self.relu(x)
        x = self.dropout(x)

        # Layer Normalization (optional)
        x = self.layer_norm(x)

        # Output layer
        x = self.output_layer(x)
        return x