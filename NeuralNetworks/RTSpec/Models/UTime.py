import torch 
import torch.nn as nn
import torch.nn.functional as F
import math
from Models.Transformer import TransformerModel

# Adapting U-time to report spectral parameters
class USpec(nn.Module):
    def __init__(
            self,
            psdXDim=195,
            maxPeaks=8,
            numLayers=4,
            chanStart=64,
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
                padd=0
            else:
                ch_in = (chanStart * (riseFactor**(i-1)))
                ch_out = (chanStart * (riseFactor**i))
                padd='same'
            kernel_size=4
            stride=1
            padding=0
            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding=padd)
            conv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            poolSize=2
            poolStride=2
            maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=False)
            # if math.floor(psdXDim / 2**(i+1)) % 2 == 1:
            #     maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=True)
            # else:
            #     maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=False)

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
        kernel_size=2
        for i in range(numLayers):
            ch_in = chanStart * (riseFactor**(numLayers-i))
            ch_out = chanStart * (riseFactor**(numLayers-(i+1)))

            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
            conv2 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
            conv3 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            norm3 = nn.BatchNorm1d(ch_out)
            upSamp = nn.Upsample(scale_factor=scaleFactor)
            # upSamp = nn.functional.interpolate(scale_factor=scaleFactor)
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
        # outWidth = (psdXDim / 2**numLayers) * 2**numLayers
        outNodes = maxPeaks*3+2
        AvgPoolSize = outWidth - (outNodes-1)*AvgPoolStride         
        self.AvgPool = nn.AvgPool1d(AvgPoolSize, AvgPoolStride)
        self.PredConv = nn.Conv1d(ch_out, 1, kernel_size, stride, padding='same')

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
            # print(x.shape)

        # Botleneck pass
        x = self.midConv1(x)
        x = self.midNorm1(x)
        x = torch.relu(x)
        x = self.midConv2(x)
        x = self.midNorm2(x)
        x = torch.relu(x)    
        # print(x.shape)
        
        # Decoder pass
        for i in range(len(self.Convs1_dec)):
            x = self.UPSamp_dec[i](x)
            # print(x.shape)
            x = self.Convs1_dec[i](x)
            # print(x.shape)
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
            # print(x.shape)

        # Prediction (classifier) pass
        x = self.AvgPool(x)
        x = self.PredConv(x)
        # print(x.shape)
        return x
    
class Specformer(nn.Module):
    def __init__(
            self,
            psdXDim=195,
            maxPeaks=8,
            numLayers=4,
            chanStart=8,
            riseFactor=2,
            dropout_rate=0.2,
    ):
        super(Specformer, self).__init__()

        # ENCODER BLOCK
        # self.Convs1_enc = nn.ModuleList()
        # self.Convs2_enc = nn.ModuleList()
        # self.Norms1_enc = nn.ModuleList()
        # self.Norms2_enc = nn.ModuleList()
        self.ResConvs_enc = nn.ModuleList()
        self.SqEx_enc = nn.ModuleList()
        self.Maxpools_enc = nn.ModuleList()
        self.dropout_enc = nn.ModuleList()
        for i in range(numLayers):
            if i == 0:
                ch_in = 1
                ch_out = chanStart
                padd=0        
                resconv = conv_block(ch_in, ch_out, kernel_size=4, stride=1, dilation=1, padding=padd)        
            else:
                ch_in = (chanStart * (riseFactor**(i-1)))
                ch_out = (chanStart * (riseFactor**i))
                padd='same'
                kernel_size=4
                stride=1
                padding=0
                # conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding=padd)
                # conv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
                # norm1 = nn.BatchNorm1d(ch_out)
                # norm2 = nn.BatchNorm1d(ch_out)
                resconv = resconv_block(ch_in, ch_out, kernel_size, stride, dilation=1, padding=padd)
            sqex = ChannelSELayer1D(ch_out)
            poolSize=2
            poolStride=2
            maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=False)
            # if math.floor(psdXDim / 2**(i+1)) % 2 == 1:
            #     maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=True)
            # else:
            #     maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=False)

            # self.Convs1_enc.append(conv1)
            # self.Convs2_enc.append(conv2)
            # self.Norms1_enc.append(norm1)
            # self.Norms2_enc.append(norm2)
            self.ResConvs_enc.append(resconv)
            self.SqEx_enc.append(sqex)
            self.Maxpools_enc.append(maxPool)
            self.dropout_enc.append(nn.Dropout(dropout_rate))
        
        # BOTTLENECK SEQUENCE
        ch_in = chanStart * (riseFactor**(numLayers-1))
        ch_out = chanStart * (riseFactor**(numLayers))
        self.midConv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
        self.midConv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
        self.midNorm1 = nn.BatchNorm1d(ch_out)
        self.midNorm2 = nn.BatchNorm1d(ch_out)

        # SELF ATTENTION
        self.positionalEncoding = PositionalEncoding(d_model=12, max_len=psdXDim)
        self.attention1 = nn.MultiheadAttention(embed_dim=12, num_heads=6)
        self.attention2 = nn.MultiheadAttention(embed_dim=12, num_heads=6)
        # self.attention3 = nn.MultiheadAttention(embed_dim=12, num_heads=6)
        # self.attention4 = nn.MultiheadAttention(embed_dim=12, num_heads=6)

        self.attention_dropout = nn.Dropout(dropout_rate)

        # DECODER BLOCK
        self.Convs1_dec = nn.ModuleList()
        # self.Convs2_dec = nn.ModuleList()
        # self.Convs3_dec = nn.ModuleList()
        self.ResConvs_dec = nn.ModuleList()
        self.SqEx_dec = nn.ModuleList()
        self.Norms1_dec = nn.ModuleList()
        self.Norms2_dec = nn.ModuleList()
        self.Norms3_dec = nn.ModuleList()
        self.UPSamp_dec = nn.ModuleList()
        scaleFactor=2
        kernel_size=2
        for i in range(numLayers):
            ch_in = chanStart * (riseFactor**(numLayers-i))
            ch_out = chanStart * (riseFactor**(numLayers-(i+1)))

            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, dilation=1, padding='same')
            # conv2 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
            # conv3 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
            resconv = resconv_block(ch_in, ch_out, kernel_size, stride, dilation=1, padding='same')
            sqex = ChannelSELayer1D(ch_out)
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            norm3 = nn.BatchNorm1d(ch_out)
            upSamp = nn.Upsample(scale_factor=scaleFactor)
            # upSamp = nn.functional.interpolate(scale_factor=scaleFactor)
            self.Convs1_dec.append(conv1)
            # self.Convs2_dec.append(conv2)
            # self.Convs3_dec.append(conv3)
            self.ResConvs_dec.append(resconv)
            self.SqEx_dec.append(sqex)  
            self.Norms1_dec.append(norm1)
            self.Norms2_dec.append(norm2)
            self.Norms3_dec.append(norm3)
            self.UPSamp_dec.append(upSamp)
        
        # PREDICTION BLOCK                
        AvgPoolStride=7        
        outWidth = math.floor(psdXDim / 2**numLayers) * 2**numLayers
        # outWidth = (psdXDim / 2**numLayers) * 2**numLayers
        outNodes = maxPeaks*3+2
        AvgPoolSize = outWidth - (outNodes-1)*AvgPoolStride         
        self.AvgPool = nn.AvgPool1d(AvgPoolSize, AvgPoolStride)
        self.PredConv = nn.Conv1d(ch_out, 1, kernel_size, stride, padding='same')

    def forward(self, x):
        # accumulate inputs for skip connections during forward pass
        skip_connections = []
        # Encoder pass
        # for i in range(len(self.Convs1_enc)): 
        for i in range(len(self.ResConvs_enc)): 
            # x_res = x            
            # x = self.Convs1_enc[i](x)
            # x = self.Norms1_enc[i](x)            
            # x = torch.relu(x)
            # x = x+x_res
            # x_res = x
            # x = self.Convs2_enc[i](x)
            # x = self.Norms2_enc[i](x)
            # x = torch.relu(x)
            # x = x+x_res
            x = self.ResConvs_enc[i](x)
            x = self.SqEx_enc[i](x)
            # store layer-processed output for concatenation with corresponding decoding layer
            skip_connections.append(x)
            x = self.Maxpools_enc[i](x)
            x = self.dropout_enc[i](x)
            # print(x.shape)                   

        # Botleneck pass
        x = self.midConv1(x)
        x = self.midNorm1(x)
        x = torch.relu(x)
        x = self.midConv2(x)
        x = self.midNorm2(x)
        x = torch.relu(x)    
        # Transformer pass
        # print(x[0].shape)
        x = x.view(x.size(0), x.size(1), x.size(2))
        # print(x[0].shape)
        x = self.positionalEncoding(x)
        x = x + self.attention1(x, x, x)[0]        
        x = x + self.attention2(x, x, x)[0]
        # x = x + self.attention3(x, x, x)[0]
        # x = x + self.attention4(x, x, x)[0]
        x = self.attention_dropout(x)
        # print(x[0].shape)
        x = x + self.positionalEncoding(x)  # Add residual connection
        # print(x[0].shape)
        
        # Decoder pass
        for i in range(len(self.Convs1_dec)):
            x = self.UPSamp_dec[i](x)
            # print(x.shape)
            x = self.Convs1_dec[i](x)
            # print(x.shape)
            x = self.Norms1_dec[i](x)
            # concatenate with corresponding encoding layer (see above)
            skip = skip_connections[-(i+1)]
            x = torch.cat((x, skip), dim=1)
            # x = self.Convs2_dec[i](x)
            # x = self.Norms2_dec[i](x)
            # x = torch.relu(x)
            # x = self.Convs3_dec[i](x)
            # x = self.Norms3_dec[i](x)
            # x = torch.relu(x)
            x = self.ResConvs_dec[i](x)
            x = self.SqEx_dec[i](x)
            # print(x.shape)

        # Prediction (classifier) pass
        x = self.AvgPool(x)
        x = self.PredConv(x)
        # print(x.shape)
        return x
    
class Specformer2(nn.Module):
    def __init__(
            self,
            psdXDim=195,
            maxPeaks=8,
            numLayers=3,
            chanStart=20,
            riseFactor=2,
            dropout_rate=0.1,
    ):
        super(Specformer2, self).__init__()

        # ENCODER BLOCK
        # self.Convs1_enc = nn.ModuleList()
        # self.Convs2_enc = nn.ModuleList()
        # self.Norms1_enc = nn.ModuleList()
        # self.Norms2_enc = nn.ModuleList()
        self.ResConvs1_enc = nn.ModuleList()
        self.ResConvs2_enc = nn.ModuleList()
        self.SqEx_enc = nn.ModuleList()
        self.Maxpools_enc = nn.ModuleList()
        self.dropout_enc = nn.ModuleList()
        for i in range(numLayers):
            if i == 0:
                ch_in = 1
                ch_out = chanStart
                padd=0        
                resconv1 = conv_block(ch_in, ch_out, kernel_size=4, stride=1, dilation=1, padding=padd)        
                resconv2 = conv_block(ch_out, ch_out, kernel_size=4, stride=1, dilation=1, padding="same")        
            else:
                ch_in = (chanStart * (riseFactor**(i-1)))
                ch_out = (chanStart * (riseFactor**i))
                padd='same'
                kernel_size=20//(i//2+1)
                stride=1
                padding=0
                # conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding=padd)
                # conv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
                # norm1 = nn.BatchNorm1d(ch_out)
                # norm2 = nn.BatchNorm1d(ch_out)
                resconv1 = resconv_block(ch_in, ch_out, kernel_size, stride, dilation=1, padding=padd)
                resconv2 = resconv_block(ch_out, ch_out, kernel_size, stride, dilation=1, padding=padd)
            sqex = ChannelSELayer1D(ch_out)
            poolSize=2
            poolStride=2
            maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=False)
            # if math.floor(psdXDim / 2**(i+1)) % 2 == 1:
            #     maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=True)
            # else:
            #     maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=False)

            # self.Convs1_enc.append(conv1)
            # self.Convs2_enc.append(conv2)
            # self.Norms1_enc.append(norm1)
            # self.Norms2_enc.append(norm2)
            self.ResConvs1_enc.append(resconv1)
            self.ResConvs2_enc.append(resconv2)
            self.SqEx_enc.append(sqex)
            self.Maxpools_enc.append(maxPool)
            self.dropout_enc.append(nn.Dropout(dropout_rate))
        
        # BOTTLENECK SEQUENCE
        ch_in = chanStart * (riseFactor**(numLayers-1))
        ch_out = chanStart * (riseFactor**(numLayers))
        self.midConv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
        self.midConv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
        self.midNorm1 = nn.BatchNorm1d(ch_out)
        self.midNorm2 = nn.BatchNorm1d(ch_out)

        # SELF ATTENTION
        self.positionalEncoding = PositionalEncoding(d_model=24, max_len=psdXDim)
        self.attention1 = nn.MultiheadAttention(embed_dim=24, num_heads=6)
        self.attention2 = nn.MultiheadAttention(embed_dim=24, num_heads=6)
        # self.attention3 = nn.MultiheadAttention(embed_dim=12, num_heads=6)
        # self.attention4 = nn.MultiheadAttention(embed_dim=12, num_heads=6)

        self.attention_dropout = nn.Dropout(dropout_rate)

        # DECODER BLOCK
        self.Convs1_dec = nn.ModuleList()
        # self.Convs2_dec = nn.ModuleList()
        # self.Convs3_dec = nn.ModuleList()
        self.ResConvs1_dec = nn.ModuleList()
        self.ResConvs2_dec = nn.ModuleList()
        self.SqEx_dec = nn.ModuleList()
        self.Norms1_dec = nn.ModuleList()
        self.Norms2_dec = nn.ModuleList()
        self.Norms3_dec = nn.ModuleList()
        self.UPSamp_dec = nn.ModuleList()
        scaleFactor=2
        kernel_size=20//(i//2+1)
        for i in range(numLayers):
            ch_in = chanStart * (riseFactor**(numLayers-i))
            ch_out = chanStart * (riseFactor**(numLayers-(i+1)))

            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, dilation=1, padding='same')
            # conv2 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
            # conv3 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
            resconv1 = resconv_block(ch_in, ch_out, kernel_size, stride, dilation=1, padding='same')
            resconv2 = resconv_block(ch_out, ch_out, kernel_size, stride, dilation=1, padding='same')
            sqex = ChannelSELayer1D(ch_out)
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            norm3 = nn.BatchNorm1d(ch_out)
            upSamp = nn.Upsample(scale_factor=scaleFactor)
            # upSamp = nn.functional.interpolate(scale_factor=scaleFactor)
            self.Convs1_dec.append(conv1)
            # self.Convs2_dec.append(conv2)
            # self.Convs3_dec.append(conv3)
            self.ResConvs1_dec.append(resconv1)
            self.ResConvs2_dec.append(resconv2)
            self.SqEx_dec.append(sqex)  
            self.Norms1_dec.append(norm1)
            self.Norms2_dec.append(norm2)
            self.Norms3_dec.append(norm3)
            self.UPSamp_dec.append(upSamp)
        
        # PREDICTION BLOCK                
        AvgPoolStride=7        
        outWidth = math.floor(psdXDim / 2**numLayers) * 2**numLayers
        # outWidth = (psdXDim / 2**numLayers) * 2**numLayers
        outNodes = maxPeaks*3+2
        AvgPoolSize = outWidth - (outNodes-1)*AvgPoolStride         
        self.AvgPool = nn.AvgPool1d(AvgPoolSize, AvgPoolStride)
        self.PredConv = nn.Conv1d(ch_out, 1, kernel_size, stride, padding='same')

    def forward(self, x):
        # accumulate inputs for skip connections during forward pass
        skip_connections = []
        # Encoder pass
        # for i in range(len(self.Convs1_enc)): 
        for i in range(len(self.ResConvs1_enc)): 
            # x_res = x            
            # x = self.Convs1_enc[i](x)
            # x = self.Norms1_enc[i](x)            
            # x = torch.relu(x)
            # x = x+x_res
            # x_res = x
            # x = self.Convs2_enc[i](x)
            # x = self.Norms2_enc[i](x)
            # x = torch.relu(x)
            # x = x+x_res
            x = self.ResConvs1_enc[i](x)
            x = self.ResConvs2_enc[i](x)
            x = self.SqEx_enc[i](x)
            # store layer-processed output for concatenation with corresponding decoding layer
            skip_connections.append(x)
            x = self.Maxpools_enc[i](x)
            x = self.dropout_enc[i](x)
            print(x.shape)                   

        # Botleneck pass
        x = self.midConv1(x)
        x = self.midNorm1(x)
        x = torch.relu(x)
        x = self.midConv2(x)
        x = self.midNorm2(x)
        x = torch.relu(x)    
        # Transformer pass
        # print(x[0].shape)
        x = x.view(x.size(0), x.size(1), x.size(2))
        # print(x[0].shape)
        x = self.positionalEncoding(x)
        x = x + self.attention1(x, x, x)[0]        
        x = x + self.attention2(x, x, x)[0]
        # x = x + self.attention3(x, x, x)[0]
        # x = x + self.attention4(x, x, x)[0]
        x = self.attention_dropout(x)
        # print(x[0].shape)
        x = x + self.positionalEncoding(x)  # Add residual connection
        # print(x[0].shape)
        
        # Decoder pass
        for i in range(len(self.Convs1_dec)):
            x = self.UPSamp_dec[i](x)
            # print(x.shape)
            x = self.Convs1_dec[i](x)
            # print(x.shape)
            x = self.Norms1_dec[i](x)
            # concatenate with corresponding encoding layer (see above)
            skip = skip_connections[-(i+1)]
            x = torch.cat((x, skip), dim=1)
            # x = self.Convs2_dec[i](x)
            # x = self.Norms2_dec[i](x)
            # x = torch.relu(x)
            # x = self.Convs3_dec[i](x)
            # x = self.Norms3_dec[i](x)
            # x = torch.relu(x)
            x = self.ResConvs1_dec[i](x)
            # print("res1:",x.shape)
            x = self.ResConvs2_dec[i](x)
            # print("res2:",x.shape)
            x = self.SqEx_dec[i](x)
            # print(x.shape)

        # Prediction (classifier) pass
        x = self.AvgPool(x)
        x = self.PredConv(x)
        # print(x.shape)
        return x

class Specformer3(nn.Module):
    def __init__(
            self,
            psdXDim=195,
            maxPeaks=8,
            numLayers=1,
            chanStart=16,
            riseFactor=2,
            dropout_rate=0.1,
    ):
        super(Specformer3, self).__init__()       
        self.ResConvs1_enc = nn.ModuleList()
        self.ResConvs2_enc = nn.ModuleList()
        self.SqEx_enc = nn.ModuleList()
        self.Maxpools_enc = nn.ModuleList()
        self.dropout_enc = nn.ModuleList()
        for i in range(numLayers):
            if i == 0:
                ch_in = 1
                ch_out = chanStart
                padd=0        
                resconv1 = conv_block(ch_in, ch_out, kernel_size=4, stride=1, dilation=1, padding=padd)        
                resconv2 = conv_block(ch_out, ch_out, kernel_size=20, stride=1, dilation=1, padding="same")        
            else:
                ch_in = (chanStart * (riseFactor**(i-1)))
                ch_out = (chanStart * (riseFactor**i))
                padd='same'
                kernel_size=20//(i//2+1)
                stride=1
                padding=0             
                resconv1 = resconv_block(ch_in, ch_out, kernel_size, stride, dilation=1, padding=padd)
                resconv2 = resconv_block(ch_out, ch_out, kernel_size, stride, dilation=1, padding=padd)
            sqex = ChannelSELayer1D(ch_out)
            poolSize=2
            poolStride=2
            maxPool = nn.MaxPool1d(poolSize, poolStride, ceil_mode=False)          
            self.ResConvs1_enc.append(resconv1)
            self.ResConvs2_enc.append(resconv2)
            self.SqEx_enc.append(sqex)
            self.Maxpools_enc.append(maxPool)
            self.dropout_enc.append(nn.Dropout(dropout_rate))
        
        # BOTTLENECK SEQUENCE
        kernel_size=20//(i//2+1)
        stride=1
        ch_in = chanStart * (riseFactor**(numLayers-1))
        ch_out = chanStart * (riseFactor**(numLayers))
        self.midConv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding='same')
        self.midConv2 = nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same')
        self.midNorm1 = nn.BatchNorm1d(ch_out)
        self.midNorm2 = nn.BatchNorm1d(ch_out)

        # SELF ATTENTION
        self.positionalEncoding = PositionalEncoding(d_model=32, max_len=5000)
        self.transformer = TransformerModel(dim=32, depth=12, heads=8, mlp_dim=32*4, dropout_rate=0.1, attn_dropout_rate=0.1)

        # DECODER BLOCK
        self.Convs1_dec = nn.ModuleList()
        # self.Convs2_dec = nn.ModuleList()
        # self.Convs3_dec = nn.ModuleList()
        self.ResConvs1_dec = nn.ModuleList()
        self.ResConvs2_dec = nn.ModuleList()
        self.SqEx_dec = nn.ModuleList()
        self.Norms1_dec = nn.ModuleList()
        self.Norms2_dec = nn.ModuleList()
        self.Norms3_dec = nn.ModuleList()
        self.UPSamp_dec = nn.ModuleList()
        scaleFactor=2
        kernel_size=20//(i//2+1)
        for i in range(numLayers):
            ch_in = chanStart * (riseFactor**(numLayers-i))
            ch_out = chanStart * (riseFactor**(numLayers-(i+1)))

            conv1 = nn.Conv1d(ch_in, ch_out, kernel_size, stride, dilation=1, padding='same')          
            resconv1 = resconv_block(ch_in, ch_out, kernel_size, stride, dilation=1, padding='same')
            resconv2 = resconv_block(ch_out, ch_out, kernel_size, stride, dilation=1, padding='same')
            sqex = ChannelSELayer1D(ch_out)
            norm1 = nn.BatchNorm1d(ch_out)
            norm2 = nn.BatchNorm1d(ch_out)
            norm3 = nn.BatchNorm1d(ch_out)
            upSamp = nn.Upsample(scale_factor=scaleFactor)
            # upSamp = nn.functional.interpolate(scale_factor=scaleFactor)
            self.Convs1_dec.append(conv1)
            # self.Convs2_dec.append(conv2)
            # self.Convs3_dec.append(conv3)
            self.ResConvs1_dec.append(resconv1)
            self.ResConvs2_dec.append(resconv2)
            self.SqEx_dec.append(sqex)  
            self.Norms1_dec.append(norm1)
            self.Norms2_dec.append(norm2)
            self.Norms3_dec.append(norm3)
            self.UPSamp_dec.append(upSamp)
        
        # PREDICTION BLOCK (MLP)      
        outWidth = math.floor(psdXDim / 2**numLayers) * 2**numLayers        
        outNodes = maxPeaks*3+2
        # AvgPoolSize = outWidth - (outNodes-1)*AvgPoolStride         
        # self.AvgPool = nn.AvgPool1d(AvgPoolSize, AvgPoolStride)
        self.PredConv = nn.Conv1d(ch_out, 1, kernel_size, stride, padding='same')
        self.PredMLP1 = nn.Linear(192, 96)        
        self.PredMLP2 = nn.Linear(96, outNodes)


    def forward(self, x):
        # accumulate inputs for skip connections during forward pass
        skip_connections = []
        # Encoder pass
        # for i in range(len(self.Convs1_enc)): 
        for i in range(len(self.ResConvs1_enc)):            
            x = self.ResConvs1_enc[i](x)
            x = self.ResConvs2_enc[i](x)
            x = self.SqEx_enc[i](x)
            # store layer-processed output for concatenation with corresponding decoding layer
            skip_connections.append(x)
            x = self.Maxpools_enc[i](x)
            x = self.dropout_enc[i](x)
            print(x.shape)                   

        # Botleneck pass
        x = self.midConv1(x)
        x = self.midNorm1(x)
        x = torch.relu(x)
        x = self.midConv2(x)
        x = self.midNorm2(x)
        x = torch.relu(x)           
        x = x.permute(0, 2, 1)
        x = self.positionalEncoding(x)        
        x = self.transformer(x)[0]        
        # print(x[0].shape)        
        print(x.shape)
        x = x.permute(0, 2, 1)
        print(x.shape)
        
        # Decoder pass
        for i in range(len(self.Convs1_dec)):
            x = self.UPSamp_dec[i](x)
            # print(x.shape)
            x = self.Convs1_dec[i](x)
            # print(x.shape)
            x = self.Norms1_dec[i](x)
            # concatenate with corresponding encoding layer (see above)
            skip = skip_connections[-(i+1)]
            x = torch.cat((x, skip), dim=1)         
            x = self.ResConvs1_dec[i](x)
            # print("res1:",x.shape)
            x = self.ResConvs2_dec[i](x)
            # print("res2:",x.shape)
            x = self.SqEx_dec[i](x)
            print(x.shape)

        # Prediction (classifier) pass        
        x = self.PredConv(x)
        print(x.shape)
        x = self.PredMLP1(x)           
        print(x.shape)
        x = self.PredMLP2(x)
        print(x.shape)
        # print(x.unsqueeze(1).shape)
        return x
    
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super(PositionalEncoding, self).__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-math.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0).transpose(0, 1)
        self.register_buffer('pe', pe)

    def forward(self, x):
        return x + self.pe[:x.size(0), :]


class resconv_block(nn.Module):
    def __init__(self, ch_in, ch_out, kernel_size, stride, padding, dilation):
        super(resconv_block, self).__init__()
        self.conv = nn.Sequential(
            nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding, dilation=dilation, bias = True),
            nn.BatchNorm1d(ch_out),
            nn.ReLU(inplace = True),
            nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same', dilation=dilation, bias = True),
            nn.BatchNorm1d(ch_out),
            nn.ReLU(inplace = True)
        )
        self.Conv_1x1 = nn.Conv1d(ch_in, ch_out, kernel_size = 1, stride = 1, padding=padding)

    def forward(self,x):

        residual = self.Conv_1x1(x)
        x = self.conv(x)
        return residual + x
    
class conv_block(nn.Module):
    def __init__(self, ch_in, ch_out, kernel_size, stride, padding, dilation):
        super(conv_block, self).__init__()
        self.conv = nn.Sequential(
            nn.Conv1d(ch_in, ch_out, kernel_size, stride, padding, dilation=dilation, bias = True),
            nn.BatchNorm1d(ch_out),
            nn.ReLU(inplace = True),
            nn.Conv1d(ch_out, ch_out, kernel_size, stride, padding='same', dilation=dilation, bias = True),
            nn.BatchNorm1d(ch_out),
            nn.ReLU(inplace = True)
        )        

    def forward(self,x):
        
        x = self.conv(x)
        return x

class ChannelSELayer1D(nn.Module):
    """
    1D extension of Squeeze-and-Excitation (SE) block described in:
        *Hu et al., Squeeze-and-Excitation Networks, arXiv:1709.01507*
        *Zhu et al., AnatomyNet, arXiv:arXiv:1808.05238*
    """

    def __init__(self, num_channels, reduction_ratio=8):
        """
        :param num_channels: No of input channels
        :param reduction_ratio: By how much should the num_channels should be reduced
        """
        super(ChannelSELayer1D, self).__init__()
        self.avg_pool = nn.AdaptiveAvgPool1d(1)
        num_channels_reduced = num_channels // reduction_ratio
        self.reduction_ratio = reduction_ratio
        self.fc1 = nn.Linear(num_channels, num_channels_reduced, bias=True)
        self.fc2 = nn.Linear(num_channels_reduced, num_channels, bias=True)
        self.relu = nn.ReLU()
        self.sigmoid = nn.Sigmoid()

    def forward(self, input_tensor):
        """
        :param input_tensor: X, shape = (batch_size, num_channels, W)
        :return: output tensor
        """
        batch_size, num_channels, W = input_tensor.size()
        # Average along each channel
        squeeze_tensor = self.avg_pool(input_tensor)

        # channel excitation
        fc_out_1 = self.relu(self.fc1(squeeze_tensor.view(batch_size, num_channels)))
        fc_out_2 = self.sigmoid(self.fc2(fc_out_1))

        output_tensor = torch.mul(input_tensor, fc_out_2.view(batch_size, num_channels, 1))

        return output_tensor
    
    