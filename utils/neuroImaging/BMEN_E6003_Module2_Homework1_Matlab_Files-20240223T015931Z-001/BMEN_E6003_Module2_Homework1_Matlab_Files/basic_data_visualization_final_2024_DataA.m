%% Homework 1 - Dataset A
% BMEN E6003, Module 2 (Brain Imaging)
% Data handling, visualization and plotting
% 2024 Elizabeth Hillman, Columbia University eh2245@columbia.edu

%% Section 0: load data and information
load('DataA_WFOM_data_RGB_128.mat');

%% Section 1: basic plot of blue data
ss = size(data.blue);
bg = mean(data.blue(:,:,50:100),3);
figure
for i = 1:ss(3)
    subplot(1,2,1)
    imagesc(squeeze(data.blue(:,:,i)));
    colormap gray
    axis image
    title('raw blue data')
    colorbar
    subplot(1,2,2)
    imagesc(squeeze(data.blue(:,:,i)./bg));
    colormap gray
    axis image
    title('blue data ratio to background')
    caxis([0.95 1.05])
    colorbar
    xlabel(i/(m.framerate/m.nLEDs));
    pause(0.1)
end

%% Section 2: make a mask
figure
imagesc(squeeze(mean(data.blue,3)));
colormap gray
axis image
title('select points around boundary and then double-click');
mask = roipoly;

%% Section 3: basic plot of blue, green and red data
colnames = {'blue','green','red'};
cols = {'b','g','r'};
figure
p = [ -4.0000  236.5000  937.5000  552.5000]; % change this to change figure size / position
set(gcf,'Position',p);
% clear M
for i = 1:ss(3)
    for j = 1:3
        subplot(2,3,j)
        eval(sprintf('datahere = mask.*data.%s;',colnames{j}));
        eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnames{j}));
        imagesc(squeeze(datahere(:,:,i)));
        title(colnames{j},'color',cols{j})
        colormap gray
        axis image; axis off
        subplot(2,3,3+j)
        imagesc(squeeze(datahere(:,:,i)./bg));
        colormap gray
        axis image; axis off
        title([colnames{j}, ' ratio to baseline'])
        caxis([0.97 1.03])
    end
    text(10,10,sprintf('t = %.2f s',i/(m.framerate/m.nLEDs)),'color','w');
    pause(.2/(m.framerate/m.nLEDs))
    % M(i) = getframe(gcf);
end
%% Section 4: Region of interest selection and plotting time-courses
i = 150;
j=2;
figure
set(gcf,'Position',[5 370 1040 400]);
subplot(121)
eval(sprintf('datahere = data.%s;',colnames{j}));
eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnames{j}));
imagesc(mask.*squeeze(datahere(:,:,i)./bg));
axis image
caxis([0.97 1.03])
colormap gray
title('Use cursor to select a region of interest');
[y x] = ginput(2);
x=round(x);
y = round(y);
hold on
plot([min(y) max(y) max(y) min(y) min(y)],[min(x) min(x) max(x) max(x) min(x)],'--y');
subplot(122)
for j=1:3;
    eval(sprintf('datahere = data.%s;',colnames{j}));
    eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnames{j}));
    tc(j,:) = mean(mean(datahere(min(x):max(x),min(y):max(y),:),2),1);
    plot([0:size(tc,2)-1]./(m.framerate/m.nLEDs),100*(tc(j,:)./tc(j,1)-1),'color',cols{j});
    hold on
end
xlabel('time (s)')
ylabel('Percent signal change');
legend('blue %','green %','red %');

%% Section 5: Convert reflectance images to HbO and HbR and correct fluorescence
% start by loading the conversion constants that you need.
load('GCaMP_correct_spectra_all.mat');

baseinterval =[10:50];
clear mua chbo chb
data_greenbg =mean(data.green(:,:,round(baseinterval)),3);
data_redbg = mean(data.red(:,:,round(baseinterval)),3);
mua(1,:,:,:)=-(1/DPF1)*log(squeeze(data.green(:,:,:)./repmat(data_greenbg,[1,1,size(data.green,3)])));
mua(2,:,:,:)=-(1/DPF2)*log(squeeze(data.red(:,:,:)./repmat(data_redbg,[1,1,size(data.red,3)])));
clear data.red data.green DPF1 DPF2
data.chbo = squeeze((EHb2*mua(1,:,:,:)-EHb1*mua(2,:,:,:))/(EHbO1*EHb2-EHbO2*EHb1));
data.chbr = squeeze((EHbO2*mua(1,:,:,:)-EHbO1*mua(2,:,:,:))/(EHb1*EHbO2-EHb2*EHbO1));
disp('done converting');

% Use hemodynamics to correct fluorescence for absorption
mua_bX(:,:,:)= EHbX(1)*data.chbr+EHbOX(1)*data.chbo;
mua_gF(:,:,:) = EHbF(2)*data.chbr+EHbOF(2)*data.chbo;
blueX_adjusted = exp(-DPFc(1)*mua_bX(:,:,:));
GFP_adjusted = exp(-DPFc(2)*mua_gF(:,:,:));
clear mua_bX mua_gF
data.blue = double(data.blue);
data.gcamp = data.blue./((blueX_adjusted.^.5).*((GFP_adjusted).^.5));
data.gcamp = data.gcamp./repmat(mean(data.gcamp(:,:,baseinterval),3),[1,1,size(data.gcamp,3)])-1;
disp('done correcting')
colnamesH = {'chbo','chbt','chbr','gcamp'};

%% Section 6: basic plot of HbO, HbR, HbT and gcamp data
cols = {'r','g','b','k'};
data.chbt = data.chbo+data.chbr;
figure
p = [72 395 1300 366];
set(gcf,'Position',p);
cc1 = [-6 6]*1e-6;
cc2 = [-3 3]*0.01;

for i = 1:ss(3)
    for j = 1:4
        subplot(1,4,j)
        eval(sprintf('datahere = mask.*data.%s;',colnamesH{j}));
        eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnamesH{j}));
        imagesc(squeeze(datahere(:,:,i)));
        title(colnamesH{j})
        colormap gray
        axis image; axis off
        if j==4; caxis(cc2); else; caxis(cc1); end
    end
    text(10,10,sprintf('t = %.2f s',i/(m.framerate/m.nLEDs)));
    pause(0.03)
end
%% Section 7: Select ROI and plot data (raw and processed)
i = 150;
j=2;
figure
set(gcf,'Position',[0.0050    0.4650    1.3455    0.3050]*1000);
subplot(1,3,1)
eval(sprintf('datahere = mask.*data.%s;',colnames{j}));
eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnames{j}));
imagesc(squeeze(datahere(:,:,i)./bg));
axis image
caxis([0.97 1.03])
colormap gray
title('Use cursor to select a region of interest');
[y x] = ginput(2);
x=round(x);
y = round(y);
hold on
plot([min(y) max(y) max(y) min(y) min(y)],[min(x) min(x) max(x) max(x) min(x)],'--y');
subplot(1,3,2)
for j=1:4;
    eval(sprintf('datahere = mask.*data.%s;',colnamesH{j}));
    eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnamesH{j}));
    tc(j,:) = mean(mean(datahere(min(x):max(x),min(y):max(y),:),2),1);
    if j<4
        plot([0:size(tc,2)-1]./(m.framerate/m.nLEDs),(tc(j,:)),'color',cols{j});
    else
        plot([0:size(tc,2)-1]./(m.framerate/m.nLEDs),100*(tc(j,:)*1e-5),'color',cols{j});
    end
    hold on
end
title('Neural and Hemodynamic converted')
xlabel('time (s)')
legend('HbO','HbT','HbR','GCaMP');
subplot(1,3,3)
for j=1:3;
    eval(sprintf('datahere = mask.*data.%s;',colnames{j}));
    eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnames{j}));
    tc(j,:) = mean(mean(datahere(min(x):max(x),min(y):max(y),:),2),1);
    plot([0:size(tc,2)-1]./(m.framerate/m.nLEDs),100*(tc(j,:)./tc(j,1)-1),'color',cols{j});
    hold on
end
xlabel('time (s)')
ylabel('Percent signal change');
legend('red %','green %','blue %');
title('Raw data')

%% Section 8: kymograph
columns = [90:110]; % change this
j=7;
eval(sprintf('datahere = mask.*data.%s;',colnamesH{j-3}));

figure
subplot(121)
imagesc(squeeze(mean(datahere(:,:,100:140),3)));
title(colnamesH{j-3})
hold on
xline(min(columns),'color','y'); % this is a new function which may not be in all Matlab versions
xline(max(columns),'color','y');

% caxis([0.97 1.03])
colormap gray
subplot(122)
imagesc([1:ss(3)]/(m.framerate/m.nLEDs), [1:ss(1)],squeeze(mean(data.gcamp(:,columns,:),2)))
xlabel('time (s)');
ylabel('pixels')
title('kymograph')

%% Section 9: clustering
numclust = 12;
ss = size(data.gcamp);
[idx c] = kmeans(reshape(data.gcamp.*mask,[prod(ss(1:2)),ss(3)]),numclust);
figure;
subplot(121)
imagesc(reshape(idx,[ss(1),ss(2)]))
colorbar
title('spatial clusters')
colormap jet
jj = 0.8*jet(numclust);
subplot(122)
for i = 1:numclust
    plot([1:ss(3)]/(m.framerate/m.nLEDs),c(i,:)+i*0.02,'color',jj(i,:));
    hold on
end
xlabel('time (s)');
title('temporal centroids of each cluster')


