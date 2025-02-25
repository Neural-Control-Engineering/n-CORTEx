import time
import numpy as np
import torch

import matplotlib.pyplot as plt

def benchmarkLatency(model, num_channels_list, num_iterations=100):
    # Load the model
    # model = torch.load(modelPath)    

    results = {}

    for num_channels in num_channels_list:
        latencies = []

        # Generate random input data
        input_data = torch.randn(num_channels, 1, 196).cuda()  # Adjust dimensions as needed

        for _ in range(num_iterations):
            start_time = time.time()
            with torch.no_grad():
                _ = model(input_data)
            end_time = time.time()

            latencies.append(end_time - start_time)

        avg_latency = np.mean(latencies)
        sem_latency = np.std(latencies) / np.sqrt(num_iterations)

        results[num_channels] = {
            'average_latency': avg_latency,
            'sem_latency': sem_latency
        }

    # Plotting the results
    channels = list(results.keys())
    avg_latencies = [results[ch]['average_latency'] for ch in channels]
    sem_latencies = [results[ch]['sem_latency'] for ch in channels]

    plt.figure(figsize=(10, 6), facecolor='#98b69e')
    plt.gca().set_facecolor('#98b69e')
    plt.errorbar(channels, avg_latencies, yerr=sem_latencies, fmt='-o', capsize=5, label='Average Latency', color='#00240d', ecolor='#00240d')
    plt.xlabel('Number of Channels', color='#00240d', fontsize=16)
    plt.ylabel('Latency (seconds)', color='#00240d', fontsize=16)
    plt.title('Model Latency vs Number of Channels', color='#00240d', fontsize=20)
    plt.legend(facecolor='#98b69e', edgecolor='#00240d', labelcolor='#00240d', fontsize=14)
    plt.grid(False)  # Make gridlines invisible
    plt.gca().spines['bottom'].set_color('#00240d')
    plt.gca().spines['top'].set_color('#00240d') 
    plt.gca().spines['right'].set_color('#00240d')
    plt.gca().spines['left'].set_color('#00240d')
    plt.gca().tick_params(axis='x', colors='#00240d', labelsize=14)
    plt.gca().tick_params(axis='y', colors='#00240d', labelsize=14)
    plt.gca().title.set_color('#00240d')
    plt.gca().xaxis.label.set_color('#00240d')
    plt.gca().yaxis.label.set_color('#00240d')
    plt.gcf().patch.set_facecolor('#98b69e')
    plt.show()

    return results

# Example usage
# modelPath = '/path/to/your/model.pth'
# num_channels_list = [1, 2, 4, 8, 16, 32, 64, 128, 256, 384]
# results = benchmarkLatency(modelPath, num_channels_list)
# print(results)