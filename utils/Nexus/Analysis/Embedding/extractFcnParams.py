import re

class nexParams(dict):
    """Dictionary subclass to store function parameters with default values."""
    pass

def extractFcnParams(fcnHandle):
    """
    Extracts parameters from a function file, following the 'CFG HEADER' convention.
    
    Args:
        fcnHandle (str): Name of the function file (without '.py' extension).
        
    Returns:
        nexParams: Dictionary-like object containing extracted parameter names and their default values.
    """
    fcnHandle = fcnHandle.__name__
    try:
        # Read the function file
        with open(fcnHandle + ".py", "r", encoding="utf-8") as f:
            txt = f.read()
    except FileNotFoundError:
        raise FileNotFoundError(f"File {fcnHandle}.py not found!")

    # Regular expression to find the CFG HEADER block
    cfg_expr = r'(?<=# CFG HEADER\n)((?:\s*[\w\d_]+\s*=\s*args\["[\w\d_]+"\]\s*#\s*default\s*=\s*[^\n]+\n)+)'
    cfg_match = re.search(cfg_expr, txt, re.MULTILINE)

    # Initialize dictionary for extracted variables
    cfgVars = nexParams()

    if cfg_match:
        cfg_block = cfg_match.group(1)  # Extract matched block

        # Regular expression to extract variable name and default value
        var_expr = r'^\s*([\w\d_]+)\s*=\s*args\["([\w\d_]*)"\]\s*#\s*default\s*=\s*(.+)'
        matches = re.findall(var_expr, cfg_block, re.MULTILINE)

        # Store results in dictionary
        for varName, _, defaultValue in matches:
            defaultValue = defaultValue.strip()  # Remove unnecessary spaces

            # Try converting to a number (int or float)
            try:
                num_value = int(defaultValue) if "." not in defaultValue else float(defaultValue)
                cfgVars[varName] = num_value
            except ValueError:
                # Ensure the extracted string **retains** both leading and trailing quotes
                if defaultValue.startswith(("'", '"')) and defaultValue.endswith(("'", '"')):
                    cfgVars[varName] = defaultValue  # Preserve quotes
                else:
                    cfgVars[varName] = f'"{defaultValue}"'  # Re-add quotes if missing

    return cfgVars
