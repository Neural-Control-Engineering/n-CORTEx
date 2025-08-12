import torch
import LSTM

class RTSpec:
    def __init__(self, params, modelPath):
        self.params = params
        self.modelPath = modelPath
        self.model = None
        self.loadModel()
    
    def loadModel(self):        
        modelState = torch.load(self.modelPath, map_location=torch.device('cuda'))
        modelType = modelState['modelType']
        # model = biLSTM50()
        module = __import__('LSTM', fromlist=[modelType])
        model_class = getattr(module, modelType)
        model = model_class()
        model.load_state_dict(modelState['state_dict'])
        model.cuda()
        model.eval()
        self.model = model
    
    def fit(self, psd):
        # self.model.fit(X, y, epochs=self.params['epochs'], batch_size=self.params['batch_size'])
        specs = self.model(psd)
        return specs
