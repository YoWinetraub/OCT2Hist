% This script will set up ML by opening an instance, copying etc. on aws
% To launch ml instance in aws, we will be following instructions by:
% https://aws.amazon.com/blogs/machine-learning/get-started-with-deep-learning-using-the-aws-deep-learning-ami/

%% Inputs

% We can start ML instance from a dataset (clean start), or from a
% previously saved snapshot.
% datasets are saved in _Datasets, Snapshots are saved in _MLModels
loadFrom = 'dataset'; % Set to 'dataset' or 'snapshot'

% When loadFrom = 'dataset', will get the latest dataset which follows these conditions:
imageResolution = '10x'; % Can be 2x,4x,10x
datasetTag = ''; % Additional string to search for 

% When loadFrom = 'snapshot', will get the snapshot with this name (or part of the name)
% Loads from _MLModels
snapshotName = '2020-06-13 10x';

%% Get data from Jenkins

%This function updates all input varible names that have name_ like this:
%name = name_
setVariblesFromJenkins(); 

currentFileFolder = fileparts(mfilename('fullpath'));

%% Lunch Instance
fprintf('%s Launching instance...\n',datestr(datetime));

% This function is generated by awsSetCredentials_Private.
awsSetCredentials();
ec2RunStructure = My_ec2RunStructure_DeepLearning();

% Launch instance
ec2Instance = awsEC2StartInstance(ec2RunStructure,'g4dn.4xlarge');

%% Copy Data to instance
if strcmpi(loadFrom,'dataset')
    fprintf('%s Copy dataset to instance...\n',datestr(datetime));

    datasetPath = s3GetPathToLatestDataset(imageResolution,datasetTag);
    datasetPath = strrep(datasetPath,' ','\ ');
    
    disp(datasetPath);
    origPath = datasetPath;

    [status,txt] = awsEC2RunCommandOnInstance (ec2Instance,{...
        'mkdir -p ~/ml' ... Make a home directory
        ['aws s3 sync ' datasetPath ' ~/ml/dataset_oct_histology/']
        });
    if (status ~= 0)
        awsEC2TerminateInstance(ec2Instance);%Terminate
        error('Failed to sync dataset: %s',txt);
    end
else  
    fprintf('%s Copy snapsoht to instance...\n',datestr(datetime)); 

    l = awsls(s3SubjectPath('','_MLModels'));
    l = l(cellfun(@(x)(contains(x,snapshotName)),l));
    
    if (isempty(l))
        awsEC2TerminateInstance(ec2Instance);%Terminate
        error('can not find "%s" in _MLModels folder',snapshotName);
    end

    pathToSnapshot = awsModifyPathForCompetability(sprintf('%s/%s/', ...
        s3SubjectPath('','_MLModels'),l{1}),true);
    pathToSnapshot = strrep(pathToSnapshot,' ','\ ');
    
    disp(pathToSnapshot);
    origPath = pathToSnapshot;
    
    [status,txt] = awsEC2RunCommandOnInstance (ec2Instance,{...
        'mkdir -p ~/ml' ... Make a home directory
        ['aws s3 sync ' pathToSnapshot ' ~/ml/']
        });
    if (status ~= 0)
        awsEC2TerminateInstance(ec2Instance);%Terminate
        error('Failed to sync dataset: %s',txt);
    end
end
origPath = strrep(origPath,'\ ',' ');

%% Upload Jupyter notebooks 
fprintf('%s Copy notebooks to instance...\n',datestr(datetime));
filesOnThisFolder = awsls(currentFileFolder);
isNotebook = cellfun(@(x)(contains(x,'.ipynb')),filesOnThisFolder);
isPyCode = cellfun(@(x)(contains(x,'.py')),filesOnThisFolder);
notbookPaths = filesOnThisFolder(isNotebook | isPyCode);

for i=1:length(notbookPaths)
    awsEC2UploadDataToInstance(ec2Instance,[currentFileFolder '/' notbookPaths{i}]...
        ,'~/ml/'); %Copy
end

fprintf('%s Done...\n',datestr(datetime));

%% Upload OCT2Hitology ML model

p = awsModifyPathForCompetability([currentFileFolder '/../31 NN Model']);
awsEC2UploadDataToInstance(ec2Instance,p,'~/ml/oct2hist_model/'); %Copy

%% Capture information user will need & disconnect from instance

% Capture information to keep for reconnect
dns = ec2Instance.dns;
id = ec2Instance.id;

% Disconnect
awsEC2TemporarilyDisconnectFromInstance(ec2Instance);

% Print information
instructions = sprintf('id_=''%s''; dns_=''%s''; origPath_ =''%s''; scriptEndML;',id,dns,origPath);
disp('Next steps: ');
disp(instructions);
