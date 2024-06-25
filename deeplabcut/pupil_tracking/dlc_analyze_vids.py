import os
import deeplabcut

config_path = 'D:\\Columbia_Masters\\NeuralEng_Control_Lab\\CodeRepo\\deeplabcut\\pupil_tracking-Dillon Noone-2024-06-23\\config.yaml'

vid_dir = "D:\\Columbia_Masters\\NeuralEng_Control_Lab\\CodeRepo\\deeplabcut\\pupil_tracking-Dillon Noone-2024-06-23\\videos"

videolist = [os.path.join(vid_dir, 'date--2024-05-31_subj--3818-20240304_geno--Dbh-Cre-x-Ai32_photom--R-rcNE1-1-jGCaMP8m-Isosbestic_opto--_phase--beta-testing_g0.mp4'),
             os.path.join(vid_dir, 'date--2024-06-10_subj--3818-20240304_geno--Dbh-Cre-x-Ai32_photom--R-rcNE1-1-jGCaMP8m-Isosbestic_opto--_phase--beta-testing_g0.mp4'),
             os.path.join(vid_dir, 'date--2024-06-11_subj--3818-20240304_geno--Dbh-Cre-x-Ai32_photom--R-rcNE1-1-jGCaMP8m-Isosbestic_opto--_phase--beta-testing_g0.mp4'),
             os.path.join(vid_dir, 'date--2024-06-13_subj--3818-20240304_geno--Dbh-Cre-x-Ai32_photom--R-rcNE1-1-jGCaMP8m-Isosbestic_opto--_phase--beta-testing_g0.mp4'),
             os.path.join(vid_dir, 'date--2024-06-14_subj--3818-20240304_geno--Dbh-Cre-x-Ai32_photom--R-rcNE1-1-jGCaMP8m-Isosbestic_opto--_phase--beta-testing_g0.mp4')]

#deeplabcut.analyze_videos(config_path, videolist, save_as_csv=True, destfolder='D:\\Columbia_Masters\\NeuralEng_Control_Lab\\data\\simple_sensory_stim\\CAMERA\\pupil_tracking_model\\predict\\csv')
deeplabcut.analyze_videos(config_path, videolist)
deeplabcut.create_labeled_video(config_path, videolist, save_frames=True)