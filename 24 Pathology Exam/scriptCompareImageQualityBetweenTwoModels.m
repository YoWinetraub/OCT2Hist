% This script compares image quality between two models

modelNameA = 's3://delazerdamatlab/Users/OCTHistologyLibrary/_MLModels/2020-11-10 Jessica with_history_buff/'; % Part of the model name
modelNameB = 'paper 4 used in paper v2'; % Part of the model name to compare to - version in the paper
isCorrectAspectRatio2To1 = true;

outputFolder = [pwd '\tmp\'];
scaleBar = 100; % Plot scale bar [um]

%% Download data 
disp('Downloading data ...');
awsMkDir(outputFolder,true);

[modelToLoadFolderA, resultsPathA] = s3GetPathToModelResults(modelNameA);
downlaodModelResultsImages(resultsPathA,isCorrectAspectRatio2To1,[outputFolder 'A\'],scaleBar);

[modelToLoadFolderB, resultsPathB] = s3GetPathToModelResults(modelNameB);
downlaodModelResultsImages(resultsPathB,isCorrectAspectRatio2To1,[outputFolder 'B\'],scaleBar);

st = awsReadJSON([modelToLoadFolderA '/dataset_oct_histology/original_image_pairs/StatusReportBySection.json']);

%% Prepeare form

[~,fpsA] = awsls([outputFolder 'A\']); fpsA = fpsA';
[~,fpsB] = awsls([outputFolder 'B\']); fpsB = fpsB';

trainingFilesI = pickNRandomSections(st,15,st.mlPhase == -1 & st.isSampleHealthy); % & computeOverallSectionQuality(st) == 2);
testingFilesI  = pickNRandomSections(st,35,st.mlPhase == 1 & st.isSampleHealthy); %& computeOverallSectionQuality(st) == 2);

whichFilesA = findFilesInST(fpsA, st, trainingFilesI | testingFilesI);
whichFilesB = findFilesInST(fpsB, st, trainingFilesI | testingFilesI);

whichFilesReal = whichFilesA & cellfun(@(x)(contains(x,'_real_B.png')),fpsA);
whichFilesA = whichFilesA & cellfun(@(x)(contains(x,'_fake_B.png')),fpsA);
whichFilesB = whichFilesB & cellfun(@(x)(contains(x,'_fake_B.png')),fpsB);

% Make sure same files appear in both sets
if sum(whichFilesA) ~= sum(whichFilesB)
    error('Not the same files exists in A and B, re-run this script it might help');
end

fpsReal = fpsA(whichFilesReal);
fpsA = fpsA(whichFilesA);
fpsB = fpsB(whichFilesB);

i = randperm(length(fpsA));
fpsA = fpsA(i);
fpsB = fpsB(i);
fpsReal = fpsReal(i);

%% Load Questions
isABetterThenB = ones(sum(whichFilesA),1)*NaN; % A = 0, B=1
for i=1:length(isABetterThenB)
    BOnTop = rand(1) > 0.5;
    
    imA = imread(fpsA{i});
    imB = imread(fpsB{i});
    imReal = imread(fpsReal{i});
    
    f = figure(1);
    set(f,'units','normalized','outerposition',[0 0 0.35 1]);
    subplot(3,1,2*BOnTop+1);
    imshow(imA); title('Computer Generated');
    subplot(3,1,3-2*BOnTop);
    imshow(imB); title('Computer Generated');
    subplot(3,1,2);
    [~,fn] = fileparts(fpsReal{i});
    imshow(imReal); title(fn)
    
    answer = questdlg(...
        'Which computer generated image looks more realistic?',...
        sprintf('Image %d of %d',i,length(isABetterThenB)),...
        'Image on Top','Image on Bottom','I''m Done','I''m Done');
    
    switch(answer)
        case 'I''m Done'
            break;
        case 'Image on Top'
            isABetterThenB(i) = BOnTop;
        case 'Image on Bottom'
            isABetterThenB(i) = 1-BOnTop;
        otherwise
            error('Never should happen');
    end
end    

%% Plot Statistics
f = figure(1);
set(f,'units','normalized','outerposition',[0 0 1 1]);
subplot(1,1,1);
subplot(3,2,[1 2]);
plot(isABetterThenB);
yticks([0,1]);
yticklabels({[modelNameA ' is Better'], [modelNameB ' is Better']});
xlabel('Image #')

isTrainSet = cellfun(@(x)(contains(x,'train','IgnoreCase',true)),fpsA);
subplot(3,2,[3 5]);
histogram(isABetterThenB(isTrainSet & ~isnan(isABetterThenB)),'Normalization','probability');
title('Training Set');
xticks([0,1]);
xticklabels({[modelNameA ' is Better'], [modelNameB ' is Better']});
ylim([0 1]);

subplot(3,2,[4 6]);
histogram(isABetterThenB(~isTrainSet & ~isnan(isABetterThenB)),'Normalization','probability');
title('Testing Set');
xticks([0,1]);
xticklabels({[modelNameA ' is Better'], [modelNameB ' is Better']});
ylim([0 1]);
