function st = generateStatusReportByLibrary(libraryNames)
% Go over all subjects in library(by library name) and returns status per
% slide. Sorted by subject name.
%
% INPUTS:
%   libraryNames - can be a string or a cell containing library names. 
%       Examples: 'LA' or {'LA','LB'}
% OUTPUTS:
%   st - sectionStats - structure containing stasticis for each cell. For
%       example. sectionStats.iteration(i) contains the iteration
%       assoicated with sectionPathsOut{i}.
%       see sectionStats.notes for explenation about the fields.

if ~exist('libraryNames','var')
    libraryNames = 'LH';
end

%%  What is the minimal usable area, let us folow calculation:
octVolumeSideLength = 1; %mm
maxDistanceFromOrigin = 0.550; %mm
% Using trigonomaty, what is the length of a histology section, cut at 45
% degrees, maxDistanceFromOrigin away from the origin
l = sqrt(2)*octVolumeSideLength-2*maxDistanceFromOrigin;
h = 0.3 + 0.1; % minimal acceptable depth of OCT section + gel

%% Input checks
if ischar(libraryNames)
    libraryNames = {libraryNames};
end
libraryNames = sort(libraryNames);

%% Get all subejcts in all libraries
subjectPaths = {};
subjectPaths_libraryI = [];
for i=1:length(libraryNames)
    s = s3GetAllSubjectsInLib(libraryNames{i});
    subjectPaths = [subjectPaths; s(:)]; %#ok<AGROW>
    subjectPaths_libraryI = [subjectPaths_libraryI; ones(size(s(:)))*i]; %#ok<AGROW>
end
subjectPaths = sort(subjectPaths);

%% Loop over each subject, get data that is extracted from subjects.
subjectPathsOut = {};
sectionPathsOut = {};
sectionNameOut = {};
sectionIterationOut = [];
sectionNumberOut = [];
libraryNamesOut = {};
fprintf('Processing %d subjects, wait for 10 starts [ ',length(subjectPaths));
for i=1:length(subjectPaths)
    if mod(i,round(length(subjectPaths)/10)) == 0
        fprintf('* ');
    end
    
    % Load subject's stack
    if ~awsExist([subjectPaths{i} 'Slides/StackConfig.json'],'file')
        warning('Cannot find file %s, skipping subject.',[subjectPaths{i} 'Slides/StackConfig.json'])
        continue;
    end
    stackConfigJson = awsReadJSON([subjectPaths{i} 'Slides/StackConfig.json']);
    
    % Get section name and path
    sn = stackConfigJson.sections.names;
    sp = cellfun(@(nm)(awsModifyPathForCompetability( ...
        [subjectPaths{i} '/Slides/' nm '/'])), sn, 'UniformOutput', false);
    sectionPathsOut = [sectionPathsOut; sp(:)]; %#ok<AGROW>
    sectionNameOut = [sectionNameOut; sn(:)]; %#ok<AGROW>
    subjectPathsOut = [subjectPathsOut; repmat(subjectPaths(i),length(sp),1)]; %#ok<AGROW>
    libraryNamesOut = [libraryNamesOut; repmat({libraryNames{subjectPaths_libraryI(i)}},length(sp),1)]; %#ok<AGROW>

    % Get section's iteration
    sectionIterationOut = [sectionIterationOut; stackConfigJson.sections.iterations(:)]; %#ok<AGROW>
    
    % Get section's number in subject
    sectionNumberOut = [sectionNumberOut; (1:length(stackConfigJson.sections.names(:)))']; %#ok<AGROW>
end
fprintf(']. Done!\n');

%% Define st (status) structure
st.libraryNames = libraryNamesOut;
st.subjectNames = cellfun(@s3GetSubjectName,subjectPathsOut,'UniformOutput',false);
st.subjectPahts = subjectPathsOut;
st.sectionNames = sectionNameOut;
st.sectionPahts = sectionPathsOut;
st.iteration = sectionIterationOut;
st.sectionNumber = sectionNumberOut;
st.isSampleHealthy = zeros(size(st.sectionNames),'logical');
st.isFreshHumanSample = zeros(size(st.sectionNames),'logical');
st.isOCTVolumeProcessed = zeros(size(st.sectionNames),'logical');
st.octDepthOfPenetration_um = zeros(size(st.sectionNames))*NaN;
st.octTissueInterfaceVariation_um = zeros(size(st.sectionNames))*NaN;
st.octUserSelectedTissueZ_um = zeros(size(st.sectionNames))*NaN;
st.octTissueInterfaceTilt = zeros(size(st.sectionNames))*NaN;
st.octSurfaceIntensity_db = zeros(size(st.sectionNames))*NaN;
st.octNoiseFloor_db = zeros(size(st.sectionNames))*NaN;
st.isHistologyInstructionsPrepared = ones(size(st.sectionNames),'logical'); %If its on this list, it has histology instructions
st.fluorescenceImagingDate = cell(size(st.sectionNames));
st.sectionDistanceFromOCTOrigin1HistologyInstructions_um = zeros(size(st.sectionNames))*NaN;
st.isFluorescenceImageUploaded = zeros(size(st.sectionNames),'logical');
st.areFiducialLinesMarked = zeros(size(st.sectionNames),'logical');
st.nOfFiducialLinesMarked =  zeros(size(st.sectionNames))*NaN;
st.sectionRotationAngle_deg = zeros(size(st.sectionNames))*NaN;
st.sectionTiltAngle_deg = zeros(size(st.sectionNames))*NaN;
st.sectionSizeChange_percent = zeros(size(st.sectionNames))*NaN;
st.sectionDistanceFromOCTOrigin2SectionAlignment_um = zeros(size(st.sectionNames))*NaN;
st.isRanStackAlignment = zeros(size(st.sectionNames),'logical');
st.wasSectionUsedInComputingStackAlignment = zeros(size(st.sectionNames),'logical');
st.isSectionPartOfAlingedStack = zeros(size(st.sectionNames),'logical');
st.sectionDistanceFromOCTOrigin3StackAlignment_um = zeros(size(st.sectionNames))*NaN;
st.wasResliceOCTVolumeRun = zeros(size(st.sectionNames),'logical');
st.isHistologyImageUploaded = zeros(size(st.sectionNames),'logical');
st.isCompletedHistologyFluorescenceImageRegistration = zeros(size(st.sectionNames),'logical');
st.wasHistologyFluorescenceImageRegistrationSuccessful = zeros(size(st.sectionNames),'logical');
st.isCompletedOCTHistologyFineAlignment = zeros(size(st.sectionNames),'logical');
st.wasRectified = zeros(size(st.sectionNames),'logical');
st.didUserFineTuneAlignmentAfterRectified = zeros(size(st.sectionNames),'logical');
st.sectionDistanceFromOCTOrigin4FineAlignment_um = zeros(size(st.sectionNames))*NaN;
st.isOCTImageQualityGood = zeros(size(st.sectionNames),'logical')*NaN;
st.isDermisVisibleInOCT = zeros(size(st.sectionNames),'logical')*NaN;
st.isHistologyImageQualityGood = zeros(size(st.sectionNames),'logical')*NaN;
st.pGelDetachedFromTissueHistology = zeros(size(st.sectionNames))*NaN;
st.alignmentQuality = zeros(size(st.sectionNames))*NaN;
st.wereFeaturesInsideTissueUsedInAlignment = zeros(size(st.sectionNames),'logical')*NaN;
st.yAxisTolerance_um = zeros(size(st.sectionNames))*NaN;
st.isQualityControlMaskGenerated = zeros(size(st.sectionNames),'logical');
st.areaOfQualityData_mm2 = zeros(size(st.sectionNames))*NaN;
st.isUsableInML = zeros(size(st.sectionNames),'logical');
st.mlPhase = zeros(size(st.sectionNames));

st.notes = sprintf([ ...
    ' -- General and Scanning Parameters --\n' ...
    'libraryNames - e.g. ''LC'', ''LD''.\n' ... 
    'subjectNames, subjectPahts - direct path to the subject corresponding to the section.\n' ...
    'sectionNames, sectionPahts - section name and direct path to the specific section.\n' ...
    'iteration - iteration number that this section was taken as part of.\n' ...
    'sectionNumber - section''s number in subject.\n' ...
    'isSampleHealthy - is sample cancer (false) or healthy (true) tissue?\n' ...
    'isFreshHumanSample - is this sample a fresh human sample? Otherwise it can be old sample or non human test sample.\n' ...
    'fluorescenceImagingDate - section scan date - time string.\n' ...
    'isHistologyInstructionsPrepared - was histology instructions exist for this section.\n' ... 
    'isOCTVolumeProcessed - was OCT volume processed to generate a tif file.\n' ...
    ' -- OCT Volume Statistics --\n' ...
    'octDepthOfPenetration_um - depth of penetration of OCT light into the sample.\n' ...
    'octTissueInterfaceVariation_um - what is the difference between the highest point in the tissue and the lowest, given tissue tilt is corrected.\n' ...
    'octUserSelectedTissueZ_um - difference between user selected average tissue interface depth and the computed average.\n' ...
    'octTissueInterfaceTilt - overall tilt of the sample (%% grade) abesolute magnitude.\n' ...
    'octSurfaceIntensity_db - surface signal magnitude.\n' ...
    'octNoiseFloor_db - noise flour magnitude.\n' ...
    ' -- Histology Instructions --\n' ...
    'sectionDistanceFromOCTOrigin1HistologyInstructions_um - distance between section to OCT origin in microns, best guess according to the time histology instructions were made.' ...
    ' -- Alignment Using a Single Slide --\n' ....
    'isFluorescenceImageUploaded - was fluorescence image scanned and uploaded for this section.\n' ...
    'areFiducialLinesMarked - are fiducial lines marked in fluorescence image?\n' ...
    'nOfFiducialLinesMarked - number of marked lines for each section. Set to nan if no lines were marked.\n' ...
    'sectionRotationAngle_deg - section''s rotation angle (along z axis) in deg, single plane fit of this section. Set to nan if no stack alignment computed.\n' ...
    'sectionTiltAngle_deg - section''s rotation along y axis in deg, single plane fit of this section. Set to nan if no stack alignment computed.\n' ...
    'sectionSizeChange_percent - section size change (%%). Negative means shrink, single plane fit of this section. Set to nan if no stack alignment computed.\n' ...
    'sectionDistanceFromOCTOrigin2SectionAlignment_um - distance between section to OCT origin in microns, single plane fit of this section. Nan if doesn''t exist.\n' ...
    ' -- Alignment Using Stack --\n' ....
    'isRanStackAlignment - is stack alignment algroithm ran on this section?\n' ...
    'wasSectionUsedInComputingStackAlignment - is section aligned with its iteration stack? Was it used to generate stack alignment? If set to false it was an outlier.\n' ...
    'isSectionPartOfAlingedStack - is stack iteration associated with this section aligned, even if this section itself not alignable.\n' ...
    'sectionDistanceFromOCTOrigin3StackAlignment_um - distance between section to OCT origin in microns according to stack alignment. Nan if doesn''t exist.\n' ...
    'wasResliceOCTVolumeRun - was OCT volume resliced for the iteration that this section is part of?\n' ...
    ' -- Histology and Fine Alignment --\n' ...
    'isHistologyImageUploaded - was H&E image uploaded.\n' ...
    'isCompletedHistologyFluorescenceImageRegistration - was H&E image aligned with fluorescence image.\n' ...
    'wasHistologyFluorescenceImageRegistrationSuccessful - was H&E image aligned with fluorescence image succesfully or the alignment failed?\n' ...
    'isCompletedOCTHistologyFineAlignment - was fine alignment completed between OCT and histology? At least before rectified.\n' ...
    'wasRectified - after computing fine alignment, did run rectify? (at least once). Notice that user can change fine alignment after rectification. We just want to make sure rectify was run at least once, fine tuning can be done after rectifying.\n' ... 
    'didUserFineTuneAlignmentAfterRectified - after running rectify, user should go on each slide, make sure x-z and rotation matches between OCT and histology, and save again. If they haddent done so, this varible will be false.\n' ...
    'sectionDistanceFromOCTOrigin4FineAlignment_um - distance between section to OCT origin in microns according to fine alignment. Nan if doesn''t exist.\n' ...
    ' -- Quality Control --\n' ...
    'isOCTImageQualityGood - is epithelium visible, image not shadowed, overall image good?\n' ...
    'isDermisVisibleInOCT - is Dermis visible in OCT image?\n' ...
    'isHistologyImageQualityGood - overall image quality is good, very little detachment and tissue not folded.\n' ...
    'pGelDetachedFromTissueHistology - what precentage (fraction of 1) gel detachement happend in the tissue at the overlap area between oct and histology.\n' ...
    'alignmentQuality - overall quality 1-3 (3 very good).\n' ...
    'wereFeaturesInsideTissueUsedInAlignment - true / false, were features inside tissue help determine alignment?\n' ...
    'yAxisTolerance_um - how much does one need to transverse in the prepandicular direction before slide doesnt match.\n' ...
    'isQualityControlMaskGenerated - is ran quality control on image.\n' ...
    'areaOfQualityData_mm2 - at the aligned image, how big is the area which has high quality data.\n' ...
    'isUsableInML - true or false, do we have enugh to use it for machine learning.\n'  ...
    'mlPhase - Which phase is this section participate in: -1 - training set, 1 - testing set, or 0 - not participating in ML.\n'  ...
    ]);

%% For debug purposes, find a specific slide that we would like to focus on
dSubject = 'LG-42';
dSlideSection = 'Slide05_Section03';
dI = cellfun(@(x)(contains(x,dSubject) && contains(x,dSlideSection)),sectionPathsOut); 
if ~any(dI) 
    dI = -1;
else
    dI = find(dI); % dI will contain the right section we are looking for. Set a breakpoint and i=dI and it should work, including loading the one off files needed.
end

%% Loop over each section, get statistics for each
fprintf('Processing %d sections, wait for 20 starts [ ',length(sectionPathsOut));
for i=1:length(sectionPathsOut)
    try
    if mod(i,round(length(sectionPathsOut)/20)) == 0
        fprintf('* ');
    end
    
    %% Sample parameters
    if i==1 || ~strcmp(st.subjectPahts{i},st.subjectPahts{i-1}) ...
            || i==dI %Debug
        subjectJson = awsReadJSON([st.subjectPahts{i} '/Subject.json']);
    end
    st.isSampleHealthy(i) = strcmp(subjectJson.sampleType,'Healthy');
    st.isFreshHumanSample(i) = subjectJson.isFreshHumanSample;
    
    %% OCT parameters
    
    % Was OCT Volume Tif generated
    if i==1 || ~strcmp(st.subjectPahts{i},st.subjectPahts{i-1}) ...
            || i==dI %Debug
        st.isOCTVolumeProcessed(i) = awsExist([st.subjectPahts{i} '/OCTVolumes/VolumeScanAbs/TifMetadata.json'],'file');
        scanConfigJson = awsReadJSON([st.subjectPahts{i} '/OCTVolumes/ScanConfig.json']);
    else
        %Its the same subject, so use the same value.
        st.isOCTVolumeProcessed(i) = st.isOCTVolumeProcessed(i-1);
    end
    
    if (st.isOCTVolumeProcessed(i) && isfield(scanConfigJson,'volumeStatistics'))
        st.octDepthOfPenetration_um(i) = nanmax([scanConfigJson.volumeStatistics.depthOfPenetration_um NaN]);
        st.octTissueInterfaceVariation_um(i) = ...
            nanmax([scanConfigJson.volumeStatistics.maxTissueInterfaceZ_um - scanConfigJson.volumeStatistics.minTissueInterfaceZ_um NaN]);
        st.octUserSelectedTissueZ_um(i) = nanmax([scanConfigJson.volumeStatistics.userSelectedTissueZ_um NaN]);
        st.octTissueInterfaceTilt(i) = nanmax([sqrt( ...
            scanConfigJson.volumeStatistics.tissueInterfaceTiltX.^2 + ...
            scanConfigJson.volumeStatistics.tissueInterfaceTiltY.^2 ), NaN]);
        st.octSurfaceIntensity_db(i) = nanmax([scanConfigJson.volumeStatistics.surfaceIntensity_db NaN]);
        st.octNoiseFloor_db(i) = nanmax([scanConfigJson.volumeStatistics.noiseFloor_db NaN]);
    end
    
    %% Stack related parameters
    
    % Read stack config if required - if it is a new subject.
    if i==1 || ~strcmp(st.subjectPahts{i-1},st.subjectPahts{i}) ...
            || i==dI %Debug
        stackConfigJson = awsReadJSON([st.subjectPahts{i} 'Slides/StackConfig.json']);
    end
    
    % Get stack position according to histology instructions.
    dist_um = arrayfun(@(hi)((-hi.estimatedDistanceFromFullFaceToOCTOrigin_um+hi.sectionDepthsRequested_um)'),...
        stackConfigJson.histologyInstructions.iterations,'UniformOutput',false);
    dist_um = [dist_um{:}];
    if isfield(stackConfigJson,'stackAlignment') && ... Ran stack alignment
            length(stackConfigJson.stackAlignment) >= st.iteration(i) && ... Ran stack alignment for this iteration
            ~isempty(stackConfigJson.stackAlignment(st.iteration(i)).planeNormal) % and stack alignment succeed for this iteration
        dirFlip = ...
            stackConfigJson.stackAlignment(st.iteration(i)).isPlaneNormalSameDirectionAsCuttingDirection;
    else
        dirFlip = 1;
    end
    st.sectionDistanceFromOCTOrigin1HistologyInstructions_um(i) = ...
        dist_um(st.sectionNumber(i)).* dirFlip;
    
    % Stack alignment plane position, stack alignment can happen even if
    % nothing is known about this slide except it was requested from histology.
    if isfield(stackConfigJson,'stackAlignment') &&  ...
            st.iteration(i) <= length(stackConfigJson.stackAlignment)

        st.isRanStackAlignment(i) = true;   

        % planeDistanceFromOCTOrigin_um
        planeDistanceFromOCTOrigin_um = ...
            cellfun(@(x)(x(:)'),{stackConfigJson.stackAlignment.planeDistanceFromOCTOrigin_um},'UniformOutput',false);
        planeDistanceFromOCTOrigin_um = [planeDistanceFromOCTOrigin_um{:}];
        if st.sectionNumber(i)<=length(planeDistanceFromOCTOrigin_um)
            planeDistanceFromOCTOrigin_um = planeDistanceFromOCTOrigin_um(st.sectionNumber(i));
        else
            planeDistanceFromOCTOrigin_um = nan; % No stack alignment data for this section.
        end

        % Is section part of aligned stack and what is its distance
        if ~isnan(planeDistanceFromOCTOrigin_um)
            st.isSectionPartOfAlingedStack(i) = true;
            st.sectionDistanceFromOCTOrigin3StackAlignment_um(i) = planeDistanceFromOCTOrigin_um;
        end
        
        % wasSectionUsedInComputingStackAlignment
        wasSectionUsedInComputingStackAlignment = ...
            cellfun(@(x)(x(:)'),{stackConfigJson.stackAlignment.wasSectionUsedInComputingStackAlignment},'UniformOutput',false);
        wasSectionUsedInComputingStackAlignment = [wasSectionUsedInComputingStackAlignment{:}];
        if st.sectionNumber(i)<=length(wasSectionUsedInComputingStackAlignment)
            wasSectionUsedInComputingStackAlignment = wasSectionUsedInComputingStackAlignment(st.sectionNumber(i));
        else
            wasSectionUsedInComputingStackAlignment = nan; % No stack alignment data for this section.
        end
        
        % Is section part of aligned stack and what is its distance
        if ~isnan(wasSectionUsedInComputingStackAlignment)
            st.wasSectionUsedInComputingStackAlignment(i) = wasSectionUsedInComputingStackAlignment;
        end
    else
        % No stack alignment calculated yet, do nothing.
    end
    
    % Was OCT volume resliced?
    if i==1 || ~strcmp(st.subjectPahts{i},st.subjectPahts{i-1}) || st.iteration(i) ~= st.iteration(i-1) ...
        || i==dI %Debug
        reslicedVolumePath = ...
            sprintf('%s/OCTVolumes/StackVolume_Iteration%d',...
                st.subjectPahts{i},  st.iteration(i));  
        st.wasResliceOCTVolumeRun(i) = awsExist(reslicedVolumePath,'folder');
    else
        st.wasResliceOCTVolumeRun(i) = st.wasResliceOCTVolumeRun(i-1);
    end
    
    %% Slide Config Parameters
    
    slideConfigFilePath = awsModifyPathForCompetability(...
        [sectionPathsOut{i} '/SlideConfig.json']);
    % Does slide config exist?
    if ~awsExist(slideConfigFilePath,'File')
        % No configuration file, I guess this slides doesn't have anything.
        continue;
    end
    slideConfigJson = awsReadJSON(slideConfigFilePath);
   
    % Photobleached lines image uploaded
    if isfield(slideConfigJson,'photobleachedLinesImagePath')
        st.isFluorescenceImageUploaded(i) = true;
    end
    
    % Fiducial lines marked & how many?
    if isfield(slideConfigJson,'FM') && isfield(slideConfigJson.FM,'fiducialLines')
        st.areFiducialLinesMarked(i) =  true;
        st.nOfFiducialLinesMarked(i) = sum([slideConfigJson.FM.fiducialLines.group] ~= 't');
        st.fluorescenceImagingDate{i} = slideConfigJson.FM.imagedAt;
        
        % Did single plane fit ran? / succeed
        if isfield(slideConfigJson.FM,'singlePlaneFit') && ~isempty(slideConfigJson.FM.singlePlaneFit)
            d = slideConfigJson.FM.singlePlaneFit.d;
            if isempty(d)
                d = NaN;
            end
            st.sectionDistanceFromOCTOrigin2SectionAlignment_um(i) = d*1e3;
            st.sectionRotationAngle_deg(i) = slideConfigJson.FM.singlePlaneFit.rotation_deg;
            st.sectionTiltAngle_deg(i) = slideConfigJson.FM.singlePlaneFit.tilt_deg;
            st.sectionSizeChange_percent(i) = slideConfigJson.FM.singlePlaneFit.sizeChange_precent;
        end
    else
        % Do nothing because it may be that slide continued despite no fiducial lines
    end
    
    % Do we have histology scanned?
    if isfield(slideConfigJson,'histologyImageFilePath')
        st.isHistologyImageUploaded(i) = true;
    end
    
    % Is histology aligned with fluorescence image?
    if isfield(slideConfigJson,'FMHistologyAlignment')
        st.isCompletedHistologyFluorescenceImageRegistration(i) = true;
        
        % Did the alignment succeeded?
        if isfield('wasAlignmentSuccessful',slideConfigJson.FMHistologyAlignment)
            st.wasHistologyFluorescenceImageRegistrationSuccessful(i) = ...
                slideConfigJson.FMHistologyAlignment.wasAlignmentSuccessful;
        else
            st.wasHistologyFluorescenceImageRegistrationSuccessful(i) = false;
        end
    end
    
    % Was fine alignment ran?
    if (isfield(slideConfigJson.FM,'singlePlaneFit_FineAligned'))
        st.isCompletedOCTHistologyFineAlignment(i) = true;
        st.sectionDistanceFromOCTOrigin4FineAlignment_um(i) = ...
            slideConfigJson.FM.singlePlaneFit_FineAligned.d*1e3; % Use d and not distanceFromOrigin_mm because we want negative and positive values.
        
        if isfield(slideConfigJson.FM.singlePlaneFit_FineAligned,'wasRectified')
            st.wasRectified(i) = slideConfigJson.FM.singlePlaneFit_FineAligned.wasRectified;
        end
        
        if st.wasRectified(i)
            % Rectified ran, did user fine tune alignment to make sure its
            % saved now?
            if isfield(slideConfigJson,'FMOCTAlignment')
                %The following line below is indicative if the user saved
                %the fine alignment after running
                tmp = slideConfigJson.FMOCTAlignment.planeDistanceFromOrigin_mm - slideConfigJson.FM.singlePlaneFit_FineAligned.d;
                st.didUserFineTuneAlignmentAfterRectified(i) = abs(tmp) < 1e-3;
            end
        end
    end
    
    % QA Info
    [qScore, isOCTImageQualityGood, isHistologyImageQualityGood, ...
        alignmentQuality, areaOfQualityData_mm2] = ...
        computeOverallSectionQuality (st.sectionPahts{i});
    
    if isfield(slideConfigJson,'QAInfo') && ~isempty(slideConfigJson.QAInfo)
        st.yAxisTolerance_um(i) = ...
            slideConfigJson.QAInfo.AlignmentQuality.YAxisToleranceMicrons;
        st.pGelDetachedFromTissueHistology(i) = slideConfigJson.QAInfo.HandEImageQuality_InOverlapArea.WasGelDetachedFromTissue;

        st.isOCTImageQualityGood(i) = isOCTImageQualityGood;   
        st.isDermisVisibleInOCT(i) = slideConfigJson.QAInfo.OCTImageQuality.IsDermisVisible;
        st.isHistologyImageQualityGood(i) = isHistologyImageQualityGood;
        st.alignmentQuality(i) = alignmentQuality;
    
        st.wereFeaturesInsideTissueUsedInAlignment(i) = ...
            slideConfigJson.QAInfo.AlignmentQuality.WereFeaturesInsideTissueUsedInAlignment;
    end
    
    % Was mask generated? and is most upto date
    % (st.didUserFineTuneAlignmentAfterRectified)
    if isfield(slideConfigJson,'alignedImagePath_Mask') && st.didUserFineTuneAlignmentAfterRectified(i)
        st.isQualityControlMaskGenerated(i) = true;
    end

    %% Finally,
    if st.isQualityControlMaskGenerated(i)
        % Figure out the area of good data
        st.areaOfQualityData_mm2(i) = areaOfQualityData_mm2;
    end
    
    st.isUsableInML(i) = qScore > 0;
    catch ME
        warning('error happend i=%d (line %d), path %s. Message: %s',...
            i,ME.stack(1).line,sectionPathsOut{i}, ME.message);
    end
end

% Update ml phases
ph = splitDataToPhases(st.subjectNames);
st.mlPhase = ( (ph==0)*(-1) + (ph==1)*(1) ).*st.isUsableInML;

fprintf(']. Done!\n');
