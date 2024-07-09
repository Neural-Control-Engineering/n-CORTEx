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

class rtVista:
    def __init__(self, spinParams, SN):        
        
        cameras = list_cameras()
        numCameras = cameras.GetSize()
        print(str(numCameras) + ' camera(s) found')
        print((SN,': selected'))            
        cam = Camera(SN)
        cam.init()

        self.SN = SN
        self.spinCam = setSpinParams(cam, spinParams)
        self.spinCam.start()

    def open(self):
        self.spinCam.start()

    def close(self):
        self.spinCam.stop()             
        self.spinCam.close()

    def reset(self):
        SN = self.SN;
        cam = Camera(SN)
        cam.init()
        cam.DeviceReset()

    def getFrame(self):
        return self.spinCam.get_array()

    def setSpinParams(camera, spinParams):
        """
        Configure camera parameters based on a dictionary of settings.
    
        Parameters:
        - camera: PySpin camera instance
        - camDict: Dictionary containing camera parameter settings
        """    
        for key, value in spinParams.items():
            if value=='false':
                value=False
            elif value=='true':
                value=True
            print('key: '+str(key))
            print('value: '+str(value))
            setattr(camera, key, value)
            print('set '+str(key)+' to '+str(value))
    
        return camera


    
