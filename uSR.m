% uSR.m 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following code recreates a GUI in MATLAB for user controlled
% experiments on weakly electric fish to detect and express the
% phenomenon of stochastic resonance. 
%
% Sensory thresholds of organisms inform whether an external stimulus is 
% detectable or not. By the addition of white noise, formally subthreshold 
% signals can be detected through a phenomenon called stochastic resonance. 
% Electric fish detect environmental signals through their electric organs
% and emit an electric impulse, or electric organ discharge (EOD). The jamming 
% avoidance response (JAR) is a reflex of electric fish whereby they increase 
% or decrease their emitted frequency when a similar frequency is emitted in 
% their surroundings by a conspecific. 
%
% Our objective is to find whether stochastic resonance in a sub-JAR environment
% is expressed, indicating that white noise enhances information.
%
% An acrylic tank was made, attached with a longitudinal pair of electrodes to 
% monitor the EOD response of the black knife fish(Apteronotus albifrons) and 
% a transverse pair of electrodes to deliver the feedback signal to the fish. 
% This GUI (graphic user interface) simultaneously plots the EOD input signal, 
% the output signal, and graph the interpulse interval (IPI)
% of the EOD. The system is calibrated using a signal generator and an oscilloscope.
%
% It was found that it is fundamentally possible to express stochastic resonance 
% using the JAR. By playing the fish?s frequency to itself, we have induced the 
% JAR and observed changes in the fish?s frequency.
%
% required uSR.fig to display figures of GUI

function varargout = uSR(varargin)
% SR MATLAB code for uSR.fig
%      SR, by itself, creates a new SR or raises the existing
%      singleton*.
%
%      H = SR returns the handle to a new SR or the handle to
%      the existing singleton*.
%
%      SR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SR.M with the given input arguments.
%
%      SR('Property','Value',...) creates a new SR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SR_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SR_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIH  ANDLES

% Edit the above text to modify the response to help SR

%%the code below is an initialization for MATLAB to create the GUI%%
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @uSR_OpeningFcn, ...
                   'gui_OutputFcn',  @uSR_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

end

% --- Executes just before SR is made visible.
function uSR_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SR (see VARARGIN)

global rate %rate of electrical output by fish
global allIPI %variable containing interpulse intervals (IPI)
global allTimes %time of session


s1 = daq.createSession('ni');
addAnalogInputChannel(s1,'Dev4','ai0','Voltage');
addAnalogOutputChannel(s1,'Dev4', 'ao0','Voltage');

s1.Rate=40000; %default rate
rate = get(s1, 'Rate');
set(handles.ad_Rate, 'String', num2str(rate))


handles.s1 = s1;
handles.output = hObject; % Choose default command line output for SR
s1.IsContinuous = true; 

% INIT VALUES
handles.dataIn = zeros(1, 20000);
handles.dataOut = zeros(1, 1000000);

handles.dataTimeIn = zeros(1,1);
handles.completeIPI = zeros(1,1);
handles.completeTimeCourse = zeros(1,1);
guidata(hObject, handles);

%collects data
lh_in = addlistener(s1, 'DataAvailable', @(src,event)processInput(src, event, handles.InputPlot_graph, hObject, handles)); 
lh_out = addlistener(s1, 'DataRequired', @(src, event) src.queueOutputData(handles.dataOut'));  %required for output
s1.queueOutputData(handles.dataOut');

allIPI = zeros(1,1); % preallocation
allTimes = zeros(1,1);      

guidata(hObject, handles);

axes(handles.InputPlot_graph);
cla  %clear axes
axes(handles.OutputPlot_graph);
cla
axes(handles.allIPI_graph);
cla
guidata(hObject, handles);

end

%%default object by MATLAB
% --- Outputs from this function are returned to the command line.
function varargout = uSR_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;

end

% --- Executes on button press in Start_Button.
function Start_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Start_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set(handles.ad_Rate,'Enable','off');
guidata(handles.ad_Rate, handles);

startBackground(handles.s1);
guidata(hObject, handles);

end

% this runs the experiments and helps calculate some data
function processInput(src, event, h, hObject, handles)
global tempData; %variable that holds data and gets appended with incoming data
global tempTimeStamps; %variable that holds recorded time at the point of data collection
 
axes(h);  
plot(h, event.TimeStamps, event.Data);    
title(h, 'INPUT');
guidata(hObject, handles); % update plot statement 

% Next two lines reference basic data from A/D board
handles.dataIn = event.Data;
handles.dataTimeIn = event.TimeStamps;
guidata(hObject, handles);

tempData = [tempData; event.Data];                  
tempTimeStamps = [tempTimeStamps; event.TimeStamps];
guidata(hObject, handles);

amp = str2double(get(handles.Damp_Amp,'String'));
handles.dataOut = amp * handles.dataIn;
guidata(hObject, handles);

%delivers white noise when selected by user at time of experiment
w = get(handles.AddNoisebutton,'Value');
switch w
    case 0
      handles.dataOut = handles.dataOut;
    case 1
        snr = str2double(get(handles.SNRvalue,'String'));
        disp('before')
        disp(handles.dataOut)
        handles.dataOut = awgn(handles.dataOut,snr);
        disp('after')
        disp(handles.dataOut)
        guidata(hObject, handles);
end

%plots collected data
plotIPI(hObject, handles);
plotOUTPUT(hObject, handles);
guidata(hObject, handles);

queueOutputData(handles.s1, handles.dataOut);  %required for output 
guidata(hObject, handles);

end

%plots the voltage outputted by the fish
function plotOUTPUT(hObject, handles)

axes(handles.OutputPlot_graph);
plot(handles.OutputPlot_graph,handles.dataTimeIn, handles.dataOut); 
title(handles.OutputPlot_graph, 'OUTPUT');

end

%funciton created to calculate IPI
function [tottime2, interpulse_interval, meanString, sdString] = calcIPI(data2, rate)

pulses=data2>0;   %only 1 or 0
t=diff(pulses);  %series will be 1, -1, 0
onsets = t>0;    %pulse onset only (this is a column)
    
z=find(onsets);  %indices of onset pulses (from thresholded data)  (column)
tottime=(z)*(1000/rate);   %column
[tr, tc]=size(tottime);

tottime2=tottime(2:tr,tc);  % x-axis values

meanString = 1/mean(interpulse_interval) * 1000;
sdString = std(interpulse_interval);

end

%outputs IPI in real-time
% this allows the user to see if stochastic resonance is expressed
function plotIPI(hObject, handles)

global allIPI
global allTimes
global rate 

data = handles.dataIn;
thresh = median(abs(data))-std(abs(data));
data2 = sparse(double((data>thresh).*data)); 
[timeStamps, interpulseTime, meanString, sdIPI] = calcIPI(data2, rate);

% Returns the mean frequency and SD of IPI
set(handles.MeanFreq, 'String', num2str(meanString));
sdString=(1/sdIPI);
set(handles.StandDevFreq, 'String', num2str(sdString));
guidata(hObject, handles);

[trow, tcol] = size(timeStamps);

[Ar, Ac] = size(allTimes);

% data wrangling for plot
v1 = allTimes(Ar,1);
v2 = timeStamps + allTimes(Ar,1);
allTimes = vertcat(allTimes, v2);
allIPI = vertcat(allIPI, interpulseTime);

plot(handles.allIPI_graph, allTimes, allIPI, 'r.');
title(handles.allIPI_graph, 'all IPI');
ylabel(handles.allIPI_graph, 'msecs');  

end 
 
% --- Executes on button press in ceasebutton2.
% This allows the user to stop the running of the program when they want
% their experiment to end
function ceasebutton2_Callback(hObject, eventdata, handles)
% hObject    handle to ceasebutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%global rate
% global snr
global allIPI 
global allTimes
global tempData
global tempTimeStamps
global fileName
global rate

snr = get(handles.SNRvalue, 'String');

disp('stop');   
disp('Begining Program Termination...')
stop(handles.s1);
s1.IsContinuous = false; 

% allows user to save their data form experiment
answer = inputdlg('Save this data? (yes or no)','Save Data', 1);
if strcmpi(answer,'YES')
    uisave({'rate','snr','allIPI','allTimes','tempData','tempTimeStamps'}, 'fileName');    
end

% we need to flush the acquired data
flushdata(handles.dataIn);
disp('Releasing all input/output devices...')

end

%reports rate of EOD from the A/D board
function ad_Rate_Callback(hObject, eventdata, handles)
% hObject    handle to ad_Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

rate = str2double(get(hObject,'String')); % returns contents of ad_Rate as a double  

end

% --- Executes during object creation, after setting all properties.
function ad_Rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ad_Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function Damp_Amp_Callback(hObject, eventdata, handles)
% hObject    handle to Damp_Amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Damp_Amp = str2double(get(hObject,'String'));
              
guidata(hObject, handles); 

end

% --- Executes during object creation, after setting all properties.
function Damp_Amp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Damp_Amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function LowPassLimit_Callback(hObject, eventdata, handles)
% hObject    handle to LowPassLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --- Executes during object creation, after setting all properties.
function LowPassLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LowPassLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function HighPassLimit_Callback(hObject, eventdata, handles)
% hObject    handle to HighPassLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --- Executes during object creation, after setting all properties.
function HighPassLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to HighPassLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function SNRvalue_Callback(hObject, eventdata, handles)
% hObject    handle to SNRvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end
 
% --- Executes during object creation, after setting all properties.
function SNRvalue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SNRvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

% --- Executes on button press in AddNoisebutton.
function AddNoisebutton_Callback(~, eventdata, handles)
% hObject    handle to AddNoisebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of AddNoisebutton

end

% --- Executes on button press in saveFile_button.
function saveFile_button_Callback(hObject, eventdata, handles)
% hObject    handle to saveFile_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%global rate
%global snr
global allIPI 
global allTimes
global tempData
global tempTimeStamps
global fileName

snr=get(handles.SNRvalue, 'String');
rate=get(handles.ad_Rate, 'String');

uisave({'rate','snr','allIPI','allTimes','tempData','tempTimeStamps'}, 'fileName');

end

% --- Executes on mouse press over axes background.
function allIPI_graph_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to allIPI_graph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --- Executes during object deletion, before destroying properties.
function allIPI_graph_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to allIPI_graph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --- Executes during object creation, after setting all properties.
function allIPI_graph_CreateFcn(hObject, eventdata, handles)
% hObject    handle to allIPI_graph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

end

% --- Executes during object creation, after setting all properties.
function MeanFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MeanFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

% --- Executes during object creation, after setting all properties.
function StandDevFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StandDevFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end
