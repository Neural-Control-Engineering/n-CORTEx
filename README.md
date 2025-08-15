![nCORTExWallpaperV](https://github.com/user-attachments/assets/5ee517ec-67c8-478a-b4f6-a1272f8f1e48)


n-CORTEx ("cortex") is a real-time experimentation platform for flexible and dynamic configuration, deployment, and data extraction of multi-modal behavioral and neural interfacing experiments utilizing industry-grade neural or behavioral recording devices on state-of-the-art real-time operating systems.

# INSTALLATION
Download and extract this repository to a preferred file directory location on [each of your 'host' and 'target' computer systems](#using-n-cortex). This master folder should be titled 'n-CORTEx' and should contain the contents included in the desired branch of this repository. It is recommended that beginners or general-purpose users install and use the main branch of n-CORTEx, as developmental branches are less thoroughly documented and maintained.

# SYSTEM REQUIREMENTS

* Matlab 2024a
    * Simulink
    * Simulink Real-Time
    * Simulink Coder
    * MATLAB Coder    
* Python 3.10 or higher
* [Spinnaker SDK](https://www.teledynevisionsolutions.com/products/spinnaker-sdk/?model=Spinnaker%20SDK&vertical=machine%20vision&segment=iis)

# QUICK START
## Host Computer:

On your [host machine](#using-n-cortex), start MATLAB and navigate to the n-CORTEx master folder you installed in the [Installation](#installation) section

Once you have navigated to the top level of this master folder, type the following command into the MATLAB command line and press 'Enter'

```matlab
>> cortex("host")
```

This will start a host-side instance of the n-CORTEx application and add the n-CORTEx folder and its contents to the file search path of your current MATLAB instance for the duration that this n-CORTEx application instance is active. (i.e. Closing this instance of the n-CORTEx application will remove its contents from the MATLAB search path and no additional manual steps are necessary to revert to your original search path)

## Target Computer(s):

On [each of your target machines](#using-n-cortex), start MATLAB and navigate to the n-CORTEx master folder you installed in the [Installation](#installation) section

Once you have navigated to the top level of this master folder, type the following command into the MATLAB command line and press 'Enter'

```matlab
>> cortex("target")
```

This will start a target-side instance of the n-CORTEx application and add the n-CORTEx folder and its contents to the file search path of your current MATLAB instance for the duration that this n-CORTEx application instance is active.


# USING n-CORTEx

## Hardware Setup Guidelines

n-CORTEx supports the integrated functionality of multiple computer systems, each with its unique resource profile that may dictate its status as a 'host' computer or one of up to several 'target' computers—resulting in a network of systems driving a given real-time experiment. Using the latest version of n-CORTEx, the user must possess—*at a minimum*—one host computer and one real-time target computer compatible with MATLAB Simulink Real-Time. The number of 'target' computers included may be extended arbitrarily to account for varying distributions of [neural or behavioral recording devices](#compatible-recording-devices) across numerous computer systems—as arranged by the user—accommodating the following guidelines:

* One host computer to develop and deploy simulink programs that define the experimental paradigms or sequences. (*required*)
* One target computer (connected via ethernet to the 'host' computer) designated as the **real-time target system**. This is usually a real-time computer platform capable of running a real-time operating system (RTOS) such as QNX, VxWorks, RTLinux, etc. (*required*)
* One or more additional 'target' computers equipped with a [specialized recording device](#compatible-recording-devices).

The target application may be run on any of these additional 'target' computers to 1) pre-process and upload recordings from respective recording devices and/or 2) stream these recordings back to the real-time target system (*experimental*):

* This network of computer systems may be interlinked by high-speed ethernet cables to support closed-loop experimental paradigms designed to process real-time feedback from [a given recording device](#compatible-recording-devices). *We are actively developing processes to streamline this and hope to include improvements in future updates*.

## Workflow

### Host-side
n-CORTEx-host requires that you 1) select a simulink module (e.g. a simulink file by the '.slx' extension - MODEL.slx) under 'Modules', 2) select a project directory under 'Project', 3) select or add an experiment directory within this project directory, and then 4) select or add a subject participating in this experiment. See [DOCUMENTATION](#documentation) for additional points on utilizing the peripheral configuration fields to leverage parameterization methods in your experiment module.
![sessionConfig1](https://github.com/user-attachments/assets/c81d62eb-160f-43f7-82c7-dd44a9dc3615)

Completing the above selection fields will enable access to device/modality-specific configuration fields specific to the experiment session as well as a subject-specific field array to help track subject status over the course of an experiment. See [DOCUMENTATION](#documentation) for a detailed breakdown of these panels.
![sessionPanels](https://github.com/user-attachments/assets/97721deb-adfe-4574-8191-a8f3369aa047)

Once you have completed the session configuration, you may connect to the real-time target by pressing the 'connect' button and then deploy and run your module by pressing the 'play' button. You may press the 'stop' button to terminate the session at any time or otherwise wait for the session timer duration to elapse—at which point n-CORTEx-host will automatically terminate the session and compile the session recordings and configuration entries into appropriate struct fields to be uploaded or discarded by the 'upload' and 'discard' buttons, respectively.

1: Connect

![playBanner](https://github.com/user-attachments/assets/9afe67a9-9241-4ba5-8cc5-3c661b124a8f)

2: Play

![playBannerII](https://github.com/user-attachments/assets/6696b83e-21e9-47af-9af7-bd9d116f7ad2)

### Target-side
n-CORTEx-target may be concurrently active on each additional 'target' computer included in driving peripheral recording devices for the experiment. Future updates will expand n-CORTEx capabilities to stream these recordings back to the real-time target system for closed loop aplications. For now, n-CORTEx-target can be used to streamline the offloading of device-specifc recordings to mounted memory storage drives or HPC environments. See [DOCUMENTATION](#documentation) to review the hierarchical structuring of raw recording files and their pre-processed or extracted counterparts that have been uploaded and registered in the application.

# COMPATIBLE RECORDING DEVICES

# DOCUMENTATION

# USING WITH LINUX
