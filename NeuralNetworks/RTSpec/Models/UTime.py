import torch 
import torch.nn as nn
import torch.nn.functional as F

# Adapting U-time to report spectral parameters
class USpec(nn.Module):
    def __init__(
            self,
            psdXDim=100,
            maxPeaks=10,
            numLayers=3,
            dropout_rate=0.1,
    ):
        super(USpec, self).__init__()

        # ENCODER BLOCK
        self.Convs1_enc = nn.ModuleList()
        self.Convs2_enc = nn.ModuleList()
        self.Norms1_enc = nn.ModuleList()
        self.Norms2_enc = nn.ModuleList()
        self.Maxpools_enc = nn.ModuleList()
        for i in range(numLayers):
            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)
            conv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding)
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            maxPool = nn.MaxPool1d(poolSize, poolStride)
            self.Convs1_enc.append(conv1)
            self.Convs2_enc.append(conv2)
            self.Norms1_enc.append(norm1)
            self.Norms2_enc.append(norm2)
            self.Maxpools_enc.append(maxPool)
        
        # BOTTLENECK SEQUENCE
        self.midConv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)
        self.midConv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)
        self.midNorm1 = nn.BatchNorm1d(ch_out)
        self.midNorm2 = nn.BatchNorm1d(ch_out)

        # DECODER BLOCK
        self.Convs1_dec = nn.ModuleList()
        self.Convs2_dec = nn.ModuleList()
        self.Convs3_dec = nn.ModuleList()
        self.Norms1_dec = nn.ModuleList()
        self.Norms2_dec = nn.ModuleList()
        self.Norms3_dec = nn.ModuleList()
        self.UPSamp_dec = nn.ModuleList()
        for i in range(numLayers):
            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)
            conv2 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)
            conv3 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            norm3 = nn.BatchNorm1d(ch_out)
            upSamp = nn.Upsample(scaleFactor)
            self.Convs1_dec.append(conv1)
            self.Convs1_dec.append(conv2)
            self.Convs1_dec.append(conv3)
            self.Norms_dec.append(norm1)
            self.Norms_dec.append(norm2)
            self.Norms_dec.append(norm3)
            self.UPSampe_dec.append(upSamp)
        
        # PREDICTION BLOCK
        self.AvgPool = nn.AvgPool1d(AvgPoolSize, AvgPoolStride)
        self.PredConv = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)

    def forward(self, x):
        # accumulate inputs for skip connections during forward pass
        skip_connections = []
        # Encoder pass
        for i in range(len(self.Convs1_enc)):            
            x = self.Convs1_enc[i](x)
            x = self.Norms1_enc[i](x)
            x = torch.relu(x)
            x = self.Convs2_enc[i](x)
            x = self.Norms2_enc[i](x)
            x = torch.relu(x)
            # store layer-processed output for concatenation with corresponding decoding layer
            skip_connections.append(x)
            x = self.Maxpools_enc[i](x)

        # Botleneck pass
        x = self.midConv1(x)
        x = self.midNorm1(x)
        x = torch.relu(x)
        x = self.midConv2(x)
        x = self.midNorm2(x)
        x = torch.relu(x)    
        
        # Decoder pass
        for i in range(len(self.Convs1_dec)):
            x = self.UPsamp_dec[i](x)
            x = self.Convs1_dec[i](x)
            x = self.Norms1_dec[i](x)
            # concatenate with corresponding encoding layer (see above)
            skip = skip_connections[-(i+1)]
            x = torch.cat((x, skip), dim=1)
            x = self.Convs2_dec[i](x)
            x = self.Norms2_dec[i](x)
            x = torch.relu(x)
            x = self.Convs3_dec[i](x)
            x = self.Norms3_dec[i](x)
            x = torch.relu(x)

        # Prediction (classifier) pass
        x = self.AvgPool(x)
        x = self.PredConv(x)
        return x