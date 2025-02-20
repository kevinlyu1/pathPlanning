%clear all;
%close all;
% constants
% uavSpeed = 1;
% ugvSpeed = uavSpeed * 0.5;

% creating the points for the problem
% numOfPoints = numPointsInit; % you can use any number, but the problem size scales as N^2
uavSpeed = 1;
% ugvSpeed = uavSpeed/UGVSpeed;
ugvSpeed = 1/8;
xPoints = GLNSx';
yPoints = GLNSy';
xyPoints = [xPoints';yPoints'];
numOfPoints = numel(xPoints);
noDepotXY = xyPoints(:,1:numOfPoints-1);
sites = 1:numOfPoints-1;
figure();
plot(xPoints,yPoints,'*b')
hold off

numOfSites = numPointsInit;
uavSites = zeros(1,numOfSites);
for i = 1:numOfSites
    uavSites(i) = i;
end
corrdinatesOfSitesTemp = [GLNSx(1:end-1); GLNSy(1:end-1)];
ugvSites = [];
typeTwoEdges = zeros(2,1);

if GLNSSolution(1)>length(v_Type)    
    GLNSSolution = GLNSSolution(2:end);
elseif GLNSSolution(end)>length(v_Type)
    GLNSSolution = GLNSSolution(1:end-1);
else
    disp('error')
end

count = 1;
count1 = 1;
for a = 1:numel(GLNSSolution)-1
    temp = v_Type(GLNSSolution(a), GLNSSolution(a+1));
    if temp == 1
        
    elseif temp == 2
        ugvSites(end+1) = a;
        ugvSites(end+1) = a+1;
        typeTwoEdges(1, count) = a;
        typeTwoEdges(2, count) = a+1;
        typeTwoEdgesBasic(1,count) = count1;
        count1 = count1+1;
        typeTwoEdgesBasic(2,count) = count1;
        count1 = count1+1;
        count = count + 1;
    elseif temp == 3
        ugvSites(end+1) = a+1;
    else
        fprintf('error')
    end
end
ugvSites(end+1) = numel(uavSites);
% creating the initial constraints of the problem intlinprog
idxs = nchoosek(1:numel(ugvSites),2); % all possible paths
dist = hypot(yPoints(idxs(:,1)) - yPoints(idxs(:,2)), xPoints(idxs(:,1)) - xPoints(idxs(:,2))); % gets distances for all combinations in idxs
lendist = numel(dist);
edgeCostMatrix = [idxs, dist];

% optimization function min(-yij)
f = ones(lendist,1)*-1;
intcon = 1:lendist; % which values are integers(all values left out are not specifically integers)

% creating upper and lower bound for problem (based on environment size)
lb = zeros(lendist,1);  % lower bound for intlinprog (based off of the lower bound for xPoints & yPoints)
ub = ones(lendist,1)*200;   % upper bound for intlinprog (based off of the upper bound for xPoints & yPoints)

A1 = spalloc(0,lendist,0); % Allocate a sparse linear inequality constraint matrix
% b1 = ones(numOfPoints-1,1);
% all outgoing edges have to add up to <=1
for j = 1:numOfPoints           % creating less than or equal to constraints
    for i = 1:lendist           % leaving a node has to be less than or equal to one
        yi = idxs(i,1);
        if yi == j
            A1(j, i) = 1;
        end
    end
end
A1 = full(A1);
b1 = ones(numel(A1(:,1)),1);
[A1, b1, ~, ~] = removeRowCol(A1, b1);

A2 = spalloc(0,lendist,0);
% b2 = ones(numOfPoints,1);
% all incoming edges have to add up to <=1
for j = 2:numOfPoints       % entering a node has to be less than or equal to one
    for i = 1:lendist
        yj = idxs(i,2);
        if yj == j
            A2(j, i) = 1;
        end
    end
end
A2 = full(A2);
b2 = ones(numel(A2(:,1)),1);
[A2, b2, ~, ~] = removeRowCol(A2, b2);

A = [A1;A2]; % combining A & B
b = [b1;b2];

% allowing every site to go to the deopt with no cost
for i = 1:lendist
    if idxs(i,2) == numOfPoints
        dist(i) = 0;
    end
end

[tUGVPrior] = createTugv(numel(ugvSites), xyPoints, ugvSites, 1);
[tUAV] = createTuav(uavSites, ugvSites, xyPoints, numOfSites);
tUGV = tUGVPrior / ugvSpeed;
location = [];                  % creating constraints
finalTotal = [];
for i = 1:lendist
    fromNode = idxs(i,1);
    toNode = idxs(i, 2);
    if (fromNode > numOfPoints-1) || (toNode > numOfPoints-1)
        location(i,i) = 1;
        finalTotal(i) = 0;
    else
        if tUGV(fromNode, toNode) > tUAV(fromNode, toNode)
            location(i,i) = 1;
            finalTotal(i) = 0;
        else
            location(i,i) = 1;
            finalTotal(i) = 1;
        end
    end
end

locationOfMembers = ismember(idxs(:,1), typeTwoEdgesBasic(1,:));    % making it so only type two can leave the nodes
location(locationOfMembers, :) = 0;
finalTotal(:,locationOfMembers) = 0;

locationOfMembers = ismember(idxs(:,2), typeTwoEdgesBasic(2,:));    % making it so only type two can enter the nodes
location(locationOfMembers, :) = 0;
finalTotal(:,locationOfMembers) = 0;

[~,m] = size(typeTwoEdges);
for i = 1:m                     % adding type two edges, but need to make sure you force them not just allow them to be used
    temp1 = find(ugvSites == typeTwoEdges(1,i));
    temp2 = find(ugvSites == typeTwoEdges(2,i));
    temp3 = ismember(idxs, [temp1,temp2]);
    for j = 1:length(idxs)
        if temp3(j,1)+temp3(j,2) == 2
            temp4 = j;
            break
        end
    end
    temp5 = find(location(:, temp4) == 1);
    if finalTotal(temp5) == 0
        finalTotal(temp5) = 1;
    else
        location(end+1,temp4) = 1;
        finalTotal(end+1) = 1;
    end
end


removeMatrix = [];
for i = 1:lendist
    if finalTotal(i) == 1
        removeMatrix(end+1) = i;
    end
end



locationRemoved = location;
locationRemoved(removeMatrix,:) = [];
finalTotalRemoved = finalTotal;
finalTotalRemoved(:,removeMatrix) = [];

opts = optimoptions('intlinprog','Display','off');  % implements the constraints
[x_tsp,costopt,exitflag,output] = intlinprog(f,intcon, A, b',locationRemoved,finalTotalRemoved,lb,ub,opts)

hold on
segments = find(x_tsp); % Get indices of lines on optimal path
lh = zeros(numOfPoints,1); % Use to store handles to lines on plot
% n = 0;
% m = 0;
[n,m] = size(idxs);
idxsInUGVPoints = zeros(n,m);
for i = 1:numel(idxs)
    idxsInUGVPoints(i) = ugvSites(idxs(i));
end

lh = updateSalesmanPlot(lh,x_tsp,idxsInUGVPoints,xPoints,yPoints);
title('Solution with Subtours');

% numtours = length(tours); % number of subtours
% fprintf('# of subtours: %d\n',numtours);

title('Solution with Subtours Eliminated');
hold off

disp(output.absolutegap);
