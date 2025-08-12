import torch
import torch.nn as nn
import torch.nn.functional as F
import math
from Models.Transformer import TransformerModel

import torch
import torch.nn as nn

class FCNN5(nn.Module):
    def __init__(self, input_size=196, output_size=26, num_channels=50, dropout_prob=0.1):
        super(FCNN5, self).__init__()

        # First two layers with kernel size 20
        self.conv1 = nn.Conv1d(in_channels=1, out_channels=num_channels, kernel_size=20, padding=9)
        self.bn1 = nn.BatchNorm1d(num_channels)
        self.dropout1 = nn.Dropout(p=dropout_prob)

        self.conv2 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=20, padding=9)
        self.bn2 = nn.BatchNorm1d(num_channels)
        self.dropout2 = nn.Dropout(p=dropout_prob)

        # Remaining layers with kernel size 5
        self.conv3 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn3 = nn.BatchNorm1d(num_channels)
        self.dropout3 = nn.Dropout(p=dropout_prob)

        self.conv4 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn4 = nn.BatchNorm1d(num_channels)
        self.dropout4 = nn.Dropout(p=dropout_prob)

        self.conv5 = nn.Conv1d(in_channels=num_channels, out_channels=1, kernel_size=5, padding=2)
        self.bn5 = nn.BatchNorm1d(1)
        self.dropout5 = nn.Dropout(p=dropout_prob)

        # Final linear layer to map to the output size
        self.fc = nn.Linear(194, output_size)

        # Activation function
        self.relu = nn.ReLU()

    def forward(self, x):
        # Assuming input is (batch_size, 1, input_size)
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.dropout1(x)

        x = self.conv2(x)
        x = self.bn2(x)
        x = self.relu(x)
        x = self.dropout2(x)

        x = self.conv3(x)
        x = self.bn3(x)
        x = self.relu(x)
        x = self.dropout3(x)

        x = self.conv4(x)
        x = self.bn4(x)
        x = self.relu(x)
        x = self.dropout4(x)

        x = self.conv5(x)
        x = self.bn5(x)
        x = self.relu(x)
        x = self.dropout5(x)

        # Flatten before feeding into the fully connected layer
        x = x.view(x.size(0), -1)
        x = self.fc(x)

        return x.unsqueeze(1)

class FCNN15(nn.Module):
    def __init__(self, input_size=196, output_size=26, num_channels=50, dropout_prob=0.1):
        super(FCNN15, self).__init__()

        # First two layers with kernel size 20
        self.conv1 = nn.Conv1d(in_channels=1, out_channels=num_channels, kernel_size=20, padding=9)
        self.bn1 = nn.BatchNorm1d(num_channels)
        self.dropout1 = nn.Dropout(p=dropout_prob)

        self.conv2 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=20, padding=9)
        self.bn2 = nn.BatchNorm1d(num_channels)
        self.dropout2 = nn.Dropout(p=dropout_prob)

        # Next three layers with kernel size 5
        self.conv3 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn3 = nn.BatchNorm1d(num_channels)
        self.dropout3 = nn.Dropout(p=dropout_prob)

        self.conv4 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn4 = nn.BatchNorm1d(num_channels)
        self.dropout4 = nn.Dropout(p=dropout_prob)

        self.conv5 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn5 = nn.BatchNorm1d(num_channels)
        self.dropout5 = nn.Dropout(p=dropout_prob)

        # Adding more convolutional layers with kernel size 5
        self.conv6 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn6 = nn.BatchNorm1d(num_channels)
        self.dropout6 = nn.Dropout(p=dropout_prob)

        self.conv7 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn7 = nn.BatchNorm1d(num_channels)
        self.dropout7 = nn.Dropout(p=dropout_prob)

        self.conv8 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn8 = nn.BatchNorm1d(num_channels)
        self.dropout8 = nn.Dropout(p=dropout_prob)

        self.conv9 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn9 = nn.BatchNorm1d(num_channels)
        self.dropout9 = nn.Dropout(p=dropout_prob)

        self.conv10 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn10 = nn.BatchNorm1d(num_channels)
        self.dropout10 = nn.Dropout(p=dropout_prob)

        self.conv11 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn11 = nn.BatchNorm1d(num_channels)
        self.dropout11 = nn.Dropout(p=dropout_prob)

        self.conv12 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn12 = nn.BatchNorm1d(num_channels)
        self.dropout12 = nn.Dropout(p=dropout_prob)

        self.conv13 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn13 = nn.BatchNorm1d(num_channels)
        self.dropout13 = nn.Dropout(p=dropout_prob)

        self.conv14 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn14 = nn.BatchNorm1d(num_channels)
        self.dropout14 = nn.Dropout(p=dropout_prob)

        self.conv15 = nn.Conv1d(in_channels=num_channels, out_channels=num_channels, kernel_size=5, padding=2)
        self.bn15 = nn.BatchNorm1d(num_channels)
        self.dropout15 = nn.Dropout(p=dropout_prob)

        # Final linear layer to map to the output size
        self.fc = nn.Linear(194*num_channels, output_size)

        # Activation function
        self.relu = nn.ReLU()

    def forward(self, x):
        # Assuming input is (batch_size, 1, input_size)
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.dropout1(x)

        x = self.conv2(x)
        x = self.bn2(x)
        x = self.relu(x)
        x = self.dropout2(x)

        x = self.conv3(x)
        x = self.bn3(x)
        x = self.relu(x)
        x = self.dropout3(x)

        x = self.conv4(x)
        x = self.bn4(x)
        x = self.relu(x)
        x = self.dropout4(x)

        x = self.conv5(x)
        x = self.bn5(x)
        x = self.relu(x)
        x = self.dropout5(x)

        x = self.conv6(x)
        x = self.bn6(x)
        x = self.relu(x)
        x = self.dropout6(x)

        x = self.conv7(x)
        x = self.bn7(x)
        x = self.relu(x)
        x = self.dropout7(x)

        x = self.conv8(x)
        x = self.bn8(x)
        x = self.relu(x)
        x = self.dropout8(x)

        x = self.conv9(x)
        x = self.bn9(x)
        x = self.relu(x)
        x = self.dropout9(x)

        x = self.conv10(x)
        x = self.bn10(x)
        x = self.relu(x)
        x = self.dropout10(x)

        x = self.conv11(x)
        x = self.bn11(x)
        x = self.relu(x)
        x = self.dropout11(x)

        x = self.conv12(x)
        x = self.bn12(x)
        x = self.relu(x)
        x = self.dropout12(x)

        x = self.conv13(x)
        x = self.bn13(x)
        x = self.relu(x)
        x = self.dropout13(x)

        x = self.conv14(x)
        x = self.bn14(x)
        x = self.relu(x)
        x = self.dropout14(x)

        x = self.conv15(x)
        x = self.bn15(x)
        x = self.relu(x)
        x = self.dropout15(x)

        # Flatten before feeding into the fully connected layer
        x = x.view(x.size(0), -1)
        x = self.fc(x)

        return x.unsqueeze(1)
