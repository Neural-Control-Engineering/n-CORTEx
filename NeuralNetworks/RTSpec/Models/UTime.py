import torch 
import torch.nn as nn
import torch.nn.functional as F
import math

# Adapting U-time to report spectral parameters
class USpec(nn.Module):
    def __init__(
            self,
            psdXDim=100,
            maxPeaks=8,
            numLayers=4,
            chanStart=8,
            riseFactor=2,
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
            if i == 0:
                ch_in = 1
                ch_out = chanStart
            else:
                ch_in = (chanStart * (riseFactor**(i-1)))
                ch_out = (chanStart * (riseFactor**i))
            kernel_size=5
            stride=1
            padding=0
            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
            conv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            poolSize=2
            poolStride=2
            maxPool = nn.MaxPool1d(poolSize, poolStride)
            self.Convs1_enc.append(conv1)
            self.Convs2_enc.append(conv2)
            self.Norms1_enc.append(norm1)
            self.Norms2_enc.append(norm2)
            self.Maxpools_enc.append(maxPool)
        
        # BOTTLENECK SEQUENCE
        ch_in = chanStart * (riseFactor**(numLayers-1))
        ch_out = chanStart * (riseFactor**(numLayers))
        self.midConv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
        self.midConv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
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
        scaleFactor=2
        for i in range(numLayers):
            ch_in = chanStart * (riseFactor**(numLayers-i))
            ch_out = chanStart * (riseFactor**(numLayers-(i+1)))

            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)
            conv2 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding)
            conv3 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding)
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            norm3 = nn.BatchNorm1d(ch_out)
            upSamp = nn.Upsample(scaleFactor)
            self.Convs1_dec.append(conv1)
            self.Convs2_dec.append(conv2)
            self.Convs3_dec.append(conv3)
            self.Norms1_dec.append(norm1)
            self.Norms2_dec.append(norm2)
            self.Norms3_dec.append(norm3)
            self.UPSamp_dec.append(upSamp)
        
        # PREDICTION BLOCK                
        AvgPoolStride=7        
        outWidth = math.floor(psdXDim / 2**numLayers) * 2**numLayers
        outNodes = maxPeaks*3+2
        AvgPoolSize = outWidth - (outNodes-1)*AvgPoolStride 
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
            x = self.UPSamp_dec[i](x)
            x = self.Convs1_dec[i](x)
            x = self.Norms1_dec[i](x)
            # concatenate with corresponding encoding layer (see above)
            skip = skip_connections[-(i+1)]
            x = torch.cat((x, skip), dim=2)
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