import torch
import torch.nn as nn
from Models.IntmdSequential import IntermediateSequential

class Electroformer(nn.Module):
  def __init__(
      self,
      numChannels = 385,
      numSamples = 5500,
      embedDim_s = 96,
      embedDim_t = 60,      
               ):
    super(Electroformer,self).__init__()
    # BUILD SPATIAL PATH
    ## CNN MODULE
    self.Conv1_s = nn.Conv1d(in_channels=numChannels, out_channels=numChannels, kernel_size=17, stride=1, padding="same") # 385 --> 385
    self.AvgPool1_s = nn.AvgPool1d(kernel_size=5,stride=5) # 5500 --> 1100
    self.Conv2_s = nn.Conv1d(in_channels=numChannels,out_channels=numChannels//7,kernel_size=15,stride=1,padding="same") # 385 --> 55
    self.AvgPool2_s = nn.AvgPool1d(kernel_size=10,stride=10) # 1100 --> 110
    self.Conv3_s = nn.Conv1d(in_channels=numChannels//7,out_channels=numChannels//7,kernel_size=15,stride=1) # 110 --> 96; 55 --> 55
    self.grp_norm_s = nn.GroupNorm(numChannels//(77),numChannels//7) # 5 groups of 11 channels
    ## TRANSFORMER MODULE
    # self.PosEnc1_s = PositionalEncoder(embedding_dim=numSamples//10,max_length=numChannels)
    # self.Transf1_s = EncoderTransformer(inSize=numSamples//10,outSize=4,numLayers=10,hiddenSize=1,numHeads=6,dropout=0.01)
    self.PosEnc1_s = PositionalEncoder(embedding_dim=embedDim_s,max_length=numChannels//7)
    self.Transf1_s = EncoderTransformer(inSize=96,outSize=5,numLayers=10,hiddenSize=1,numHeads=8,dropout=0.01)

    # BUILD TEMPORAL PATH
    # CNN MODULE
    self.Conv1_t = nn.Conv1d(in_channels=numSamples,out_channels=numSamples//5, kernel_size=numChannels//55, stride=1, padding="same") # 5500 --> 1100    
    self.AvgPool1_t = nn.AvgPool1d(kernel_size=5,stride=5) # 385 --> 77
    self.Conv2_t = nn.Conv1d(in_channels=numSamples//5,out_channels=numSamples//50, kernel_size=7, stride=2, padding=24) # 1100 --> 110; 77 --> 60
    # TRANSFORMER MODULE    
    self.PosEnc1_t = PositionalEncoder(embedding_dim=embedDim_t,max_length=numSamples)
    self.Transf1_t = EncoderTransformer(inSize=60,outSize=5,numLayers=10,hiddenSize=1,numHeads=6,dropout=0.01)

    # Build Fully Connected Path
    inSize_fc1 = (numChannels // 7) * 5 + (numSamples // 50) * 5 # 275 + 550 = 825
    self.fc1 = nn.Linear(inSize_fc1,125)
    self.fc2 = nn.Linear(125,4)

  def forward(self, x):
    # Spatial Pass
    x_s = self.Conv1_s(x)
#     print('x_s conv1: ',x_s.shape)
    x_s = self.AvgPool1_s(x_s)
#     print('x_s avg1: ',x_s.shape)
    x_s = self.Conv2_s(x_s)
#     print('x_s conv21: ',x_s.shape)
    x_s = self.AvgPool2_s(x_s)
#     print('x_s avg2: ',x_s.shape)
    x_s = self.Conv3_s(x_s)
    x_s = self.grp_norm_s(x_s)
    x_s = x_s.permute(0,2,1)
    x_s = self.PosEnc1_s(x_s)
    x_s = self.Transf1_s(x_s)
#     print('x_s tf1: ',x_s.shape)
    
    # Temporal Pass
    x_t = self.Conv1_t(x)
#     print('x_t conv1: ',x_t.shape)
    x_t = self.AvgPool1_t(x_t)
#     print('x_t avg1: ',x_t.shape)
    x_t = self.Conv2_t(x_t)
#     print('x_t conv2: ',x_t.shape)    
    # x_t = x_t.permute(0,2,1) # transpose to present time wise vectors to transformer encoder    
    x_t = self.PosEnc1_t(x_t)
    x_t = self.Transf1_t(x_t)
#     print('x_t tf1: ',x_t.shape)
    # Concatenation
    # x_s = x_s.permute(0,2,1)
    # x_t = x_t.permute(0,2,1)
    x_cat = torch.cat((x_s, x_t),dim=2)
    x_view = x_cat.view(x_cat.size(0),-1)
#     print('x_cat: ',x_cat.shape)
    # Output Pass: Fully Connected into Softmax
    x = self.fc1(x_view)
    x = torch.log_softmax(x,dim=1)
    return x


class EncoderTransformer(nn.Module):
  def __init__(self, inSize, outSize, numLayers=3, hiddenSize=1, numHeads=8, dropout=0.01):
    super(EncoderTransformer,self).__init__()
    self.encoderLayer = nn.TransformerEncoderLayer(d_model=inSize, nhead=numHeads, dim_feedforward=hiddenSize, dropout=dropout)
    self.encoder = nn.TransformerEncoder(self.encoderLayer,num_layers=numLayers)
    self.fc1 = nn.Linear(inSize, outSize)
  def forward(self, x):
    x = self.encoder(x)
    x = self.fc1(x)
    return x

## CHECK HERE !
class PositionalEncoder(nn.Module):
  def __init__(self, embedding_dim, max_length=1000):
    super(PositionalEncoder,self).__init__()
    pe = torch.zeros(max_length, embedding_dim)
    position = torch.arange(0, max_length,dtype=float).unsqueeze(1)
    div_term = torch.exp(
        torch.arange(0, embedding_dim, 2).float()
        * (-torch.log(torch.tensor(10000.0))/embedding_dim)
    )
    pe[:,0::2] = torch.sin(position * div_term)
    pe[:,1::2] = torch.cos(position * div_term)
    pe.unsqueeze(0).transpose(0,1)
    self.register_buffer('pe',pe)

  def forward(self, x):
    #print(self.pe[:x.size(1)].shape)
    return x + self.pe[:x.size(1),:]

