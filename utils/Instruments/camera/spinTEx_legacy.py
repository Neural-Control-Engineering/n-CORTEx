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
from multiprocessing import Process, Queue, Value
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
        saveProc = Process(target=saveFrames,args=(frameBuffer,acqDir,isTerm))
        print('starting listening thread')        
        listenForTermProc = Process(target=termListener,args=(isTerm,listenerPort))
        saveProc.start()
        listenForTermProc.start() # start a socket listener for end of program signal
        # Begin Acquisition
        cam.start() 
        print('FPS: ',cam.AcquisitionResultingFrameRate)      
        # i=0
        try:
            while isTerm.value == 0:
                frame = cam.get_array() 
                frameBuffer.put(frame)
                # print(frame)
                # if frame is None:
                # # if len(frameBuffer) < BUFFERSIZE:
                #     frameBuffer.append(frame)
                #     print(f"Buffered {len(frameBuffer)}")
                # else:
                #     #frameBuffer.pop(0)  # discard oldest if buffer is full
                #     frame = frameBuffer.get()
                #     frameBuffer.append(frame)

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