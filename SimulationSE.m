function SimulationSE(initial)
%ZMW 11/29/2014

global visual;
global eye;
global step;
global vars;
global color;
global data;
global toplexon;
global counter;

try
    
    
    [visual,eye,vars,color,data] = deal([]);
    
    %***** set parameters ******
    
    
    eye.side = 2;%Tracked eye (L = 1, R = 2)
    eye.fixating=0;%initialize the fixation 0=not 1=is fixated
    
    
    counter.fix1=0;
    counter.fix2=0;
    counter.choice=0;

    
    visual.baseRect = [0 0 80 300];% Make a base Rect of 80 by 300 pixels
    visual.outline = [0 0 100 320];% outline square for feedback
    
    % initialize variables for later analysis
    vars.strobesOn  = 1;%Send strobes to Plexon (Yes = 1, No = 0)
    vars.trial=[];%trial number for stamping all other varialbles
    vars.daysTrials = 0;
    vars.rt=[];%reaction time
    vars.leftStd=[];%standard offer is on the 1=left 0=right
    vars.stdPrst=[];%standard offer that is presented 0=0.125 1=0.175
    vars.experience=[];%it is an experience trial or not: 1=experience trial, 0=stimuli trial
    vars.rewardPrst=[];%reward size presented/experienced: 1=0.075,2,3,4,5=0.250
    vars.choseLeft=[];%chose which side: 1=left 0=right
    vars.experience=[];
    vars.choice=[];
    vars.alternative=[];
    vars.stiSize = [.075; .1; .150; .200; .250]; %5 stimuli reward sizes 75ml to 250ml
    vars.stdSize = [0.150; 0.175; 0.200]; %3 standard reward size
    
    %     vars.expSize = [.075; .1;.150; ]; %3 esperience reward sizes 75ml to 250ml
    %     vars.expDurations=[0.055 0.075 0.097 0.124 0.146];

    %     vars.rewardDurations=[0.055 0.075 0.097 0.124 0.146]; 
    
    vars.rewardDurations=[0.065 0.085 0.115 0.145 0.170];% in Enterprise juicer 1: Water
    
    %     vars.stdDuration=[0.097 0.115 0.146];% in batcave
    vars.stdDuration=[0.115 0.130 0.145];% in enterprise
    % got from autoreward juicer recalibration in an excel file
    vars.rect = 0.5; %Time: offer presentation for 500ms
    vars.minFixDot  = .2;%Time: fixation min for fixation dot
    vars.minFixCho = .2;%Time: fixation min for choice
    vars.consume = .75;%Time: duration for experiencing/looking at a offer
    vars.feedback   = .3;%Time: feedback
    vars.reward     = .75;%Time: duration for consuming the chosen reward
    vars.ITI        = 1;%Time: intertrial interval
    vars.StartTime=0;
    vars.EndTime=0;
    vars.TotalRunTime=0;
    
    %     vars.randSerial= randSerial(500);
    
    
    color.chosen    = [255  0  255];  %Chosen option outline color Magenta
    color.rectColor      = [255  0    0;     %Red 75
        225  225  0;     %Yellow 100
        0    0    255;   %Blue 150
        0    255  0;     %Green 200
        0    255  255];  %Cyan 250
    
    
    %***** get screen parameters *****
    
    % % Get the screen numbers
    % screens = Screen('Screens');
    % % Draw to the external screen if avaliable
    % screenNumber = max(screens);
    % Define white, black, and  grey
    color.white = WhiteIndex(0);
    color.black = BlackIndex(0);
    color.grey  = color.white/2;
    
    % Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure they are
    % loaded and ready when we need them - without delays in the wrong
    % moment:
    KbCheck;
    WaitSecs(0.05);
    GetSecs;
    
    
    %***** Set up ******
    [vars.filename, foldername] = createFile('/Data/Simulation1', 'SimSE', initial);
    
    vars.daysTrials = countDayTrials('/Data/Simulation1', foldername); %Count day's cumulative trials
    
    % designate where to desplay the stimuli
    visual.screen = setupEyelink; %Connect to Eyelink
    
    %Initialize strobes
    toplexon = strobeInit();
    
    
    % Open an on screen window
    [visual.window, windowRect] = Screen('OpenWindow', visual.screen, color.black);
    ShowCursor;
    
    % Get the size of the on screen window
    [screenXpixels, screenYpixels] = Screen('WindowSize', visual.window);
    
    % Query the frame duration
    visual.ifi = Screen('GetFlipInterval', visual.window);
    
    % Numer of frames to wait when specifying good timing
    visual.waitframes = 1;
    
    % Get the centre coordinate of the window
    [visual.xCenter, visual.yCenter] = RectCenter(windowRect);
    
    % Screen X positions of our three rectangles
    visual.squareXpos = [screenXpixels * 0.25 screenXpixels * 0.75];
    
    % read in the images for standard offer stimuli
    visual.theImage1 = imread('Yosemite1.jpg');
    visual.theImage2 = imread('Yosemite2.jpg');
    visual.theImage3 = imread('Yosemite3.jpg');
    
    
    % Maximum priority level
    topPriorityLevel = MaxPriority(visual.window);
    Priority(topPriorityLevel);
    
    % #################
    % toplexon = strobeInit(); %Initialize strobes
    
    
    %***** Ask to start *******
    go = 0;
    step=10;
    disp('Right Arrow to start');
    vars.StartTime=GetSecs;
    gokey=KbName('RightArrow');
    nokey=KbName('ESCAPE');
    while(go == 0)
        [keyIsDown,~,keyCode] = KbCheck;
        if keyCode(gokey)
            go = 1;
            if vars.strobesOn==1, toplexon(8001);end %strobe: start experiment
        elseif keyCode(nokey)
            if vars.strobesOn==1, toplexon(8002);end %strobe: escaped from experiment
            go = -1;
            
        end
    end
    while keyIsDown
        [keyIsDown,~,~] = KbCheck;
    end
    home
    
    
    %***** Run trials *******
    while(go == 1)
        
        switch step,
            case 1, step_fixation1;
                
            case 21, step_offerCueG;
                
            case 22, step_offerCueW;
                
            case 31, step_colorRect;
                
            case 32, step_experience;
                
                %case 4, step_fixation2;
                
            case 5, step_standard;
                
            case 6, step_fixation3;
                
            case 71, step_choice1;
                
            case 72, step_choice2;
                
            case 81, step_feedback1;
                
            case 82, step_feedback2;
                
            case 9, step_reward;
                
            case 10,step_ITI;
                
        end
        
        go = keyCapture;
        
    end % of while-go
    sca
    
catch
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    % output the error message that describe the error
    
    psychrethrow(psychlasterror);
end

end


% PsychDebugWindowConfiguration(0,0.5);   % online debugging (Shraddha)


%step10
function step_ITI
global step; global vars; global toplexon;global counter;

if vars.strobesOn==1, toplexon(6010);end %strobe: ITI


WaitSecs(vars.ITI);


% update the trial number for this trial
if isempty(vars.trial)
    vars.trial=1;
else
    vars.trial=vars.trial+1;
end


if(vars.trial ~= (vars.trial + vars.daysTrials))
    disp(['Current # ' num2str(vars.trial) '/' 'Cumulative #' num2str(vars.trial + vars.daysTrials)]);
else
    disp(['Trial #' num2str(vars.trial)]);
end

counter.fix1=0;
counter.fix2=0;
counter.choice=0;

step=1;



end

%step1
function step_fixation1
global color; global step;  global eye; global visual; global vars; global toplexon; global counter;

counter.fix1=counter.fix1+1;
%***** Set screen *******

% prepare the fixation rect with the same color of background
fixSquare=CenterRectOnPointd([0 0 200 200], visual.xCenter, visual.yCenter);

Screen('FillRect', visual.window, color.black, fixSquare);

% Draw a white dot where the mouse is
Screen('DrawDots', visual.window, [visual.xCenter, visual.yCenter], 15, color.white, [], 2);

% Flip to the screen
Screen('Flip', visual.window);

if counter.fix1==1
    if vars.strobesOn==1, toplexon(6020);end % strobe: fixation 1 on screen
end


%***** Check eye position *******
e = Eyelink('newestfloatsample');
% e.gx(eye.side)
% e.gy(eye.side)
inside=IsInRect(e.gx(eye.side), e.gy(eye.side), fixSquare);
if inside==1
    if eye.fixating ~= 1 % this was initialized as 0
        eye.fixtime = GetSecs;
        eye.fixating = 1;
    elseif GetSecs >= (vars.minFixDot + eye.fixtime)
        
        if vars.strobesOn==1, toplexon(6001);end %strobe: fixiated on 1 fix dot   
        vars.randDespExp=rand(1);
        if vars.randDespExp < 0.5
            step = 22;
            vars.experience=1;
        else
            step = 21;
            vars.experience=0;
        end
        
        eye.fixating = 0;
    end
elseif eye.fixating == 1
    eye.fixating = 0;
end

end

%step 21
function step_offerCueG % present the gray cue for stimulus trials
global color; global visual; global vars; global step; global toplexon;

rNum=rand(1);

if rNum<=.5
    visual.recPosition=visual.squareXpos(1);
    visual.stdPosition=visual.squareXpos(2);
    vars.leftStd=0;
else
    visual.recPosition=visual.squareXpos(2);
    visual.stdPosition=visual.squareXpos(1);
    vars.leftStd=1;
end

visual.thisRect=CenterRectOnPointd(visual.baseRect, visual.recPosition, visual.yCenter);

% Sync us and get a time stamp
vbl = Screen('Flip', visual.window);
% Length of time and number of frames we will use for each drawing test
numSecs = vars.rect;
numFrames = round(numSecs / visual.ifi);
frame=1;

if vars.strobesOn==1, toplexon(6030);end %strobe: offerCueGray on screen

while frame <= numFrames
    
    % Draw the rect to the screen
    % Screen('FillRect', windowPtr [,color] [,rect] )
    
    Screen('FillRect', visual.window, color.grey, visual.thisRect);
    
    
    % Flip to the screen
    vbl  = Screen('Flip', visual.window, vbl + (visual.waitframes - 0.5) * visual.ifi);
    
    frame=frame+1;
end



step =31;
end

%step 22
function step_offerCueW  % present the white cue for experience trials
global color; global visual; global vars; global step; global toplexon;

rNum=rand(1);

if rNum<=.5
    visual.recPosition=visual.squareXpos(1);
    visual.stdPosition=visual.squareXpos(2);
    vars.leftStd=0;
else
    visual.recPosition=visual.squareXpos(2);
    visual.stdPosition=visual.squareXpos(1);
    vars.leftStd=1;
end

visual.thisRect=CenterRectOnPointd(visual.baseRect, visual.recPosition, visual.yCenter);

% Sync us and get a time stamp
vbl = Screen('Flip', visual.window);
% Length of time and number of frames we will use for each drawing test
numSecs = vars.rect;
numFrames = round(numSecs / visual.ifi);
frame=1;

if vars.strobesOn==1, toplexon(6030);end %strobe: offerCueWhite on screen

while frame <= numFrames
    
    % Draw the rect to the screen
    % Screen('FillRect', windowPtr [,color] [,rect] )
    
    Screen('FillRect', visual.window, color.white, visual.thisRect);
    
    
    % Flip to the screen
    vbl  = Screen('Flip', visual.window, vbl + (visual.waitframes - 0.5) * visual.ifi);
    
    frame=frame+1;
end



step =32;
end

%step 31 stimulus
function step_colorRect
global step; global color; global visual; global vars; global toplexon;

visual.randRect=randi([1,5],1);
vars.rewardPrst=visual.randRect;

% Sync us and get a time stamp
vbl = Screen('Flip', visual.window);
% Length of time and number of frames we will use for each drawing test
numSecs = vars.consume;
numFrames = round(numSecs / visual.ifi);
frame=1;

if vars.strobesOn==1, toplexon(6040);end %strobe: stimuli rectangle on screen

while frame <= numFrames
    
    % Draw the rect to the screen
    % Screen('FillRect', windowPtr [,color] [,rect] )
    
    Screen('FillRect', visual.window, color.rectColor(visual.randRect,:), visual.thisRect);
    
    
    % Flip to the screen
    vbl  = Screen('Flip', visual.window, vbl + (visual.waitframes - 0.5) * visual.ifi);
    
    frame=frame+1;
end


step=5;
end

%step 32 experience
function step_experience
global step; global color; global visual; global vars; global toplexon;

visual.randRect=randi([1,5],1);
vars.rewardPrst=visual.randRect;

Screen('FillRect', visual.window, color.black);

if vars.strobesOn==1, toplexon(6040);end %strobe: experience reward size

% Flip to the screen
Screen('Flip', visual.window);




reward(vars.rewardDurations(visual.randRect));

disp('White bar value: ');
ValDisp=visual.randRect;
disp(ValDisp);

WaitSecs(vars.consume);

step=5;
end

%step5
function step_standard
global step; global visual; global vars; global toplexon;

% Sync us and get a time stamp
vbl = Screen('Flip', visual.window);
% Length of time and number of frames we will use for each drawing test
numSecs = vars.rect;
numFrames = round(numSecs / visual.ifi);

rstd=randi([1,3],1);
switch rstd
    case 1
        visual.imageTexture = Screen('MakeTexture', visual.window, visual.theImage1);
        vars.stdPrst=10;
        vars.stdCho=1;
    case 2
        visual.imageTexture = Screen('MakeTexture', visual.window, visual.theImage2);
        vars.stdPrst=20;
        vars.stdCho=2;
    case 3
        visual.imageTexture = Screen('MakeTexture', visual.window, visual.theImage3);
        vars.stdPrst=30;
        vars.stdCho=3;
end

visual.stdRect=CenterRectOnPointd(visual.baseRect, visual.stdPosition, visual.yCenter);

if vars.strobesOn==1, toplexon(6050);end %strobe: std offer on screen

for frame = 1:numFrames
    
    % Draw the rect to the screen
    % Screen('FillRect', windowPtr [,color] [,rect] )
    
    Screen('DrawTexture', visual.window, visual.imageTexture, [], visual.stdRect, 0);
    
    
    % Flip to the screen
    vbl  = Screen('Flip', visual.window, vbl + (visual.waitframes - 0.5) * visual.ifi);
end

step=6;
end

%step6
function step_fixation3
global color; global step; global eye; global visual; global vars; global toplexon; global counter;

%***** Set screen *******
counter.fix2=counter.fix2+1;

% prepare the fixation rect with the same color of background
fixSquare=CenterRectOnPointd([0 0 200 200], visual.xCenter, visual.yCenter);

% Draw a white dot where the mouse is
Screen('DrawDots', visual.window, [visual.xCenter, visual.yCenter], 15, color.white, [], 2);

% Flip to the screen
Screen('Flip', visual.window);

if counter.fix2==1
    if vars.strobesOn==1, toplexon(6060);end %strobe: fixation2 on screen
end


%***** Check eye position *******
e = Eyelink('newestfloatsample');
inside = IsInRect(e.gx(eye.side), e.gy(eye.side), fixSquare);
if inside==1
    if eye.fixating ~= 1 % this was initialized as 0
        eye.fixtime = GetSecs;
        eye.fixating = 1;
    elseif GetSecs >= (vars.minFixDot + eye.fixtime)
        if vars.strobesOn==1, toplexon(6002);end %strobe: fixiated on fix dot 2

        if vars.experience==1
            step = 72;
        else
            step = 71;
        end
        % vars.choiceStart = GetSecs;
        eye.fixating = 0;
        
    end
elseif eye.fixating == 1
    eye.fixating = 0;
end
end

%step 71
function step_choice1
global vars; global color; global step; global onset; global eye; global visual; global toplexon; global counter;

%***** Set screen *******
counter.choice=counter.choice+1;

% Draw the fixation window that's bigger than the rect itself
% same color as background
fixRectL=CenterRectOnPointd([0 0 130 350], visual.squareXpos(1), visual.yCenter);
Screen('FillRect', visual.window, color.black, fixRectL);

fixRectR=CenterRectOnPointd([0 0 130 350], visual.squareXpos(2), visual.yCenter);
Screen('FillRect', visual.window, color.black, fixRectR);

% draw the option rects
Screen('FillRect', visual.window, color.grey , visual.thisRect);

Screen('DrawTexture', visual.window, visual.imageTexture, [], visual.stdRect, 0);

% Flip to the screen
Screen('Flip', visual.window);

if counter.choice==1
    if vars.strobesOn==1, toplexon(6070);end %strobe: choice b/t stimuli & std
end


t0=GetSecs;

%***** Check eye position *****
e = Eyelink('newestfloatsample');
insideL = IsInRect(e.gx(eye.side), e.gy(eye.side), fixRectL);
insideR = IsInRect(e.gx(eye.side), e.gy(eye.side), fixRectR);

if insideL==1
    if eye.fixating ~= 1
        eye.fixtime = GetSecs;    
        eye.fixating = 1;
    elseif GetSecs >= (vars.minFixCho + eye.fixtime)
        if vars.strobesOn==1, toplexon(6003);end %strobe: fixiated on choice
        tEnd=GetSecs;
        vars.rt=tEnd-t0;
        vars.choseLeft= 1;
        visual.fbPosition=visual.squareXpos(1);
        step = 81;
        eye.fixating = 0;
        
    end
elseif eye.fixating == 1
    eye.fixating = 0;
end
if insideR==1
    if eye.fixating ~= 2
        eye.fixtime = GetSecs; 
        eye.fixating = 2;
        onset = true;
    elseif GetSecs >= (vars.minFixCho + eye.fixtime)
        if vars.strobesOn==1, toplexon(6003);end %strobe: fixiated on choice
        tEnd=GetSecs;
        vars.rt=tEnd-t0;
        vars.choseLeft= 0;
        visual.fbPosition=visual.squareXpos(2);
        step = 81;
        eye.fixating = 0;
        
    end
elseif eye.fixating == 2
    eye.fixating = 0;
    
end

end

%step 72
function step_choice2
global vars; global color; global step; global onset; global eye; global visual; global toplexon; global counter;

%***** Set screen *******
counter.choice=counter.choice+1;

% Draw the fixation window that's bigger than the rect itself
% same color as background
fixRectL=CenterRectOnPointd([0 0 130 350], visual.squareXpos(1), visual.yCenter);
Screen('FillRect', visual.window, color.black, fixRectL);

fixRectR=CenterRectOnPointd([0 0 130 350], visual.squareXpos(2), visual.yCenter);
Screen('FillRect', visual.window, color.black, fixRectR);

% draw the option rects
Screen('FillRect', visual.window, color.white , visual.thisRect);

Screen('DrawTexture', visual.window, visual.imageTexture, [], visual.stdRect, 0);

% Flip to the screen
Screen('Flip', visual.window);

if counter.choice==1
    if vars.strobesOn==1, toplexon(6070);end %strobe: choice b/t stimuli & std
end


t0=GetSecs;

%***** Check eye position *****
e = Eyelink('newestfloatsample');
insideL = IsInRect(e.gx(eye.side), e.gy(eye.side), fixRectL);
insideR = IsInRect(e.gx(eye.side), e.gy(eye.side), fixRectR);

if insideL==1
    if eye.fixating ~= 1
        eye.fixtime = GetSecs;
        eye.fixating = 1;
    elseif GetSecs >= (vars.minFixCho + eye.fixtime)
        if vars.strobesOn==1, toplexon(6003);end %strobe: fixiated on choice
        tEnd=GetSecs;
        vars.rt=tEnd-t0;
        vars.choseLeft= 1;
        visual.fbPosition=visual.squareXpos(1);
        step = 82;
        eye.fixating = 0;
    end
elseif eye.fixating == 1
    eye.fixating = 0;
end
if insideR==1
    if eye.fixating ~= 2
        eye.fixtime = GetSecs;
        eye.fixating = 2;
        onset = true;
    elseif GetSecs >= (vars.minFixCho + eye.fixtime)
        if vars.strobesOn==1, toplexon(6003);end %strobe: fixiated on 1 fix dot
        tEnd=GetSecs;
        vars.rt=tEnd-t0;
        vars.choseLeft= 0;
        visual.fbPosition=visual.squareXpos(2);
        step = 82;
        eye.fixating = 0;
        
    end
elseif eye.fixating == 2
    eye.fixating = 0;
    
end

end

%step 81
function step_feedback1
global visual; global color; global vars; global step; global toplexon;


fbRect=CenterRectOnPointd(visual.outline, visual.fbPosition, visual.yCenter);

% Sync us and get a time stamp
vbl = Screen('Flip', visual.window);
% Length of time and number of frames we will use for each drawing test
numSecs = vars.feedback;
numFrames = round(numSecs / visual.ifi);

if vars.strobesOn==1, toplexon(6080);end %strobe: feedback b/t stimuli & std

for frame = 1:numFrames
    
    % draw the feedback rect
    Screen('FillRect', visual.window, color.chosen, fbRect);
    
    % draw the options
    Screen('FillRect', visual.window, color.grey, visual.thisRect);
    
    Screen('DrawTexture', visual.window, visual.imageTexture, [], visual.stdRect, 0);
    
    
    % Flip to the screen
    vbl  = Screen('Flip', visual.window, vbl + (visual.waitframes - 0.5) * visual.ifi);
end
step=9;
end

%step 82
function step_feedback2
global visual; global color; global vars; global step; global toplexon;


fbRect=CenterRectOnPointd(visual.outline, visual.fbPosition, visual.yCenter);

% Sync us and get a time stamp
vbl = Screen('Flip', visual.window);
% Length of time and number of frames we will use for each drawing test
numSecs = vars.feedback;
numFrames = round(numSecs / visual.ifi);

if vars.strobesOn==1, toplexon(6080);end %strobe: choice b/t stimuli & std

for frame = 1:numFrames
    
    % draw the feedback rect
    Screen('FillRect', visual.window, color.chosen, fbRect);
    
    % draw the options
    Screen('FillRect', visual.window, color.white, visual.thisRect);
    
    Screen('DrawTexture', visual.window, visual.imageTexture, [], visual.stdRect, 0);
    
    
    % Flip to the screen
    vbl  = Screen('Flip', visual.window, vbl + (visual.waitframes - 0.5) * visual.ifi);
end
step=9;
end

%step9
function step_reward
global data; global step; global vars; global visual; global color; global toplexon;
% t0=GetSecs;
Screen('FillRect', visual.window, color.black);

if vars.strobesOn==1, toplexon(6090);end %strobe: reward delivery

% Flip to the screen
Screen('Flip', visual.window);


if vars.leftStd==1
    if vars.choseLeft==0
        reward(vars.rewardDurations(visual.randRect));
        vars.choice=visual.randRect;
        vars.alternative=vars.stdPrst;
    elseif vars.choseLeft==1
        reward(vars.stdDuration(vars.stdCho));
        vars.choice=vars.stdPrst;
        vars.alternative=visual.randRect;
    end
elseif vars.leftStd==0
    if vars.choseLeft==0
        reward(vars.stdDuration(vars.stdCho));
        vars.choice=vars.stdPrst;
        vars.alternative=visual.randRect;
    elseif vars.choseLeft==1
        reward(vars.rewardDurations(visual.randRect));
        vars.choice=visual.randRect;
        vars.alternative=vars.stdPrst;
    end
end

WaitSecs(vars.reward);
% tEnd=GetSecs;
% rewardDuration=tEnd-t0;

if vars.strobesOn==1
    toplexon(vars.trial);
    toplexon(vars.stdPrst+2000);
    toplexon(vars.rewardPrst+2100);
    toplexon(vars.choice+3000);
    toplexon(vars.alternative+4000);
    toplexon(vars.experience+5000);
    toplexon(vars.leftStd+7000);
    toplexon(vars.choseLeft+9000);
    toplexon(vars.daysTrials+vars.trial);
end

data{vars.trial} = vars;

eval(['save ' vars.filename ' data']);

step = 10;
end


function go = keyCapture
global step; global vars;
go = 1;
stopkey=KbName('ESCAPE');
pause=KbName('LeftArrow');
[keyIsDown,~,keyCode] = KbCheck;
if keyCode(stopkey)
    vars.EndTime=GetSecs;
    vars.TotalRunTime=(vars.EndTime-vars.StartTime)/60;
    disp('Total Time of Running in minutes')
    disp(vars.TotalRunTime)
    go = 0;
elseif keyCode(pause) && step ~= 10
    step = 10;
elseif keyCode(pause) && step == 10
    step = 1;
    
end
while keyIsDown
    [keyIsDown,~,~] = KbCheck;
end
end


function reward(rewardduration)

if(rewardduration > 0)
    daq=DaqDeviceIndex;
    %     disp(sprintf('Reward time: %4.2fs', rewardduration));
    if(rewardduration ~= 0)
        DaqAOut(daq,0,.6); %(device,channel,voltage)
        starttime=GetSecs;
        while (GetSecs-starttime)<(rewardduration);
        end;
        DaqAOut(daq,0,0);
        StopJuicer;
    end
end
end% 11/23/11  MAM, TB



function toplexon = strobeInit()
mexHID('initialize');
mcc = MCCOpen;
toplexon = @(n)sendStrobe(n,mcc);
end

function out = negforplexon(in)
if in < 0
    out = (-1 * in) + 7000;
else
    out = in;
end
end%CES 5/7/2013

function [filename, foldername] = createFile(projFolder, projInits, initial) %CES 9/27/2013
cd(projFolder(1:5));
if exist(projFolder(7:end), 'dir')==0, mkdir(projFolder(7:end)); end
cd(projFolder);
dateS = datestr(now, 'yymmdd');
filename = [initial dateS '.1.' projInits '.mat'];
foldername = [initial dateS];
if exist(foldername, 'dir')==0, mkdir(foldername); end
cd(foldername)
trynum = 1;
while(exist(filename, 'file')~=0)
    trynum = trynum + 1;
    filename = [initial dateS '.' num2str(trynum) '.' projInits '.mat'];
end
home
end


function daysTrials = countDayTrials(projFolder, foldername) %CES 5/6/2013
cd(projFolder);
thesefiles = dir(foldername);
cd(foldername);
fileIndex = find(~[thesefiles.isdir]);
daysTrials = 0;
for i = 1:length(fileIndex)
    thisfile = thesefiles(fileIndex(i)).name;
    thisdata = importdata(thisfile);
    daysTrials = daysTrials + length(thisdata);
end
end





% function num=randSerial(times)
% num=[];
% for i=1:times
%     num((i-1)*4+1:i*4)=randperm(4);
% end
% end



