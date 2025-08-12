import sys
import os
import pandas as pd
import numpy as np
import pdb
from PyQt6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QSlider, QLineEdit, QLabel, QGroupBox, QListWidget
from PyQt6.QtWebEngineWidgets import QWebEngineView
import plotly.graph_objs as go
from matplotlib.figure import Figure
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
# from nex_addpath import nex_addpath
# nex_addpath("/home/user/Code_Repo/n-CORTEx/utils/Nexus")
from nexVisualization_embedding import nexVisualization_embedding
from nexCompute_embedding import nexCompute_embedding
from breakoutFcnFields import breakoutFcnFields
from extractFcnParams import extractFcnParams
from nexCfg_fcnPanel import nexCfg_fcnPanel
from embedPCA import embedPCA
from extractFcnParams import nexParams
from functools import partial
from collections import defaultdict
import csv

class nexFigure_embedding(QMainWindow):
    def __init__(self, params):
        super().__init__()

        # PROPERTY DEFAULTS
        self.params = params
        self.Parents = type('', (), {})()
        self.Partners = type('', (), {})()
        self.Children = type('', (), {})()
        self.DF = type('', (), {})()
        self.DF_out = type('', (), {})()
        self.dfID = "rtPMTM_magnitude_temporal"
        self.classID = "emb"
        self.UserData = type('', (), {})()
        self.opCfg = {}
        self.opCfg["fcn"] = globals()["embedPCA"]
        self.opCfg["entryParams"] = extractFcnParams(self.opCfg["fcn"])
        self.compCfg = type('', (), {})()
        self.visCfg = {}
        self.visCfg["fcn"] = globals()["nexVisualization_embedding"]
        self.visCfg["entryParams"] = extractFcnParams(self.visCfg["fcn"])
        self.selCfg = {}
        self.selCfg["entryParams"] = nexParams({})
        
        self.setWindowTitle("Nexus: Interactive Embedding")
        self.setGeometry(100, 100, 800, 500)  # (x, y, width, height)

        # Create main widget and layout
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        self.main_layout = QHBoxLayout(main_widget)  # Horizontal layout (Plot + Side Panel)

        # 🎨 Left: Matplotlib Figure (Interactive)
        # self.figure = Figure()
        # self.canvas = FigureCanvas(self.figure)
        # self.ax = self.figure.add_subplot(111)        

        # FIGURE PANEL
        self.embFigure = {}  # Creates an empty dynamic object   
        self.embFigure["panel1"] = {}
        self.embFigure["panel1"]["wv"] = QWebEngineView()
        self.embFigure["panel1"]["fh"] = self.empty_scatter()        

        # CONTROL PANEL
        self.embFigure["panel2"] = {}
        self.embFigure["panel2"]["gb"] = QGroupBox("Controls")                  
        self.embFigure["panel2"]["gl"] = QVBoxLayout()     
        self.embFigure["panel2"]["opIdEntry"] = QLineEdit("embedPCA")
        self.embFigure["panel2"]["opIdEntry"].textChanged.connect(self.opIdChanged)
        self.embFigure["panel2"]["gl"].addWidget(self.embFigure["panel2"]["opIdEntry"])        
        self.embFigure["panel2"]["routerPanel"] = {}
        self.embFigure["panel2"]["routerPanel"]["dfIdEntry"] = QLineEdit("rtPMTM_magnitude_temporal") # enter ID of selected dataset                
        self.embFigure["panel2"]["routerPanel"]["dfIdEntry"].textChanged.connect(self.dfIdChanged)
        self.embFigure["panel2"]["gl"].addWidget(self.embFigure["panel2"]["routerPanel"]["dfIdEntry"])        
        self.embFigure["panel2"]["compPanel"] = nexCfg_fcnPanel(self, self.embFigure["panel2"]["gl"], self.opCfg["entryParams"], self.compCfgEntryChanged)        
        self.embFigure["panel2"]["visPanel"] = nexCfg_fcnPanel(self, self.embFigure["panel2"]["gl"], self.visCfg["entryParams"], self.visCfgEntryChanged)
        self.embFigure["panel2"]["gb"].setLayout(self.embFigure["panel2"]["gl"])               

        # Add elements to main layout
        # main_layout.addWidget(self.canvas, 70)  # 70% width for plot
        self.main_layout.addWidget(self.embFigure["panel1"]["wv"],70)
        # main_layout.addWidget(self.ui_panel, 30)  # 30% width for controls        
        self.main_layout.addWidget(self.embFigure["panel2"]["gb"], 30)

    def empty_scatter(self):
        trace = go.Scatter3d(
            x=[],  # Empty data for now
            y=[],  # Empty data for now
            z=[],  # Empty data for now
            mode='markers',
            marker=dict(
                size=5,
                color=[],  # Empty color data for now
                colorscale='Viridis',
                opacity=0.8
            )
        )
        layout = go.Layout(
            scene=dict(
                xaxis_title='X',
                yaxis_title='Y',
                zaxis_title='Z'
            ),
            title="Interactive 3D Scatter Plot"
        )
        return go.Figure(data=[trace], layout=layout)
    
    def opIdChanged(self, opId):
        pass

    def dfIdChanged(self, dfId):
        self.reroute()        

    def load(self):
        # load dataset given params
        pass

    def visualize(self):
        visArgs = self.visCfg["entryParams"]
        nexVisualization_embedding(self, visArgs)
    
    def visCfgEntryChanged(self, entryParams, k, v):
        entryParams[k] = v
        self.visualize()

    def compCfgEntryChanged(self, entryParams, k, v):
        entryParams[k] = v
        self.update()

    def compute(self):
        opArgs = self.opCfg["entryParams"]
        opArgs["rowSel"] = self.compCfg["entryParams"]["rowSel"]
        nexCompute_embedding(self, opArgs)

    def update(self):
        self.compute()
        self.visualize()

    def reroute(self):
        dataPath = os.path.join(params["paths"]["Data"]["FTR"]["local"],"TRAIN",self.dfID)
        # load new dataset (from current dfID)
        X_import_path = os.path.join(dataPath, "X.csv")
        Y_import_path = os.path.join(dataPath, "Y.csv")
        # self.DF["X"] = pd.read_csv(X_import_path, header=None)

        # Read the CSV file manually using the csv module
        with open(X_import_path, 'r') as f:
            reader = csv.reader(f)
            rows = [row for row in reader]

        # Determine the maximum row length
        max_length = max(len(row) for row in rows)

        # Pad rows that are shorter with None (or NaN)
        for row in rows:
            row.extend([None] * (max_length - len(row)))

        # Now create a DataFrame from the padded rows
        self.DF["X"] = pd.DataFrame(rows)

        self.DF["Y"] = pd.read_csv(Y_import_path, header=None)
        # insert label masks (all unique vals in each y col)
        self.selCfg["entryParams"] = nexParams({}) # reinit before next load
        layout = QVBoxLayout()
        # Loop through each column in Y        
        for i in range(self.DF["Y"].shape[1]):
            unique_values = np.unique(self.DF["Y"][1:, i])  # Get unique values in the column
            labelKey = self.DF["Y"][0,i]
            self.selCfg["entryParams"][labelKey] = {}
            list_widget = QListWidget()  # Create QListWidget
            list_widget.addItems(map(str, unique_values))  # Add unique values as items
            list_widget.currentItemChanged.connect(partial(self.subSelectionChanged,labelKey))  # Connect signal
            
            layout.addWidget(list_widget)  # Add to layout

        # self.compCfg["entryParams"]["selection"] = 
        # insert new layout into control panel
        self.main_layout.insertLayout(1,layout)
        # update figure
        self.update()

def subSelectionChanged(self, key, v):
    """
    Slot to handle selection changes in the list widgets.
    It updates the entryParams with the new selection for the given key.
    """
    # Get all selected items in the list widget (assuming 'v' is the list widget)
    # selected_items = v.selectedItems()  # Get all selected items
    selected_items = v
    
    # Convert selected item text to the appropriate type (e.g., int)
    selected_values = [float(item.text()) for item in selected_items]  # Convert to list of ints
    
    # Update the selection for the given label key with the list of selected values
    self.selCfg["entryParams"][key] = selected_values  # Store the list of selected values
    
    # After updating the selection, prepare the new selection vector (or update any other necessary data)
    self.updateSelectionVector()

def updateSelectionVector(self):
    """
    Update the selection vector by finding the intersection of selections
    across all label keys in self.selCfg.
    """
    selected_rows = None  # Initialize the selected rows as None to start with
    for labelKey, selected_value in self.selCfg["entryParams"].items():
        # Find rows where the value of the current labelKey matches the selection
        matching_rows = self.DF["Y"][self.DF["Y"][labelKey] == selected_value].index
        
        # If this is the first labelKey, initialize selected_rows with the matching rows
        if selected_rows is None:
            selected_rows = matching_rows
        else:
            # Otherwise, intersect the matching rows with the current selection
            selected_rows = selected_rows.intersection(matching_rows)

    # selected_rows now contains the rows that match all selected labels
    self.compCfg["entryParams"]["rowSel"] = selected_rows
    # self.update()  # Refresh/update based on the new selection vector


# Run the application
if __name__ == "__main__":
    app = QApplication([])    
    # Create a defaultdict where each level initializes another defaultdict
    params = defaultdict(lambda: defaultdict(lambda: defaultdict(dict)))
    params["paths"]["Data"]["FTR"]["local"]="/media/user/Expansion/nCORTEx_local/Project_Neuromodulation-For-Pain/Experiments/JOLT/Data/FTR/"
    window = nexFigure_embedding(params)
    window.show()
    sys.exit(app.exec_())

    # app = QApplication(sys.argv)
    # label = QLabel("Hello, PyQt5!")
    # label.show()
    # # sys.exit(app.exec_())
