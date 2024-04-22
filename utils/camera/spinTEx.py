import sys
import os
import json
from simple_pyspin import Camera, list_cameras
from PIL import Image
import cv2
import signal
import socket
import multiprocessing
from multiprocessing import Process

# MINI LIBRARY BUILT FROM SPINVIEW API (SPINNAKER SDK) TO CONFIGURE AND START A SPINVIEW ACQUISITION

BUFFERSIZE=1000
COMPRESSIONLEVEL=1

def main():
    # Check if the required argument is provided
    if len(sys.argv) != 2:
        print("Usage: python script.py <spinParams_json>")
        sys.exit(1)

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
        frameBuffer=multiprocessing.Manager().list()
        isTerm=multiprocessing.Manager().Value('i',0)
        print('frameBuffer initiated')
        print('Rx Value initiated')

        cameras = list_cameras()
        numCameras = cameras.GetSize()
        print(str(numCameras) + ' camera(s) found')

        print((SN,': selected'))            
        cam = Camera(SN)
        cam.init()
        cam = setSpinParams(cam, spinParams['spinParams'])
        # listenerPort = int(SN(-6:-1)) # last 5 digits of SN 
        acqDir = spinParams['saveDir']
       
        # if camSelect==pupilSN:
        #     cam = Camera(pupilSN)
        #     # temporary: reset camera on startup
        #     # setattr(cam,'DeviceReset',1)
        #     print('Pupil Cam Selected')
        #     cam.init()
        #     cam = setSpinParams(cam, spinParams['pupilCam']) # find and store pupil camera
        #     rawPupilFldr = os.path.join(saveDir,"Raw Pupil Data")
        #     if not os.path.exists(rawPupilFldr):
        #         os.mkdir(rawPupilFldr)
        #     acqDir = os.path.join(rawPupilFldr, sessionLabel)
        #     listenerPort=12345
        #     # isKillVar='ISPUPKILL'            
           
        # elif camSelect==whiskSN:
        #     cam = Camera(whiskSN)
        #     # temporary: reset camera on startup
        #     # setattr(cam,'DeviceReset',1)
        #     print('Whisker Cam Selected')
        #     cam.init()
        #     cam = setSpinParams(cam, spinParams['whiskCam'])
        #     rawWhiskFldr = os.path.join(saveDir,"Raw Whisker Data")
        #     if not os.path.exists(rawWhiskFldr):
        #         os.mkdir(rawWhiskFldr)
        #     acqDir = os.path.join(rawWhiskFldr, sessionLabel)
        #     listenerPort=23456
        #     # isKillVar='ISWSKKILL'
        
        # else      
            
           
        # os.environ[isKillVar]='0' # init to 0 and check if set to 1
        
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
        while True: # continue triggered acquisition until 'stop' is called        
            # print('camStarted')
            frame = cam.get_array()
            print('frame acquired')
            frameBuffer.append(frame)
            print('BUFFERLEN: ', len(frameBuffer))

            if len(frameBuffer)>BUFFERSIZE:
                while len(frameBuffer)>BUFFERSIZE:
                    frameBuffer.pop(0)

            
            if isTerm.value==1:
                print('acquisition isTerm: ',str(isTerm.value))
                print("Acquisition Complete, releasing resources")
                cam.stop()
                cam.close()                                
                break           

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
    i=0
    while True:
        if len(frameBuffer)>0:
            frame = frameBuffer.pop(0)
            cv2.imwrite(os.path.join(acqDir, "frame_"+str(i)+".png"), frame, [cv2.IMWRITE_PNG_COMPRESSION, COMPRESSIONLEVEL])
            # cv2.imwrite(os.path.join(acqDir, "frame_"+str(i)+".png"), frame)
            i+=1 
            print('frame_',i,' saved')
            print('BUFFERLEN: ', len(frameBuffer))            
        
        if isTerm.value==1:
            print('saving isTerm: ',str(isTerm.value))
            break
    

def termListener(isTerm, portNum):
    serverSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serverSocket.bind(('localhost',portNum))
    serverSocket.listen(1)
    print("Waiting for a connection...")
    clientSocket, clientAddress = serverSocket.accept()
    # receive client data in a loop
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