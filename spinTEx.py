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
    # retrieve videoWriter params
    pupilCv2 = spinParams["pupilCv2"]
    whiskCv2 = spinParams["whiskCv2"]
    pupFps = pupilCv2["fps"]
    pupFrameW = pupilCv2["frameSizeW"]
    pupFrameH = pupilCv2["frameSizeH"]
    wskFps = whiskCv2["fps"]
    wskFrameW = whiskCv2["frameSizeW"]
    wskFrameH = whiskCv2["frameSizeH"]    
    
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
            cam.init()
            serialNum = cam.get_info('DeviceSerialNumber')['value']
            print('SN'+str(i)+': '+str(serialNum))
            if serialNum==pupilSN:
                pupCam = cam # find and store pupil camera
            elif serialNum==wskSN:
                wskCam = cam     
               
        # print(pupCam.get_info('TriggerMode'))
        # pupCam.TriggerMode='Off'
        # print(pupCam.get_info('TriggerMode'))
        # setattr(pupCam, 'TriggerMode','On')
        # print(pupCam.get_info('TriggerMode'))

        pupCam = setSpinParams(pupCam, spinParams['pupilCam'])

        if not os.path.exists(saveDir):
            # If it doesn't exist, create the directory
            os.mkdir(saveDir)            
            print(f"Directory '{saveDir}' created.")
        else:
            print(f"Directory '{saveDir}' already exists.")
        pupAcqDir = os.path.join(saveDir,"pupilAcquisition")
        wskAcqDir = os.path.join(saveDir,"whiskerAcquisition")
        if not os.path.exists(pupAcqDir):
            os.mkdir(pupAcqDir)
        if not os.path.exists(wskAcqDir):
            os.mkdir(wskAcqDir)

        print('starting acquisition')

        # open Video Writers
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        pupWriter = cv2.VideoWriter(os.path.join(saveDir,"pupilAcquisition",("pupil.mp4"),fourcc,pupFps,(pupFrameW, pupFrameH)))
        wskWriter = cv2.VideoWriter(os.path.join(saveDir,"whiskerAcquisition",("whisker.mp4"),fourcc,wskFps,(wskFrameW, wskFrameH)))

        while True: # continue triggered acquisition until 'stop' is called
            pupCam.start()
            wskCam.start()
            # print('camStarted')
            pupFrame = pupCam.get_array()
            pupWriter.write(pupFrame)
            # print('arrayGot')
            wskFrame = wskCam.get_array()
            wskWriter.write(wskFrame)


            
            
            # print('savingImg')
            # Image.fromarray(pupFrame).save(os.path.join(saveDir,"pupilAcquisition",("pupilFrame_"+str(i)+".png")))
            # print('ImgSaved')
            # Image.fromarray(wskFrame).save(os.path.join(saveDir,"whiskerAcquisition",("whiskerFrame_"+str(i)+".png")))

            # i+=1
            # print(('frame '+str(i)+' stored'))

            # if i==100:
            #     break

    elif execStatus=="stop":
        PID = os.environ.get("startPID")
        # release VideoWriters
        pupWriter.release()
        wskWriter.release()
         # # Release the camera and system resources
        pupCam.close()
        wskCam.close()                

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