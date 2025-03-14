import plotly.graph_objs as go

def update3DScatter(DF, labelSel):

    x_data = DF["df"][0]
    y_data = DF["df"][1]
    z_data = DF["df"][2]
    Y = DF["Y"]
    labelSelIdx = (DF["Y"].iloc[0,:]==labelSel).index

    trace = go.Scatter3d(
        x=x_data,  # Empty data for now
        y=y_data,  # Empty data for now
        z=z_data,  # Empty data for now
        mode='markers',
        marker=dict(
            size=5,
            color=Y[1:,labelSelIdx],  # Empty color data for now
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
    # Create the figure and return it
    figure = go.Figure(data=[trace], layout=layout)

    # Plot the figure in the shell
    figure.show()  # This will render the plot interactively

    return figure