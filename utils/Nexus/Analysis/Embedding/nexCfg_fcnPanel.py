from PyQt5.QtWidgets import QWidget, QVBoxLayout, QLabel, QLineEdit, QSpinBox, QComboBox
from functools import partial

def nexCfg_fcnPanel(nexObj, groupLayout, entryParams, entryChangedFcnHandle):
    """
    Creates UI entry fields in a PyQt layout based on the given entryParams dictionary.

    Args:
        nexObj: An object that holds necessary settings or color configurations.
        groupLayout: The layout to which the generated UI elements will be added.
        entryParams: Dictionary containing key-value pairs of parameter names and their values.
        fcnHandle: A function that will be called when an entry field value changes.
    """
    for key, value in entryParams.items():
        # Add label
        label = QLabel(key)
        groupLayout.addWidget(label)

        # Determine input field type based on value type
        if isinstance(value, (int, float)):  # Numeric input
            widget = QSpinBox() if isinstance(value, int) else QLineEdit()
            widget.setText(str(value)) if isinstance(value, float) else widget.setValue(value)
        elif isinstance(value, str):  # Text input
            widget = QLineEdit()
            widget.setText(value)
        elif isinstance(value, list) and all(isinstance(i, str) for i in value):  # Dropdown for string list
            widget = QComboBox()
            widget.addItems(value)
            widget.setCurrentText(value[0])
        else:
            continue  # Skip unsupported types

        # Connect signal to fcnHandle
        if isinstance(widget, (QLineEdit, QComboBox)):
            widget.textChanged.connect(partial(entryChangedFcnHandle, entryParams, key))
        elif isinstance(widget, QSpinBox):
            widget.valueChanged.connect(partial(entryChangedFcnHandle, entryParams, key))

        groupLayout.addWidget(widget)