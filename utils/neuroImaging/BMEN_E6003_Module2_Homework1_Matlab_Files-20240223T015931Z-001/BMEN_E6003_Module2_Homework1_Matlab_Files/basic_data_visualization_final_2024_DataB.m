%% Homework 1 (Dataset B)
% BMEN E6003, Module 2 (Brain Imaging) 
% Data handling, visualization and plotting
% 2024 Elizabeth Hillman, Columbia University eh2245@columbia.edu

%% Section 0: load data and information
load('DataB_Cell_data_RGB_MIP.mat');
colnames = {'green','red'};
ss = size(data.green);

%% Cell 1: basic plot of single color data
chosecol = 1; % 1 = green (calcium), 2 = red (static marker)
eval(sprintf('datahere = data.%s;',colnames{chosecol}));
bg = mean(datahere(:,:,50:100),3);
figure
for i = 1:ss(3)
    subplot(1,2,1)
    imagesc(meta.cal.y*[1:ss(1)],meta.cal.x*[1:ss(2)],squeeze(datahere(:,:,i)));
    % you may want to tweak your caxis here
    caxis([0 200])
    colormap gray
    axis image
    title(['raw data (',colnames{chosecol},')'])
    colorbar
    subplot(1,2,2)
    imagesc(meta.cal.y*[1:ss(1)],meta.cal.x*[1:ss(2)],squeeze(datahere(:,:,i)./bg));
    colormap gray
    axis image
    title(['ratio to background (',colnames{chosecol},')'])
    caxis([0.9 1.1])
    colorbar
    xlabel(i/(meta.framerate));
    pause(0.1)
end

%% Section 2: basic plot of RGB merge 

chosecol = 1;
% datahere = data.blue;
eval(sprintf('datahere = data.%s;',colnames{chosecol}));
clear RGB
scred = 0.3;
scall = 1/200;
figure
for i = 1:ss(3)
    clear RGB
    RGB(:,:,1) = scred*data.red(:,:,i);
    RGB(:,:,2) = data.green(:,:,i);
    RGB(:,:,3) = zeros(size(data.green(:,:,i)));
    imagesc(meta.cal.y*[1:ss(1)],meta.cal.x*[1:ss(2)],squeeze(RGB(:,:,:,1))*scall);
   axis image
   title(sprintf('t = %.2f mins',i/meta.framerate/60))
   pause(0.1)
end


%% Section 3: Region of interest selection and plotting time-courses

cols = {'g','r'};
colnum = length(colnames);
j=1;
figure
set(gcf,'Position',[5 370 1040 400]);
subplot(121)
eval(sprintf('datahere = data.%s;',colnames{j}));
imagesc(squeeze(mean(datahere(:,:,:),3)));
axis image
title('Use cursor to select a region of interest');
[y x] = ginput(2);
x=round(x);
y = round(y);
hold on
plot([min(y) max(y) max(y) min(y) min(y)],[min(x) min(x) max(x) max(x) min(x)],'--y');
subplot(122)
for j=1:colnum;
    eval(sprintf('datahere = data.%s;',colnames{j}));
    eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnames{j}));
    tc(j,:) = mean(mean(datahere(min(x):max(x),min(y):max(y),:),2),1);
    plot([0:size(tc,2)-1]./(meta.framerate),100*(tc(j,:)./tc(j,1)-1),'color',cols{j});
    hold on
end
xlabel('time (s)')
ylabel('Percent signal change');
legend(colnames);

%% Section 4: kymograph

columns = [1:ss(2)];
chosecol = 1;
eval(sprintf('datahere = data.%s;',colnames{chosecol}));

figure
subplot(121)
imagesc(squeeze(mean(datahere(:,:,30),3)));
title(colnames{chosecol})
hold on
xline(min(columns),'color','y'); % this is a new function which may not be in all Matlab versions
xline(max(columns),'color','y');

subplot(122)
imagesc([1:ss(3)]/(meta.framerate), [1:ss(1)],squeeze(mean(datahere(:,columns,:),2)))
xlabel('time (s)');
ylabel('pixels')
title('kymograph')

%% Section 5: clustering % might take a while to run

chosecol = 1;
% datahere = data.blue;
eval(sprintf('datahere = data.%s;',colnames{chosecol}));
numclust = 12;
ss = size(datahere);
[idx c] = kmeans(reshape(datahere,[prod(ss(1:2)),ss(3)]),numclust);
figure; 
subplot(121)
imagesc(reshape(idx,[ss(1),ss(2)]))
colorbar
title('spatial clusters')
colormap jet
jj = 0.8*jet(numclust);
subplot(122)
for i = 1:numclust
plot([1:ss(3)]/(meta.framerate),c(i,:)+i*0.02,'color',jj(i,:));
hold on
end
xlabel('time (s)');
title('temporal centroids of each cluster')


%% Section 6: segment and extract signals

tmp = max(data.red,[],3);
zz = imbinarize(tmp/max(max(max(tmp))),'adaptive','ForegroundPolarity','bright','Sensitivity',0.4);
se = strel('disk',3);
zz = imerode(zz,se);
CC = bwconncomp(zz);
numPixels = cellfun(@numel,CC.PixelIdxList);
[toosmall,idx] = find(numPixels>15); % eliminate ones that are too small (optional)
mmm=0;
greenlin = reshape(data.green,[prod(ss(1:2)),ss(3)]);
redlin = reshape(data.red,[prod(ss(1:2)),ss(3)]);

zz = zeros(ss(1:2));
for jjj = idx
    mmm=mmm+1;
    rr = CC.PixelIdxList{jjj};
    out.rois{i,mmm} = rr; % store ROIs
    zz(rr) = mmm;
    out.greentc(mmm,:) = mean(greenlin(rr,:),1);
    out.redtc(mmm,:) = mean(greenlin(rr,:),1);
    [I, J, K] = ind2sub(ss(1:3),rr);
    x = mean(I);
    y = mean(J);
    z = mean(K);
    out.centind(mmm,i,:) = [x y z]; % roughly calculate centroids of each cell
end
clear greelin redlin; % delete temp variables to minimize memory
disp(i)

figure
subplot(121)
imagesc(zz)
colormap jet;
jj = jet(mmm)*0.8;
subplot(122)
for i = 1:mmm
    tmp = out.greentc(i,:);
    tmp = tmp-min(tmp);% min subtract then normalizing
    plot([1:ss(3)]/(meta.framerate),tmp/max(tmp)*100+i*100,'color',jj(i,:));
    hold on
end
xlabel('time (s)')
ylabel('% change in fluorescence')
title(sprintf('%d cells found',mmm))
