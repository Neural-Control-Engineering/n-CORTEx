def nexVisualization_embedding(nexObj, args):

    # CFG HEADER
    dimSel_start = args["dimSel_start"] # default = 0
    dimSel_end = args["dimSel_end"] # default = 2
    labelSel = args["labelSel"] # default = "phase"    

    x_data = nexObj.DF_postOp["df"][0]
    y_data = nexObj.DF_postOp["df"][1]
    z_data = nexObj.DF_postOp["df"][2]
    Y = nexObj.DF_postOp["Y"]

    labelSelIdx = (nexObj.DF["Y"][0,:]==labelSel).index
    
    if z_data is None:
        nexObj.embFigure["panel1"]["fh"].data[0].x = x_data
        nexObj.embFigure["panel1"]["fh"].data[0].y = y_data
        nexObj.embFigure["panel1"]["fh"].data[0].marker.color = Y[labelSelIdx]
    else:
        nexObj.embFigure["panel1"]["fh"].data[0].x = x_data
        nexObj.embFigure["panel1"]["fh"].data[0].y = y_data
        nexObj.embFigure["panel1"]["fh"].data[0].z = z_data
        nexObj.embFigure["panel1"]["fh"].data[0].marker.color = Y[labelSelIdx]

    # nexObj.embFigure["panel1"]["fh"].update_layout(title="Updated Scatter Plot")
    nexObj.embFigure["panel1"]["fh"].to_html(full_html=False)  # Convert figure to HTML for embedding
    nexObj.embFigure["panel1"]["wv"].setHtml(nexObj.embFigure["panel1"]["fh"])
