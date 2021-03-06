function spfPlotTopView(varargin)
%This function plots top view of Single Plane Fit
%INPUTS:
%   singlePlaneFits - single plane fit(s) structure as generated by fdlnEstimateUVHSinglePlane. 
%       If this is an array of plane structures will plot them one by one.

%       Leave empty to draw just 
%   hLinePositions, vLinePositions - as defined by octVolumeJson.photobleach
%Additional Parameters:
%   lineLength - length of each slide (default is 2mm)
%   enfaceViewImage - an enface overview image (OCT)
%   enfaceViewImageXLim,enfaceViewImageYLim - [limStart, limEnd]. If no limit is provide, will assume size to be 1 by 1 mm. Recomendation:
%           enfaceViewImageXLim = [min(octVolumeJson.overview.xCenters) max(octVolumeJson.overview.xCenters)] + octVolumeJson.overview.range*[-1/2 1/2]
%   planeULim - n by 2 (n as number of planes) for each of the planes what u start and end will be. If non are set will draw a lineLength slide. 
%   planeNames - cell array with names of planes to be presented
%   theDot - x,y position of the dot (if exist)
%   isStartCuttingFromDotSide - 1 for start cutting from dot side, -1
%       otherwise. Set to empty if you would like not to draw it.

%% Input Parameters
p = inputParser;
addRequired(p,'singlePlaneFits');
addRequired(p,'hLinePositions');
addRequired(p,'vLinePositions');

%General parameters
addParameter(p,'lineLength',2,@isnumeric);
addParameter(p,'enfaceViewImage',[]);
addParameter(p,'enfaceViewImageXLim',[1 1]);
addParameter(p,'enfaceViewImageYLim',[1 1]);
addParameter(p,'planeULim',[]);
addParameter(p,'planeNames',{});
addParameter(p,'theDot',[]);
addParameter(p,'isStartCuttingFromDotSide',[]);

parse(p,varargin{:});

in = p.Results;
singlePlaneFits = in.singlePlaneFits;
hLinePositions = in.hLinePositions;
vLinePositions = in.vLinePositions;
lineLength = in.lineLength;

isPlotEnface = ~isempty(in.enfaceViewImage);
isPlotSinglePlane = length(singlePlaneFits) == 1;

%% Remove empty data
if ~iscell(singlePlaneFits)
    singlePlaneFits = {singlePlaneFits};
end
isFitEmpty = cellfun(@isempty,singlePlaneFits);
singlePlaneFits(isFitEmpty) = [];

if length(in.planeNames) == length(isFitEmpty)
    in.planeNames(isFitEmpty) = [];
end

%% Cleanup figure
delete(get(gca,'Children')); %Clear prev text (if exist)

%% Plot enface overview
if (isPlotEnface)
    imagesc(in.enfaceViewImageXLim,in.enfaceViewImageYLim,in.enfaceViewImage);
    colormap gray;
    hold on;
    monoColor = 'w';
else
    monoColor = 'k';
end

%% Plot Photobleached lines
mm = [-1 1]*(lineLength/2);
for i=1:length(vLinePositions)
    c = vLinePositions(i);
    
    h = plot([c c],mm,'-','LineWidth',2);
    if (~isPlotSinglePlane)
        set(h,'color',monoColor);
    end
    if (i==1)
        hold on;
    end
end
for i=1:length(hLinePositions)
    c = hLinePositions(i);
    
    h = plot(mm,[c c],'-','LineWidth',2);
    if (~isPlotSinglePlane)
        set(h,'color',monoColor);
    end
end

%% Compute Histology Plane Start & Finish
planesX = zeros(2,length(singlePlaneFits)); %(start&end,n)
planesY = zeros(2,length(singlePlaneFits)); %(start&end,n)

for i=1:length(singlePlaneFits)
    
    %Extract data
    sp = singlePlaneFits{i};
    
    %Decide if we use u or random points on the plane
    if(~isempty(in.planeULim))
        %Use u given
        x = polyval(sp.xFunctionOfU,in.planeULim);
        planesX(:,i) = x;
        planesY(:,i) = sp.m*x+sp.n;
    else
        %Use mid point
        c = mean([sp.xIntercept_mm sp.yIntercept_mm],2);
        slopeV = [1; sp.m];
        slopeV = slopeV/norm(slopeV);

        planesX(:,i) = c(1)+slopeV(1)*lineLength/2*[1 -1];
        planesY(:,i) = c(2)+slopeV(2)*lineLength/2*[1 -1];
    end
end

%% Plot Histology plane
if ~isempty(singlePlaneFits)
    h = plot(planesX,planesY,'LineWidth',2); %Plot the planes

    if     ( isPlotEnface &&  isPlotSinglePlane)
        set(h, {'color'}, {'w'}); 
    elseif (~isPlotEnface &&  isPlotSinglePlane)
        set(h, {'color'}, {'k'}); 
    elseif (isPlotEnface &&  ~isPlotSinglePlane)
        set(h, {'color'}, num2cell(winter(size(planesX,2)),2)); %Set multiple colors
    else
        set(h, {'color'}, num2cell(winter(size(planesX,2)),2)); %Set multiple colors
    end
end

%Plot edges
if (isPlotSinglePlane && ~isempty(in.planeULim))
    plot(planesX(1),planesY(1),'o','Color',monoColor);
    text(planesX(1),planesY(1),sprintf('u=%.0f',in.planeULim(1)),'Color',monoColor);
    text(planesX(end),planesY(end),sprintf('u=%.0f',in.planeULim(end)),'Color',monoColor);
end

%% Write planes names
if ~isempty(in.planeNames)
    
    v = [mean(diff(mean(planesX,1)));mean(diff(mean(planesY,1)))];
    v = v/norm(v)*0.2; 
    
    for i = unique([1 size(planesX,2)])
        d = (i==1)*2-1;
        if (abs(singlePlaneFits{i}.rotation_deg)>90)
            %Line arrangement is filpt, so add 180[deg]
            ang = -(singlePlaneFits{i}.rotation_deg+180);
        else
            ang = -singlePlaneFits{i}.rotation_deg;
        end
        text(mean(planesX(:,i))-v(1)*d,mean(planesY(:,i))-v(2)*d,strrep(in.planeNames{i},'_',' '), ...
            'Rotation',ang,'HorizontalAlignment','center','VerticalAlignment','middle','Color',monoColor);
    end
end

%% Plot the dot
theDot = in.theDot;
if (~isempty(theDot))
    theDot = theDot/norm(theDot)*lineLength/2;
    plot(theDot(1),theDot(2),'bo','MarkerSize',10,'MarkerFaceColor','b');
end

%% Plot Where User Requested to cut (direction)
isStartCuttingFromDotSide = in.isStartCuttingFromDotSide;
if ~isempty(theDot) && ~isempty(isStartCuttingFromDotSide)
    x = theDot(1) * [1.3 0.6]*isStartCuttingFromDotSide;
    y = theDot(2) * [1.3 0.6]*isStartCuttingFromDotSide;
    drawArrow = @(x,y) quiver( x(1),y(1),x(2)-x(1),y(2)-y(1),0,...
        'MaxHeadSize',50,'LineWidth',2);
    drawArrow(x,y);
end

%% Finalize figure
axis equal;
axis ij;
hold off;
grid on;
xlabel('x[mm]');
ylabel('y[mm]');