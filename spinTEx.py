import PySpin
import sys
import os
import signal
import json

# MINI LIBRARY BUILT FROM SPINVIEW API (SPINNAKER SDK) TO CONFIGURE AND START A SPINVIEW ACQUISITION

def main():
    # Check if the required argument is provided
    # if len(sys.argv) != 2:
    #     print("Usage: python script.py <spinParams_json>")
    #     sys.exit(1)

    # spinParams = sys.argv[1] 
    spinParams="{\"saveDir\": \"Select Project Directory\", \"pupilCam\": {\"TriggerMode\": 1}, \"whiskCam\": {\"TriggerMode\": 1}, \"execStatus\": \"start\"}"
    spinParams = json.loads(spinParams)       
    

    # retrieve video save location
    saveDir = spinParams["saveDir"]
    execStatus = spinParams["execStatus"]

    

    if execStatus=="start":
        
        # store PID for future 'stop' interrupt
        print('initiating vision capture')
        # os.environ["startPID"] = os.getpid()
        
        # Initiate Cameras
        system = PySpin.System.GetInstance()
        cam_list = system.GetCameras()
        numCams=cam_list.GetSize()
        for i, camera in enumerate(cam_list):
            TLDeviceNodeMap = camera.GetTLDeviceNodeMap()
            iNode = TLDeviceNodeMap.GetNode("DeviceSerialNumber")
            serial_number = iNode.GetUniqueID()
            # serial_number = camera.GetTLDeviceNodeMap().GetNode("DeviceSerialNumber").GetUniqueID()
            print(f"Camera {i + 1} - Serial Number: {serial_number}")
        # if num_cameras == 0:
        #     raise Exception("No cameras found!")            
        pup_camera = cam_list.GetBySerial('19133897')    
        pup_camera.Init()
        tst_cam=cam_list.GetBySerial('11212')    

        print(pup_camera)
        # wsk_camera = cam_list.GetBySerial('')           


        # Configure Cameras
        pup_camera = setSpinParams(pup_camera, spinParams["pupilCam"])        
        print('Cameras configured')
        # wsk_camera = setSpinParams(wsk_camera, spinParams["whiskCam"])
        
        # Acquire images by triggermode
        pup_camera.BeginAcquisition()
        print('Starting Acquisition')
        # wsk_camera.BeginAcquisition()
        i=0
        # while True: # continue triggered acquisition until 'stop' is called
        #     pupFrame = pup_camera.GetNextImage()
        #     # wskFrame = wsk_camera.GetNextImage()

        #     pupFrame.Save(os.path.join(saveDir,"pupilAcquisition",("pupilFrame_"+str(i)+".png")))
        #     # wskFrame.Save(os.path.join(saveDir,"whiskerAcquisition",("whiskerFrame_"+str(i)+".png")))          

        #     i+=1
        #     print(i)


    elif execStatus=="stop":
        PID = os.environ.get("startPID")
        os.kill(PID)

         # # Release the camera and system resources
        pup_camera.DeInit()
        # wsk_camera.DeInit()
        del pup_camera
        # del wsk_camera
        system.ReleaseInstance()
    else:
        raise Exception("Missing ExecStatus!")  
    
def setSpinParams(camera, camDict):
    """
    Configure camera parameters based on a dictionary of settings.

    Parameters:
    - camera: PySpin camera instance
    - camDict: Dictionary containing camera parameter settings
    """
    # Open the camera
    camera.Init()

    # Access the camera node map for parameter manipulation
    nodemap = camera.GetNodeMap()

    # Loop through the dictionary and assign parameter values
    for param_name, param_value in camDict.items():
        try:
            # Get the parameter node based on its name
            param_node = PySpin.CFloatPtr(nodemap.GetNode(param_name))
            
            # Check if the parameter node exists and is writable
            if param_node is not None: #and param_node.IsWritable():
                # Set the parameter value
                print(f"Setting {param_name} to {param_value}")
                param_node.SetValue(param_value)
                
            else:
                print(f"Skipping {param_name} (not writable)")

        except Exception as e:
            print(f"Error configuring {param_name}: {str(e)}")
    
    return camera


if __name__ == "__main__":
    main()