import sys
import os
import json
from simple_pyspin import Camera, list_cameras
# from PIL import Image
import cv2
import signal
import numpy as np
import socket
import multiprocessing
from multiprocessing import Process, Queue, Value, Event
from multiprocessing.shared_memory import SharedMemory
from multiprocessing.sharedctypes import RawArray, RawValue, Array
import PySpin
import struct
# import queue

# MINI LIBRARY BUILT FROM SPINVIEW API (SPINNAKER SDK) TO CONFIGURE AND START A SPINVIEW ACQUISITION

BUFFERSIZE=1000
COMPRESSIONLEVEL=1

def main():
    # Check if the required argument is provided
    if len(sys.argv) != 2:
        print("Usage: python script.py <spinParams_json>")
        sys.exit(1)
    print("STARTING")
    spinParams = sys.argv[1] 
    # spinParams="{\"saveDir\": \"Select Project Directory\", \"pupilCam\": {\"TriggerMode\": \"On\"}, \"whiskCam\": {\"TriggerMode\": \"On\"}, \"execStatus\": \"start\"}"
    spinParams = json.loads(spinParams)     

    # retrieve video save location
    # saveDir = spinParams["saveDir"]
    # sessionLabel = spinParams["sessionLabel"]
    execStatus = spinParams["execStatus"]
    # camSelect = spinParams["camSelect"]    
    
    # SN registry
    # pupilSN=spinParams["pupilSN"]
    # whiskSN=spinParams["whiskSN"]
    SN = spinParams['SN']
    # SN_char = Char(SN)
    listenerPort = int(SN[-6:-1])
    print(type(SN))
    # listenerPort = SN % 100000
    print('listenerPort: ',listenerPort)

    if execStatus=="start":                
        # frameBuffer=multiprocessing.Manager().list()
        frameBuffer = Queue(maxsize=BUFFERSIZE)                
        isTerm = Value('i', 0)  # Shared variable to signal termination
        print('frameBuffer initiated')
        print('Rx Value initiated')

        cameras = list_cameras()
        numCameras = cameras.GetSize()
        if numCameras < 1:
            print("Error: no cameras connected.")
            return
        
        print(str(numCameras) + ' camera(s) found')
        print((SN,': selected'))            

        cam = Camera(SN)
        cam.init()
        camParams = spinParams['spinParams']
        cam = setSpinParams(cam, spinParams['spinParams'])
        
        # listenerPort = int(SN(-6:-1)) # last 5 digits of SN 
        acqDir = spinParams['saveDir']
        print(acqDir)                        
        
        # Init directory to store frames
        if not os.path.exists(acqDir):
            os.mkdir(acqDir)        

        # Start concurrent frame saving process
        print('starting acquisition')        
        print('starting saving thread')
        # saveProc = Process(target=saveFrames,args=(frameBuffer,acqDir,isTerm))
        width_frame = camParams['Width']
        height_frame = camParams['Height']
        frameSize = width_frame * height_frame
        # shared_buffer = [RawArray('H', cam.get_array().size) for _ in range(BUFFERSIZE)]  # Create a shared memory buffer        
        shared_buffer = [RawArray('B', frameSize) for _ in range(BUFFERSIZE)]  # Create a shared memory buffer        
        idxs_frame = Queue()
        idxs_empty = Queue()
        for i in range(BUFFERSIZE):
            idxs_empty.put(i)  # Fill the empty index queue with indices

        # idx = idxs_empty.get()  # Get an index for the first frame
        # frame = cam.get_array()  # Get the first frame to determine its shape
        # shape = frame.shape  # Get the shape of the frame
        # np.copyto(np.frombuffer(shared_buffer[idx], dtype=np.uint16).reshape(shape), frame)  # Initialize the shared buffer with the first frame        
        # idxs_frame.put(idx)  # Mark the index as used

        # Begin Acquisition
        cam.start() 
        frame = cam.get_array()  # Get the first frame to determine its shape
        shape = frame.shape  # Get the shape of the frame        
        
        frame_ready = Event()  # Event to signal when a new frame is ready
        # start consumer process
        saveProc = Process(target=consumeSharedFrame_contig,args=(shared_buffer, frame_ready, idxs_frame, idxs_empty, shape, acqDir,isTerm))
        print('starting listening thread')        
        listenForTermProc = Process(target=termListener,args=(isTerm,listenerPort))
        saveProc.start()
        listenForTermProc.start() # start a socket listener for end of program signal
        
        print('FPS: ',cam.AcquisitionResultingFrameRate)      
        # i=0
        try:
            while isTerm.value == 0:
                frame = cam.get_array() 
                # print("shape1: ",frame.shape)
                # frameBuffer.put(frame)
                # storeSharedFrame(shared_buffer, frame, frame_ready, shape)  # Store the frame in shared memory                
                storeSharedFrame(shared_buffer, frame, frame_ready, idxs_frame, idxs_empty, shape)

        except Exception as e:
            print("Error during acquisition:", e)

        finally:
            cam.stop()
            cam.close()
            # isTerm.value = 1  # signals the saving process to exit
            # saveProc.join()
            # termProc.terminate()
            # termProc.join()
            print("Acquisition finished.")

    elif execStatus=="stop":
        # Send termination signals to whisker and pupil acquisition ports
        # listenerPort = int(SN(-6:-1))
        clientSocket1 = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # pupilAcq socket
        # clientSocket2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # whiskerAcq socket
        clientSocket1.connect(('localhost',listenerPort))      
        # clientSocket2.connect(('localhost',23456))
        msgOut = 'terminateAcq'        
        clientSocket1.send(msgOut.encode())
        # clientSocket2.send(msgOut.encode())
        print("resetting equipment")
        clientSocket1.close()
        # clientSocket2.close()
        #resetCameras(pupilSN, whiskSN)
        resetCamera(SN)
    else:
        raise Exception("Missing ExecStatus!")  

def setSpinParams(camera, stgsDict):
    """
    Configure camera parameters based on a dictionary of settings.

    Parameters:
    - camera: PySpin camera instance
    - camDict: Dictionary containing camera parameter settings
    """    
    for key, value in stgsDict.items():
        if value=='false':
            value=False
        elif value=='true':
            value=True
        print('key: '+str(key))
        print('value: '+str(value))
        setattr(camera, key, value)
        print('set '+str(key)+' to '+str(value))

    return camera

def storeSharedFrame(shared_buffer, frame, frame_ready, idxs_frame, idxs_empty, shape):
    # Store a frame in shared memory for inter-process communication.
    idx = idxs_empty.get()  # Get an index for the current frame    
    arr = np.frombuffer(shared_buffer[idx], dtype=np.uint8).reshape(shape)
    np.copyto(arr, frame)  # Copy the frame data into the shared memory array
    print("frame stored")
    frame_ready.set()  # Signal that a new frame is ready    
    idxs_frame.put(idx)  # Mark the index as empty for future use    

def consumeSharedFrame(shared_buffer, frame_ready, idxs_frame, idxs_empty, shape, acqDir, isTerm):
    # Consume a frame from shared memory.
    # arr = np.frombuffer(shared_buffer, dtype=np.uint16).reshape(shape)
    i=0
    while True:
        if isTerm.value == 1:
            print('saving isTerm: ', str(isTerm.value))
            break        

        frame_ready.wait()  # Wait for a new frame to be ready
        frame_ready.clear()  # Clear the event for the next frame

        # if arr.size == 0:
        #     print("No data in shared memory.")
        #     continue
        
        # Copy the shared memory data to a local variable
        # This is necessary because the shared memory array may be modified by other processes.
        # frame = arr.copy()  # Copy the shared memory data to a local variable        
        
        idx = idxs_frame.get()  # Get the index of the frame to process      
        frame = np.frombuffer(shared_buffer[idx], dtype=np.uint8).reshape(shape)  # Reshape the shared memory data to the original frame shape
        # print("shape: ",shape)
        idxs_empty.put(idx)  # Mark the index as used          

        # Save the frame to a file
        # size control
        if frame.ndim == 2:
            height, width = frame.shape
            channels = 1
        elif frame.ndim == 3:
            height, width, channels = frame.shape
        else:
            raise ValueError("Unsupported frame dimensions.")        
        
        fname = f"{acqDir}/{i:010d}.bin"

        with open(fname, "wb") as f:
            f.write(struct.pack("<III", height, width, channels))
            f.write(frame.tobytes())  # raw pixel data

        i += 1
        print(f"frame {i} (height:{height}, width:{width}, channels:{channels}) saved to {fname}")

def consumeSharedFrame_contig(shared_buffer, frame_ready, idxs_frame, idxs_empty, shape, acqDir, isTerm):
    # Prepare output binary file
    os.makedirs(acqDir, exist_ok=True)
    bin_path = os.path.join(acqDir, "frames.bin")
    meta_path = os.path.join(acqDir, "metadata_frames.txt")  # Stores shape info for MATLAB or Python

    with open(bin_path, "ab") as f_out:
        i = 0
        while True:
            if isTerm.value == 1:
                print('saving isTerm: ', str(isTerm.value))
                break        

            frame_ready.wait()
            frame_ready.clear()

            idx = idxs_frame.get()
            frame = np.frombuffer(shared_buffer[idx], dtype=np.uint8).reshape(shape)
            idxs_empty.put(idx)

            if frame.ndim == 2:
                height, width = frame.shape
                channels = 1
            elif frame.ndim == 3:
                height, width, channels = frame.shape
            else:
                raise ValueError("Unsupported frame dimensions.")        

            # Write frame header + data (little endian)
            # f_out.write(struct.pack("<III", height, width, channels))  # 3x uint32 header
            f_out.write(frame.tobytes())

            i += 1
            print(f"Appended frame {i} (H:{height}, W:{width}, C:{channels}) to {bin_path}")

    # Save metadata
    with open(meta_path, "w") as meta:
        meta.write(f"{i} {height} {width} {channels} uint8\n")  # Total frames and format info
        

def saveFrames(frameBuffer, acqDir, isTerm):
    """
    Saves raw frames in .bin format with a small header.

    Header (in first 12 bytes) consists of:
    - width (uint32, 4 bytes),
    - height (uint32, 4 bytes),
    - channels (uint32, 4 bytes).

    The rest is raw pixel data in row-major format.

    """
    i = 0
    basePath = os.path.join(acqDir, "{:06d}.bin")
    while True:
        if isTerm.value == 1:
            print('saving isTerm: ', str(isTerm.value))
            break
        if not frameBuffer.empty():
        # if len(frameBuffer) > 0:
            frame = frameBuffer.get()
            height, width = frame.shape[0], frame.shape[1]
            channels = 1 if frame.ndim == 2 else frame.shape[2]
    
            fname = basePath.format(i)
    
            with open(fname, "wb") as f:
                # First write a small header with dimensions and channels.
                # We'll use 4-byte ints in little-endian format.
                f.write(struct.pack("<III", height, width, channels))
                f.write(frame.tobytes())  # Then write the raw pixel data
                i += 1
                print(f"frame {i} (height:{height}, width:{width}, channels:{channels}) saved to {fname}")


def termListener(isTerm, portNum):
    serverSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serverSocket.bind(('localhost',portNum))
    serverSocket.listen(1)
    print("Waiting for a connection...")
    clientSocket, clientAddress = serverSocket.accept()
    # receive client data in a loop
    print("port: ",portNum)
    while True:
        msgIn = clientSocket.recv(1024)
        msgIn = msgIn.decode()
        print("Received:",str(msgIn))
        if msgIn == 'terminateAcq':            
            isTerm.value=1        
            print("terminating...")
            # respond to client
            # msgOut = "termReceived"
            # clientSocket.send(msgOut.encode())
            clientSocket.close()
            serverSocket.close()
            break

# def resetCameras(pupilSN, whiskSN):
#     wskCam = Camera(pupilSN)
#     pupCam = Camera(whiskSN)
#     wskCam.init()
#     pupCam.init()
#     wskCam.DeviceReset()
#     pupCam.DeviceReset()

def resetCamera(SN):
    cam = Camera(SN)
    cam.init()
    cam.DeviceReset()


if __name__ == "__main__":
    main()