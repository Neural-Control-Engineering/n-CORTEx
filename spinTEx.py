import sys
import os
import json
from simple_pyspin import Camera, list_cameras
from PIL import Image
import cv2
import signal
import multiprocessing
from multiprocessing import Process

# MINI LIBRARY BUILT FROM SPINVIEW API (SPINNAKER SDK) TO CONFIGURE AND START A SPINVIEW ACQUISITION

BUFFERSIZE=1000
COMPRESSIONLEVEL=6

def main():
    # Check if the required argument is provided
    if len(sys.argv) != 2:
        print("Usage: python script.py <spinParams_json>")
        sys.exit(1)

    spinParams = sys.argv[1] 
    # spinParams="{\"saveDir\": \"Select Project Directory\", \"pupilCam\": {\"TriggerMode\": \"On\"}, \"whiskCam\": {\"TriggerMode\": \"On\"}, \"execStatus\": \"start\"}"
    spinParams = json.loads(spinParams)     

    # retrieve video save location
    saveDir = spinParams["saveDir"]
    execStatus = spinParams["execStatus"]
    camSelect = spinParams["camSelect"]    
    
    # SN registry
    pupilSN=spinParams["pupilSN"]
    whiskSN=spinParams["whiskSN"]

    if execStatus=="start":                
        frameBuffer=multiprocessing.Manager().list()
        print('frameBuffer initiated')

        cameras = list_cameras()
        numCameras = cameras.GetSize()
        print(str(numCameras) + ' camera(s) found')
       
        if camSelect==pupilSN:
            cam = Camera(pupilSN)
            # temporary: reset camera on startup
            setattr(cam,'DeviceReset',1)
            print('Pupil Cam Selected')
            cam.init()
            cam = setSpinParams(cam, spinParams['pupilCam']) # find and store pupil camera
            acqDir = os.path.join(saveDir,"Raw Pupil Data")
            isKillVar='ISPUPKILL'            
           
        elif camSelect==whiskSN:
            cam = Camera(whiskSN)
            # temporary: reset camera on startup
            setattr(cam,'DeviceReset',1)
            print('Whisker Cam Selected')
            cam.init()
            cam = setSpinParams(cam, spinParams['whiskCam'])
            acqDir = os.path.join(saveDir,"Raw Whisker Data")
            isKillVar='ISWSKKILL'
           
        os.environ[isKillVar]='0' # init to 0 and check if set to 1
        
        # Init directory to store frames
        if not os.path.exists(acqDir):
            os.mkdir(acqDir)        

        # Start concurrent frame saving process
        print('starting acquisition')
        endEvent=multiprocessing.Event()
        print('starting saving thread')
        saveProc = Process(target=saveFrames,args=(frameBuffer,acqDir, endEvent))        
        saveProc.start()
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

            if os.environ.get(isKillVar)=='1':
                cam.stop()
                endEvent.set()
                print("Acquisition Complete, releasing resources")
                break           

    elif execStatus=="stop":
        os.environ['ISPUPKILL']='1'
        os.environ['ISWSKKILL']='1'        
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
        print('key: '+str(key))
        print('value: '+str(value))
        setattr(camera, key, value)
        print('set '+str(key)+' to '+str(value))

    return camera

def saveFrames(frameBuffer, acqDir, endEvent):
    i=0
    while True:
        if len(frameBuffer)>0:
            frame = frameBuffer.pop(0)
            cv2.imwrite(os.path.join(acqDir, "frame_"+str(i)+".png"), frame, [cv2.IMWRITE_PNG_COMPRESSION, COMPRESSIONLEVEL])
            i+=1 
            print('frame_',i,' saved')
            print('BUFFERLEN: ', len(frameBuffer))
        elif endEvent.is_set():
            break


if __name__ == "__main__":
    main()