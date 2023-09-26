import sys
import os
import json
from simple_pyspin import Camera, list_cameras
from PIL import Image
import cv2

# MINI LIBRARY BUILT FROM SPINVIEW API (SPINNAKER SDK) TO CONFIGURE AND START A SPINVIEW ACQUISITION

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
    # retrieve videoWriter params
    # pupilCv2 = spinParams["pupilCv2"]
    # whiskCv2 = spinParams["whiskCv2"]
    # pupFps = pupilCv2["fps"]
    # pupFrameW = pupilCv2["frameSizeW"]
    # pupFrameH = pupilCv2["frameSizeH"]
    # wskFps = whiskCv2["fps"]
    # wskFrameW = whiskCv2["frameSizeW"]
    # wskFrameH = whiskCv2["frameSizeH"]    
    
    # SN registry
    pupilSN = '19133897'
    wskSN='23248866'

    if execStatus=="start":

        # Store the PID in an environment variable
        os.environ["startPID"] = str(os.getpid())

        cameras = list_cameras()
        numCameras = cameras.GetSize()
        print(str(numCameras) + ' camera(s) found')

        # Find pupil and whisker cameras if connected
        for i in range(numCameras):
            cam = Camera(i)
            # cam.init()
            # serialNum = cam.get_info('DeviceSerialNumber')['value']
            # print('SN'+str(i)+': '+str(serialNum))
            if camSelect==0:
                print('Pupil Cam Selected')
                cam.init()
                cam = setSpinParams(cam, spinParams['pupilCam']) # find and store pupil camera
                acqDir = os.path.join(saveDir,"Raw Pupil Data")
            elif camSelect==1:
                print('Whisker Cam Selected')
                cam.init()
                cam = setSpinParams(cam, spinParams['whiskCam'])
                acqDir = os.path.join(saveDir,"Raw Whisker Data")
        
        if not os.path.exists(acqDir):
            os.mkdir(acqDir)        

        print('starting acquisition')

        # open Video Writers       
        cam.start()       
        i=0
        while True: # continue triggered acquisition until 'stop' is called        
            # print('camStarted')
            frame = cam.get_array()
            Image.fromarray(frame).save(os.path.join(acqDir,"frame_"+str(i)+".png"))            
            i+=1        

    elif execStatus=="stop":
        PID = os.environ.get("startPID")                         
        os.kill(PID)        

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


if __name__ == "__main__":
    main()