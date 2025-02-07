%Copyright (c) 2016, Haotian Teng rights reserved.
    
%ZerbrafishProject is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.

%ZerbrafishProject is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%You should have received a copy of the GNU General Public License
%    along with ZerbrafishProject.  If not, see <http://www.gnu.org/licenses/>.

classdef PlainPainter < handle
    properties
    ProjectorHandles;
    UIfigure; %stroe the uifigure
    Tgroup;
    JTabGroup
    SpotTab
    BarTab
    Export
    FontSize
    Frames %Fresh rate unit in frames/second
    TotalFrames
    TotalTime
    TotalTimeUnit
    FramesTextHandle
    FramesHandle
    Advanced
    SpotsOnTime = 1; %unit in seconds, used for generate the inital spots parameters
    SpotsTimeInterval = 4; %unit in seconds, used for generate the inital spots parameters
    WHRatio; % The Weight - Height Ratio, used to calculate the spot radius in milli meter.
    plainMovie;
    Info; %Used to save the metadata of the movie.
    
    %Variables correlated with spots
    SpotsProperties
    SpotsHandles
    SpotsText
    SpotsTextHandles
    Spots  %Used to store the Matrix to generate the movie
    
    %Variables correlated with bars
    BarsProperties
    BarsHandles
    BarsText
    BarsTextHandles
    Bars
    MeshX;
    MeshY;
    %Parameter. The data is stored in spotsProperties, and the handles of
    %each uicontrols in spot panel is stored in spotsHandles, and spotsText
    %is used for presenting the text on the UI interface.
    end
    
    methods
        %Construct the GUI Interface
        function this = PlainPainter(ProjectorHandles)
                this.ProjectorHandles = ProjectorHandles; %A projector handles from Projector GUI.
                this.WHRatio = this.ProjectorHandles.dishRadius * pi / 180;
                this.FontSize = 16;    
                FLeft = 1 * this.FontSize;
                FTop = 1 * this.FontSize;
                FWidth = 30 * this.FontSize;
                FHeight = 37* this.FontSize;
                TabPagePosition = [0.02,0.2,0.96,0.8];
                TabPageWidth = TabPagePosition(3) * FWidth;
                TabPageHeight = TabPagePosition(4) * FHeight;
                
                this.Frames = 30;
               %Spots
                this.SpotsHandles = struct('Number',[],'Index',[],'RadiusBegin',[],...
                    'RadiusEnd',[],'OnBegin',[],'OnEnd',[],'XBegin',[],...
                    'XEnd',[],'YBegin',[],'YEnd',[],'Movement',[],...
                    'Pattern',[],'TotalTime',[],'Repeat',[]);              
               this.SpotsProperties = struct('Number',1,'Index',[],'RadiusBegin',[],...
                    'RadiusEnd',[],'OnBegin',[],'OnEnd',[],'XBegin',[],...
                    'XEnd',[],'YBegin',[],'YEnd',[],'Movement','Straight',...
                    'Pattern',[],'Repeat',[],'XTrailFunction',[],'YTrailFunction',[],'PatternFunction',[],'Parameters',[]);
                               
               %Bars
               this.BarsProperties = struct('SeperateDegrees',30,'Direction',0,'Width',10,'Speed',20,'Phase',0,'OnTime',5);
                %Inital value
                
                
                set(0,'defaultUicontrolFontSize',this.FontSize)
                this.UIfigure = figure('Visible','on','Position',[FLeft,FTop,FWidth,FHeight],...
                    'NumberTitle','off','CloseRequestFcn',@this.CloseFcn,'Name','PlainPainter');
                this.Tgroup = uitabgroup(this.UIfigure,'Position',TabPagePosition);
                this.SpotTab = uitab('Parent', this.Tgroup, 'Title', 'Spot','tag','SpotTab','ForegroundColor','Blue');
                this.BarTab = uitab('Parent', this.Tgroup, 'Title', 'Bar','tag','BarTab','ForegroundColor','Red');
                this.Export = uicontrol('Parent',this.UIfigure,'Style','pushbutton',...
                 'String','Export','Position',[11*this.FontSize,FHeight - this.FontSize*36,6 * this.FontSize, 2*this.FontSize],'Callback',@this.Export_Callback);
                this.Advanced = uicontrol('Parent',this.UIfigure,'Style','pushbutton',...
                    'String','Advanced','Position',[20*this.FontSize,FHeight - this.FontSize*36,6 * this.FontSize, 2*this.FontSize],'Callback',@this.Advanced_Callback,'Visible', 'off');
                %Advanced enable one to customized the spot trail as max
                %freedom, a structure list including the information needed for
                %generate a spot movie is demand,
                
                %The Structure list has to including these properties,         
                %Length of the Structure list is how many spots need to be
                %generated, Each structure stand for 1 spot.
                
                %In each structure, 
                
                %A 1*N vector called SizeTrail is
                %needed, which N is the total frames of the movie, describe
                %the spot size in each frame. Value 0 in a certain column 
                %means the spot will not be displayed at the certain frame
                
                %A 1*N object list called PatternFunction is needed, which
                %N is the total frames of the movie, and in each object
                %there is a function handles point to some functions which
                %is used to generate a certain pattern of the spot. The
                %parameters needed is obtained from the PatternParameter
                %field which described below. The functions should at least
                %take a iamge as a input parameter which is the original
                %spot iamge, and at least output a image which is the image
                %which with pattern. And these two image should be the same
                %size.
                
                %A 1*N cell array called PatternParameter is needed, which N is the
                %total frames of the movie, and for each cell, a vector of
                %parameter list is used to pass into pattern generate
                %functions handles.
                
                %A 2*N matrix called PositionTrail is needed, which N is the
                %total frames of the movie, this vector describe the X and
                %Y position of this spot in each frame, unit is in degrees.
                %First Line of the matrix describe the X position, and
                %second line describe the Y position.
                
                this.FramesTextHandle = uicontrol('Parent',this.UIfigure,'Style','text',...
                    'String','Frames:','Position',[this.FontSize,FHeight - this.FontSize*36,6 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.FramesHandle =  uicontrol('Parent',this.UIfigure,'Style','edit',...
                    'String',num2str(this.Frames),'Position',[this.FontSize * 7,FHeight - this.FontSize*36,2 * this.FontSize, 2*this.FontSize],'Callback',@this.Frames_Callback);
             
             %Spot Page construction
                %Plain Text
                this.SpotsTextHandles.Number = uicontrol('Parent', this.SpotTab, 'Style','Text',...
                    'String','Spot Number','Position',[this.FontSize,TabPageHeight - this.FontSize*4,9 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.Number = uicontrol('Parent', this.SpotTab, 'Style','edit',...
                    'String',num2str(this.SpotsProperties.Number),'Position',...
                    [this.FontSize * 10,TabPageHeight - this.FontSize*4,3*this.FontSize, 2*this.FontSize],...
                    'Callback',@this.SpotsNumber_Callback);
                this.SpotsHandles.NumberConfirm = uicontrol('Parent',this.SpotTab,'Style','pushbutton',...
                    'String','Confirm','Position',[this.FontSize * 14,TabPageHeight - this.FontSize*4,6*this.FontSize, 2*this.FontSize],...
                    'Callback',@this.SpotsNumberConfirm_Callback);
                %First Line end
                
                this.SpotsTextHandles.Index = uicontrol('Parent',this.SpotTab,'Style','text',...
                    'String','Current Spot Index','Position',[this.FontSize,TabPageHeight - this.FontSize*7,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.Index = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.Index),'Position',...
                    [this.FontSize * 13,TabPageHeight - this.FontSize*7,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsIndex_Callback);
                this.SpotsHandles.IndexPlus = uicontrol('Parent',this.SpotTab,'Style','pushbutton',...
                    'String','+','Position',...
                    [this.FontSize * 16,TabPageHeight - this.FontSize*6,this.FontSize, this.FontSize],...
                    'Enable','off','Callback',@this.SpotsIndexPlus_Callback);
                this.SpotsHandles.IndexMinus = uicontrol('Parent',this.SpotTab,'Style','pushbutton',...
                    'String','-','Position',...
                    [this.FontSize * 16,TabPageHeight - this.FontSize*7,this.FontSize, this.FontSize],...
                    'Enable','off','Callback',@this.SpotsIndexMinus_Callback);
                %Second Line end
                
                this.SpotsTextHandles.Radius = uicontrol('Parent',this.SpotTab,'Style','text',...
                    'String','Spot Radius from','Position',[this.FontSize,TabPageHeight - this.FontSize*10,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.RadiusBegin = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.RadiusBegin),'Position',...
                    [this.FontSize * 13,TabPageHeight - this.FontSize*10,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsRadiusBegin_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','to','Position',[this.FontSize * 16,TabPageHeight - this.FontSize*10,2 * this.FontSize, 2*this.FontSize]);
                this.SpotsHandles.RadiusEnd = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.RadiusEnd),'Position',...
                    [this.FontSize * 18,TabPageHeight - this.FontSize*10,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsRadiusEnd_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','Degrees','Position',[this.FontSize * 21,TabPageHeight - this.FontSize*10,6 * this.FontSize, 2*this.FontSize]);
                %3rd Line end
                
                this.SpotsTextHandles.OnTime = uicontrol('Parent',this.SpotTab,'Style','text',...
                    'String','Spot On from','Position',[this.FontSize,TabPageHeight - this.FontSize*13,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.OnBegin = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.OnBegin),'Position',...
                    [this.FontSize * 13,TabPageHeight - this.FontSize*13,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsOnBegin_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','to','Position',[this.FontSize * 16,TabPageHeight - this.FontSize*13,2 * this.FontSize, 2*this.FontSize]);
                this.SpotsHandles.OnEnd = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.OnEnd),'Position',...
                    [this.FontSize * 18,TabPageHeight - this.FontSize*13,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsOnEnd_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','Seconds','Position',[this.FontSize * 21,TabPageHeight - this.FontSize*13,6 * this.FontSize, 2*this.FontSize]);
                %4th Line end
                
                this.SpotsTextHandles.Movement = uicontrol('Parent',this.SpotTab,'Style','text',...
                    'String','Spot Movement','Position',[this.FontSize,TabPageHeight - this.FontSize*16,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.Movement = uicontrol('Parent',this.SpotTab,'Style','pop',...
                    'String',{'Straight';'Trail'},'Position',...
                    [this.FontSize * 13,TabPageHeight - this.FontSize*16,6 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsMovement_Callback);
                %5th Line End
                
                this.SpotsTextHandles.Coordinate = uicontrol('Parent',this.SpotTab,'Style','text',...
                    'String','Spot Travel from','Position',[this.FontSize,TabPageHeight - this.FontSize*19,11 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.XBegin = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.XBegin),'Position',...
                    [this.FontSize * 13,TabPageHeight - this.FontSize*19,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsXBegin_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','to','Position',[this.FontSize * 16,TabPageHeight - this.FontSize*19,2 * this.FontSize, 2*this.FontSize]);
                uicontrol('Parent',this.SpotTab,'Style','text','String','X','Position',[this.FontSize * 12,TabPageHeight - this.FontSize*19,1 * this.FontSize, 2*this.FontSize]);
                uicontrol('Parent',this.SpotTab,'Style','text','String','X','Position',[this.FontSize * 18,TabPageHeight - this.FontSize*19,1 * this.FontSize, 2*this.FontSize]);
                this.SpotsHandles.XEnd = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.XEnd),'Position',...
                    [this.FontSize * 19,TabPageHeight - this.FontSize*19,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsXEnd_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','Degrees','Position',[this.FontSize * 22,TabPageHeight - this.FontSize*19,6 * this.FontSize, 2*this.FontSize]);
                %6th Line End
                
                this.SpotsHandles.YBegin = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.YBegin),'Position',...
                    [this.FontSize * 13,TabPageHeight - this.FontSize*22,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsYBegin_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','Y','Position',[this.FontSize * 12,TabPageHeight - this.FontSize*22,1 * this.FontSize, 2*this.FontSize]);
                uicontrol('Parent',this.SpotTab,'Style','text','String','Y','Position',[this.FontSize * 18,TabPageHeight - this.FontSize*22,1 * this.FontSize, 2*this.FontSize]);
                this.SpotsHandles.YEnd = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.YEnd),'Position',...
                    [this.FontSize * 19,TabPageHeight - this.FontSize*22,3 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsYEnd_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','mm','Position',[this.FontSize * 22,TabPageHeight - this.FontSize*22,3 * this.FontSize, 2*this.FontSize]);
                %7th Line End
                
                this.SpotsTextHandles.Pattern = uicontrol('Parent',this.SpotTab,'Style','text',...
                    'String','Spot Pattern','Position',[this.FontSize,TabPageHeight - this.FontSize*25,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.Pattern = uicontrol('Parent',this.SpotTab,'Style','pop',...
                    'String',{'Solid';'CheckerBoard'},'Position',...
                    [this.FontSize * 13,TabPageHeight - this.FontSize*25,6 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsPattern_Callback);
                this.SpotsHandles.PatternPSet = uicontrol('Parent',this.SpotTab,'Style','pushbutton',...
                    'String','Set Pattern Parameter','Position',[this.FontSize * 20,TabPageHeight - this.FontSize*25,6 * this.FontSize, 2*this.FontSize],...
                    'Callback',@this.SpotsPatternPSet_Callback);
                %8th Line End
                
                this.SpotsTextHandles.Repeat = uicontrol('Parent',this.SpotTab,'Style','text',...
                    'String','Repeat in','Position',[this.FontSize,TabPageHeight - this.FontSize*28,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.Repeat = uicontrol('Parent',this.SpotTab,'Style','edit',...
                    'String',num2str(this.SpotsProperties.Repeat),'Position',...
                    [this.FontSize * 13,TabPageHeight - this.FontSize*28,6 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.SpotsRepeat_Callback);
                uicontrol('Parent',this.SpotTab,'Style','text','String','Seconds','Position',[this.FontSize * 20,TabPageHeight - this.FontSize*28,6 * this.FontSize, 2*this.FontSize]);
                %9th Line End
                
                this.SpotsTextHandles.TotalTime = uicontrol('Parent',this.UIfigure,'Style','text',...
                    'String',['Total Time/Frames  ',num2str(this.TotalTime)],'Position',[this.FontSize,FHeight - this.FontSize*33,15 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.SpotsHandles.TotalTimeUnit = uicontrol('Parent',this.UIfigure,'Style','pop',...
                    'String',{'Seconds';'Frames'},'Position',...
                    [this.FontSize * 16,FHeight - this.FontSize*33,7 * this.FontSize, 2*this.FontSize],...
                    'Enable','off','Callback',@this.TotalTimeUnit_Callback);
                %10th Line End
                
                
           %Spot Page End
           
           %Bar Page construction
                
                this.BarsTextHandles.SeperateDegrees = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Seperate Degrees','Position',[this.FontSize,TabPageHeight - this.FontSize*7,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.BarsHandles.SeperateDegrees = uicontrol('Parent',this.BarTab,'Style','edit',...
                    'String',num2str(this.BarsProperties.SeperateDegrees),'Position',[13*this.FontSize,TabPageHeight - this.FontSize*7,3 * this.FontSize, 2*this.FontSize],...
                    'Callback',@this.BarsSeperateDegrees_Callback);
                this.BarsTextHandles.SeperateDegreesUnit = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Degrees','Position',[17*this.FontSize,TabPageHeight - this.FontSize*7,6 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                %1st LineEnd
                
                
                this.BarsTextHandles.Direction = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Direction','Position',[this.FontSize,TabPageHeight - this.FontSize*10,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.BarsHandles.Direction = uicontrol('Parent',this.BarTab,'Style','edit',...
                    'String',num2str(this.BarsProperties.Direction),'Position',[13*this.FontSize,TabPageHeight - this.FontSize*10,3 * this.FontSize, 2*this.FontSize],...
                    'Callback',@this.BarsDirection_Callback);
                this.BarsTextHandles.DirectionUnit = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Degrees','Position',[17*this.FontSize,TabPageHeight - this.FontSize*10,6 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                %2nd Line End
                
                this.BarsTextHandles.Width = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Width(Radius)','Position',[this.FontSize,TabPageHeight - this.FontSize*13,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.BarsHandles.Width = uicontrol('Parent',this.BarTab,'Style','edit',...
                    'String',num2str(this.BarsProperties.Width),'Position',[13*this.FontSize,TabPageHeight - this.FontSize*13,3 * this.FontSize, 2*this.FontSize],...
                    'Callback',@this.BarsWidth_Callback);
                this.BarsTextHandles.WidthUnit = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Degrees','Position',[17*this.FontSize,TabPageHeight - this.FontSize*13,6 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                
                %3rd Line End
                
                this.BarsTextHandles.Speed = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Speed','Position',[this.FontSize,TabPageHeight - this.FontSize*16,12 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.BarsHandles.Speed = uicontrol('Parent',this.BarTab,'Style','edit',...
                    'String',num2str(this.BarsProperties.Speed),'Position',[13*this.FontSize,TabPageHeight - this.FontSize*16,3 * this.FontSize, 2*this.FontSize],...
                    'Callback',@this.BarsSpeed_Callback);
                this.BarsTextHandles.SpeedUnit = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Degrees/Second','Position',[17*this.FontSize,TabPageHeight - this.FontSize*16,14 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                %4th Line End
                
                this.BarsTextHandles.Phase = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Phase','Position',[this.FontSize,TabPageHeight - this.FontSize*19,6 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.BarsHandles.Phase = uicontrol('Parent',this.BarTab,'Style','edit',...
                    'String',num2str(this.BarsProperties.Phase),'Position',[13*this.FontSize,TabPageHeight - this.FontSize*19,3 * this.FontSize, 2*this.FontSize],...
                    'Callback',@this.BarsPhase_Callback);
                this.BarsTextHandles.Phase = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Degrees','Position',[17*this.FontSize,TabPageHeight - this.FontSize*19,14 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                %5th Line End
                
                this.BarsTextHandles.OnTime = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','OnTime','Position',[this.FontSize,TabPageHeight - this.FontSize*22,6 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                this.BarsHandles.OnTime = uicontrol('Parent',this.BarTab,'Style','edit',...
                    'String',num2str(this.BarsProperties.OnTime),'Position',[13*this.FontSize,TabPageHeight - this.FontSize*22,3 * this.FontSize, 2*this.FontSize],...
                    'Callback',@this.BarsOnTime_Callback);
                this.BarsTextHandles.OnTime = uicontrol('Parent',this.BarTab,'Style','text',...
                    'String','Seconds','Position',[17*this.FontSize,TabPageHeight - this.FontSize*22,14 * this.FontSize, 2*this.FontSize],...
                    'Ho','left');
                %6th Line End
                
                
           %Bar Page End

                
           uiwait(this.ProjectorHandles.figure1);%Stop running the Projector GUI until return.
%            set(this.ProjectorHandles.figure1,'WindowStyle','modal')
        end
        
        function CloseFcn(this,src,eventdata)
%             this.UIfigure
            delete(this.UIfigure);
        end
        


        %Callback functions
        function SpotsNumber_Callback(this,src,eventdata)
            this.SpotsProperties.Number = str2num(get(src,'String'));

        end
        
        function SpotsNumberConfirm_Callback(this,src,eventdata)
            this.SpotsProperties.Number = str2double(get(this.SpotsHandles.Number,'String'));
            if rem(this.SpotsProperties.Number,1) ~= 0
                display('Warning! Spots number must be a integer.')
                this.SpotsProperties.Number = round(this.SpotsProperties.Number);
                set(this.SpotsHandles.Number,'String',num2str(this.SpotsProperties.Number));
            end
            set(this.SpotsHandles.Number,'enable','off');
            SpotNumber = this.SpotsProperties.Number;
            TimeInterval = this.SpotsTimeInterval; %default 4s
            OnTime   = this.SpotsOnTime; %default 1s
            this.SpotsProperties.Index = 1;
            Index =1;
            this.SpotsProperties.RadiusBegin = ones(1,SpotNumber)*3;
            this.SpotsProperties.RadiusEnd   = ones(1,SpotNumber)*3;
            this.SpotsProperties.OnBegin     = 0:TimeInterval:TimeInterval*(SpotNumber-1);
            this.SpotsProperties.OnEnd       = (0+OnTime):TimeInterval:(TimeInterval*(SpotNumber-1)+OnTime);
            this.SpotsProperties.Movement    = cell(1,SpotNumber);
            for i=1:SpotNumber
            this.SpotsProperties.Movement{i} = 'Straight';
            this.SpotsProperties.PatternFunction{i} = @this.SolidPatternFunction;
            this.SpotsProperties.Pattern{i}  = 'Solid';
            end
            this.SpotsProperties.Parameters = cell(1,5); %Used to store the parameters of the pattern function.
            this.SpotsProperties.XBegin      = (180/(SpotNumber+1)):(180/(SpotNumber+1)):(180-(180/(SpotNumber+1)));
            this.SpotsProperties.XEnd        = (180/(SpotNumber+1)):(180/(SpotNumber+1)):(180-(180/(SpotNumber+1)));
            this.SpotsProperties.YBegin      = ones(1,SpotNumber)*5;
            this.SpotsProperties.YEnd        =  ones(1,SpotNumber)*5;
            this.TotalTimeUnit = 'Seconds';
            this.SpotsProperties.Repeat =cell(SpotNumber,1);
            [this.SpotsProperties.Repeat{:}] = deal(0);
            
            set(this.SpotsHandles.Index,'enable','on','String',num2str(this.SpotsProperties.Index));
            set(this.SpotsHandles.RadiusBegin,'enable','on','String',num2str(this.SpotsProperties.RadiusBegin(Index)));
            set(this.SpotsHandles.RadiusEnd,'enable','on','String',num2str(this.SpotsProperties.RadiusEnd(Index)));
            set(this.SpotsHandles.OnBegin,'enable','on','String',num2str(this.SpotsProperties.OnBegin(Index)));
            set(this.SpotsHandles.OnEnd,'enable','on','String',num2str(this.SpotsProperties.OnEnd(Index)));
            set(this.SpotsHandles.XBegin,'enable','on','String',num2str(this.SpotsProperties.XBegin(Index)));
            set(this.SpotsHandles.XEnd,'enable','on','String',num2str(this.SpotsProperties.XEnd(Index)));
            set(this.SpotsHandles.YBegin,'enable','on','String',num2str(this.SpotsProperties.YBegin(Index)));
            set(this.SpotsHandles.YEnd,'enable','on','String',num2str(this.SpotsProperties.YEnd(Index)));
            set(this.SpotsHandles.Movement,'enable','on');
            set(this.SpotsHandles.Pattern,'enable','on');
            set(this.SpotsHandles.TotalTimeUnit,'enable','on');
            set(this.SpotsHandles.Repeat,'enable','on','String',num2str(this.SpotsProperties.Repeat{Index}));
            set(this.SpotsHandles.IndexPlus,'enable','on');
            set(this.SpotsHandles.IndexMinus,'enable','on');
            
            this.TotalTime = max(this.SpotsProperties.OnEnd);
            this.TotalFrames = ceil(this.TotalTime * this.Frames);
            this.TotalTimeUnit_Callback(this.SpotsHandles.TotalTimeUnit,eventdata);
                
        end
        
        function SpotsIndex_Callback(this,src,eventdata)
            Index = str2double(get(src,'String'));
            if rem(this.SpotsProperties.Index,1) ~= 0
                display('Warning! Spots Index must be a integer.')
                this.SpotsProperties.Index = round(this.SpotsProperties.Index);
                set(this.SpotsHandles.Index,'String',num2str(this.SpotsProperties.Index));
            end
            set(src,'String',Index);
            if Index < 1 || Index >this.SpotsProperties.Number
                set(src,'String',num2str(this.SpotsProperties.Index));
                warndlg(sprintf('The Index Input is illegal!\n Index must a positive smaller than %d (SpotsNumber)',this.SpotsProperties.Number));
                return;
            end
            this.SpotsProperties.Index = Index;
            set(this.SpotsHandles.Index,'enable','on','String',num2str(this.SpotsProperties.Index));
            set(this.SpotsHandles.RadiusBegin,'enable','on','String',num2str(this.SpotsProperties.RadiusBegin(Index)));
            set(this.SpotsHandles.RadiusEnd,'enable','on','String',num2str(this.SpotsProperties.RadiusEnd(Index)));
            set(this.SpotsHandles.OnBegin,'enable','on','String',num2str(this.SpotsProperties.OnBegin(Index)));
            set(this.SpotsHandles.OnEnd,'enable','on','String',num2str(this.SpotsProperties.OnEnd(Index)));
            MovementIndex = find(strcmp([this.SpotsHandles.Movement.String(:)],this.SpotsProperties.Movement{Index})); 
            % due to way to save the movement mode -- with a string cell, never do that in saving a popupmenu Value.
            set(this.SpotsHandles.Movement,'Value',MovementIndex);
            set(this.SpotsHandles.XBegin,'enable','on','String',num2str(this.SpotsProperties.XBegin(Index)));
            set(this.SpotsHandles.XEnd,'enable','on','String',num2str(this.SpotsProperties.XEnd(Index)));
            set(this.SpotsHandles.YBegin,'enable','on','String',num2str(this.SpotsProperties.YBegin(Index)));
            set(this.SpotsHandles.YEnd,'enable','on','String',num2str(this.SpotsProperties.YEnd(Index)));
            PatternIndex = find(strcmp([this.SpotsHandles.Pattern.String(:)],this.SpotsProperties.Pattern{Index})); 
            % due to the way to save the movement mode -- with a string cell, never do that in saving a popupmenu Value.
            set(this.SpotsHandles.Pattern,'Value', PatternIndex);
            set(this.SpotsHandles.Repeat,'String',num2str(this.SpotsProperties.Repeat{Index}));
            
        end
        function SpotsIndexPlus_Callback(this,src,eventdata)
            set(this.SpotsHandles.Index ,'String' , num2str(this.SpotsProperties.Index + 1) );
            this.SpotsIndex_Callback(this.SpotsHandles.Index,eventdata);
        end
        function SpotsIndexMinus_Callback(this,src,eventdata)
            set(this.SpotsHandles.Index ,'String' , num2str(this.SpotsProperties.Index - 1) );
            this.SpotsIndex_Callback(this.SpotsHandles.Index,eventdata);
        end
        function SpotsRadiusBegin_Callback(this,src,eventdata)
            this.SpotsProperties.RadiusBegin(this.SpotsProperties.Index) = str2double(get(src,'String'));
        end
        
        function SpotsRadiusEnd_Callback(this,src,eventdata)
            this.SpotsProperties.RadiusEnd(this.SpotsProperties.Index) = str2double(get(src,'String'));
        end
        
        function SpotsOnBegin_Callback(this,src,eventdata)
            OnBegin = str2double(get(src,'String'));
            OnEnd = this.SpotsProperties.OnEnd(this.SpotsProperties.Index);
            this.SpotsProperties.OnBegin(this.SpotsProperties.Index) = OnBegin;
            if OnBegin > OnEnd
                this.SpotsProperties.OnEnd(this.SpotsProperties.Index) = OnBegin + 1 ;
                set(this.SpotsHandles.OnEnd,'String',num2str(this.SpotsProperties.OnEnd(this.SpotsProperties.Index)));
                this.SpotsOnEnd_Callback(this.SpotsHandles.OnEnd,eventdata);
                display('Warning, the Spot On Start Time can not be after the Spot On End Time, the End Time have been reset to the Start Time.')
            end
        end
        
        function SpotsOnEnd_Callback(this,src,eventdata)
            OnEnd = str2double(get(src,'String'));
            this.SpotsProperties.OnEnd(this.SpotsProperties.Index) = OnEnd;
            if OnEnd < this.SpotsProperties.OnBegin(this.SpotsProperties.Index)
                this.SpotsProperties.OnBegin(this.SpotsProperties.Index) = OnEnd - 1 ;
                set(this.SpotsHandles.OnBegin,'String',num2str(this.SpotsProperties.OnBegin(this.SpotsProperties.Index)));
                display('Warning, the Spot On End Time can not be earlier the Spot On Start Time, the Start Time have been reset to the End Time - 1s.')
            end
            RenewTotalTime = OnEnd+max(this.SpotsProperties.Repeat{this.SpotsProperties.Index});
            if RenewTotalTime > this.TotalTime
                this.TotalTime = RenewTotalTime;
                this.TotalFrames = ceil(this.TotalTime * this.Frames);
                this.TotalTimeUnit_Callback(this.SpotsHandles.TotalTimeUnit,eventdata);
            end
        end
        
        function SpotsMovement_Callback(this,src,eventdata)
            this.SpotsProperties.Movement{this.SpotsProperties.Index} = src.String{get(src,'Value')};
            if strcmp(this.SpotsProperties.Movement{this.SpotsProperties.Index},'Trail')
               display(['The Spot',num2str(this.SpotsProperties.Index),' is begin at ',...
                   num2str(this.SpotsProperties.OnBegin(this.SpotsProperties.Index)),' and end at ',...
                   num2str(this.SpotsProperties.OnEnd(this.SpotsProperties.Index))]);
               display(['So the t is range from 0 to ',...
                   num2str(this.SpotsProperties.OnEnd(this.SpotsProperties.Index)-this.SpotsProperties.OnBegin(this.SpotsProperties.Index))]);
               XTrailFunction = input(['Please input a function to calculate the X(t) for the Spot ',num2str(this.SpotsProperties.Index),', for example:\n X(t)=sin(t) \n X(t)='],'s');
               YTrailFunction = input(['Please input a function to calculate the Y(t) for the Spot ',num2str(this.SpotsProperties.Index),', for example:\n Y(t)=cos(t) \n Y(t)='],'s');
               this.SpotsProperties.XTrailFunction{this.SpotsProperties.Index} = str2func(['@(t)',XTrailFunction]);
               this.SpotsProperties.YTrailFunction{this.SpotsProperties.Index} = str2func(['@(t)',YTrailFunction]);
            end
        end
        
        function SpotsXBegin_Callback(this,src,eventdata)
            this.SpotsProperties.XBegin(this.SpotsProperties.Index) = str2double(get(src,'String'));
        end
        function SpotsYBegin_Callback(this,src,eventdata)
            this.SpotsProperties.YBegin(this.SpotsProperties.Index) = str2double(get(src,'String'));
        end
        function SpotsXEnd_Callback(this,src,eventdata)
            this.SpotsProperties.XEnd(this.SpotsProperties.Index) = str2double(get(src,'String'));
        end
        function SpotsYEnd_Callback(this,src,eventdata)
            this.SpotsProperties.YEnd(this.SpotsProperties.Index) = str2double(get(src,'String'));
        end
        function SpotsPattern_Callback(this,src,eventdata)
            this.SpotsProperties.Pattern{this.SpotsProperties.Index} = this.SpotsHandles.Pattern.String{get(src,'Value')};
            switch this.SpotsProperties.Pattern{this.SpotsProperties.Index}
                case 'Solid'
                    this.SpotsProperties.PatternFunction{this.SpotsProperties.Index} = @this.SolidPatternFunction;
                case 'CheckerBoard'
                    this.SpotsProperties.PatternFunction{this.SpotsProperties.Index} = @this.CheckerBoardPatternFunction;
                    this.SpotsPatternPSet_Callback(this.SpotsHandles.PatternPSet,eventdata);
                    this.SpotsProperties.Parameters{this.SpotsProperties.Index} = struct('ChangeRate',200,'SubRow',4,'SubColumn',4);
            end
        end
        function TotalTimeUnit_Callback(this,src,eventdata)
            this.TotalTimeUnit = get(src,'Value');
            switch this.TotalTimeUnit
                case 2
                    TotalTime = this.TotalTime * this.Frames;
                case 1
                    TotalTime = this.TotalTime ;
            end
            set(this.SpotsTextHandles.TotalTime,'String',['Total Time/Frames ',num2str(TotalTime)])
        end
        
        function SpotsRepeat_Callback(this,src,eventdata)
            this.SpotsProperties.Repeat{this.SpotsProperties.Index} = str2double(strsplit(get(src,'String'),{',',' ',';'}));
            MaxRepeat = zeros(1,this.SpotsProperties.Number);
            for i = 1:this.SpotsProperties.Number
                MaxRepeat(i)  = max(this.SpotsProperties.Repeat{i});
                
            end
            this.TotalTime = max(this.TotalTime,max(this.SpotsProperties.OnEnd+MaxRepeat));
            this.TotalFrames = ceil(this.TotalTime * this.Frames);
            this.TotalTimeUnit_Callback(this.SpotsHandles.TotalTimeUnit,eventdata);
        end
        
        function SpotsPatternPSet_Callback(this,src,eventdata)
            Index = this.SpotsProperties.Index;
            switch   this.SpotsProperties.Pattern{Index}
                case 'CheckerBoard'
                    ChangeRate = str2double(input('ChangeRate (unit in ms)= ','s'));
                    SubRow = str2double(input('Divide the spot into ? rows = ','s'));
                    SubColumn = str2double(input('Divide the spot into ? columns = ','s'));
                    if ~isnan(ChangeRate)
                    this.SpotsProperties.Parameters{Index}.ChangeRate = ChangeRate;
                        if rem(this.SpotsProperties.OnEnd(Index)-this.SpotsProperties.OnBegin(Index),0.001*ChangeRate) >0.0001
                        display('Warning! The checkerboard refresh time may be shorter in the boundary of spots on and off period.\n Because the Spot checkerboard Period is cut off by the spot on event and vanish event.\n To solve this, input an integeral Spot On begin and end time and Changerate.')
                        end
                    end
                    if ~isnan(SubRow)
                    this.SpotsProperties.Parameters{Index}.SubRow = SubRow;
                        if rem(SubRow,1) > 0.000000000001
                        display('Warning, sub row must be a integer, subrow has been automatically corrected to the nearest integer.')
                        this.SpotsProperties.Parameters(Index).SubRow = round(SubRow);
                        end
                    end
                    if ~isnan(SubColumn)
                    this.SpotsProperties.Parameters{Index}.SubColumn = SubColumn;
                        if rem(SubColumn,1) > 0.000000000001
                        display('Warning, sub column must be a integer, subcolumn has been automatically corrected to the nearest integer.')
                        this.SpotsProperties.Parameters(Index).SubColumn = round(SubColumn);
                        end
                    end
                    
            end
        end
        
        %Bars Callback Functions
       
        function BarsSeperateDegrees_Callback(this,src,eventdata)
            this.BarsProperties.SeperateDegrees = str2double(get(src,'String'));
            if(this.BarProperties.SeperateDegrees > 180)
                display(['Warning! The seperate degrees can not exceed 180 degrees.']);
                this.BarProeprties.SeperateDegrees = 180;
                set(src,'String',num2str(180));
            end
        end
        
        function BarsDirection_Callback(this,src,eventdata)
            this.BarsProperties.Direction = str2double(get(src,'String'));
        end
        
        function BarsWidth_Callback(this,src,eventdata)
            this.BarsProperties.Width = str2double(get(src,'String'));
        end
        
        function BarsSpeed_Callback(this,src,eventdata)
            this.BarsProperties.Speed = str2double(get(src,'String'));
        end
        
        function BarsPhase_Callback(this,src,eventdata)
            this.BarsProperties.Phase = str2double(get(src,'String'));
        end
        
        function BarsOnTime_Callback(this,src,eventdata)
            this.BarsProperties.OnTime = str2double(get(src,'String'));
        end
        %General Callback Fcns
        function Frames_Callback(this , src ,  eventdata);
            Frames = str2num(get(src,'String'));
            if(rem(Frames,1) ~= 0)
                dispaly('Warning!The input must be an integer, frames has been set to the nearest integer of the input.')
            end
            this.Frames = round(Frames);
            this.TotalFrames = this.TotalTime * this.Frames;
        end
        
        
        function Export_Callback(this , src , eventdata)
            if this.Tgroup.SelectedTab == this.SpotTab
            this.Spots = cell(1,this.SpotsProperties.Number);
            for i = 1:this.SpotsProperties.Number
                this.SpotsProperties.Index = i;
                this.Spots{i} = struct('SizeTrail',zeros(1,this.TotalFrames),'XCoor',zeros(1,this.TotalFrames),'YCoor',zeros(1,this.TotalFrames),'PatternFunctionIndex',1);
                %the 1st pattern function is the default patternfunction
                %included in the @this.SolidPatternFunction.
                OnTime = round(this.SpotsProperties.OnBegin(i)*this.Frames)+1:round(this.SpotsProperties.OnEnd(i)*this.Frames);
                Len = length(OnTime);
                SizeTrail = linspace(this.SpotsProperties.RadiusBegin(i),this.SpotsProperties.RadiusEnd(i),Len);
                this.Spots{i}.SizeTrail(OnTime) = SizeTrail;
                this.Spots{i}.PatternFunctionIndex = find(strcmp(this.SpotsHandles.Pattern.String(:),this.SpotsProperties.Pattern{i})); 
                switch this.Spots{i}.PatternFunctionIndex
                    case 2 %2 refers to CheckerBoard Pattern
                        this.Spots{i}.CheckerBoardOrder = zeros(this.TotalFrames,this.SpotsProeprteis.Parameters{i}.SubRow*this.SpotsProeprteis.Parameters{i}.SubColumn);
                end
                switch this.SpotsProperties.Movement{i}
                    case 'Straight'
                        this.Spots{i}.XCoor(OnTime) = linspace(this.SpotsProperties.XBegin(i),this.SpotsProperties.XEnd(i),Len);
                        this.Spots{i}.YCoor(OnTime) = linspace(this.SpotsProperties.YBegin(i),this.SpotsProperties.YEnd(i),Len);
                    case 'Trail'
                        this.Spots{i}.XCoor(OnTime) = this.SpotsProperties.XTrailFunction{i}((OnTime-OnTime(1))/this.Frames);
                        this.Spots{i}.YCoor(OnTime) = this.SpotsProperties.YTrailFunction{i}((OnTime-OnTime(1))/this.Frames);
                end
                
                for k = 1:length(this.SpotsProperties.Repeat{i})
                    if(this.SpotsProperties.Repeat{i}(k)>0)
                    Latency = round((this.SpotsProperties.Repeat{i}(k)+this.SpotsProperties.OnBegin(i))*this.Frames)+1;
                    LatencyOnTime = OnTime - OnTime(1) + Latency;
                    this.Spots{i}.XCoor(LatencyOnTime) = this.Spots{i}.XCoor(OnTime);
                    this.Spots{i}.YCoor(LatencyOnTime) = this.Spots{i}.YCoor(OnTime);
                    this.Spots{i}.SizeTrail(LatencyOnTime) = this.Spots{i}.SizeTrail(OnTime);
%                     this.Spots{i}.PatternFunctionIndex(LatencyOnTime) = this.Spots{i}.PatternFunctionIndex(OnTime);
                    end
                end 
            end
            this.plainMovie = this.PlainMovie();
            this.Info = struct('FreshRate',this.Frames,'SpotInfo',this.Spots);
            elseif this.Tgroup.SelectedTab == this.BarTab
            this.TotalFrames = round(this.BarsProperties.OnTime * this.Frames);
            this.plainMovie = this.BarPlainMovie();
            this.Info = struct('FreshRate',this.Frames,'BarInfo',this.BarsProperties);
                
            end
            
            uiresume(this.ProjectorHandles.figure1);%Continue on the Projector GUI.
            this.CloseFcn(this.UIfigure,eventdata);
            
            
        end
        
        %Paint Function
        function PlainMovie = PlainMovie(this)
            stripHeight = this.ProjectorHandles.stripHeight;
            stripHeightResolution = this.ProjectorHandles.stripHeightResolution;
            stripWidth = this.ProjectorHandles.stripWidth;
            stripWidthResolution = this.ProjectorHandles.stripWidthResolution;
            spotNumber = this.SpotsProperties.Number;


            Height=ceil(stripHeight/stripHeightResolution)+1;
            Width=ceil(stripWidth/stripWidthResolution)+1;
            plainMovie = zeros(Height , Width , 3 , this.TotalFrames , 'uint8');
            %Variables List Initiation
            plainMovie(:,:,1,:)=this.ProjectorHandles.backGroundColor(1)*255;
            plainMovie(:,:,2,:)=this.ProjectorHandles.backGroundColor(2)*255;
            plainMovie(:,:,3,:)=this.ProjectorHandles.backGroundColor(3)*255;
            for i = 1:spotNumber    
                this.SpotsProperties.Index = i;
                for j = 1:this.TotalFrames        
                    SpotSize = this.Spots{i}.SizeTrail(j);

                    if SpotSize > 0
                        Spot = this.SpotsProperties.PatternFunction{i}(SpotSize,[0,0,0],j);
                        objectXStart=ceil((this.Spots{i}.XCoor(j) - SpotSize)/stripWidthResolution);
                        objectYStart=ceil((this.Spots{i}.YCoor(j) - SpotSize*this.WHRatio)/stripHeightResolution);
                        [objectH,objectW,N]=size(Spot);
                        plainMovie(objectYStart:1:objectYStart+objectH-1,objectXStart:1:objectXStart+objectW-1,: ,j)=Spot;
                    end

                end    

            end
            PlainMovie = plainMovie;
            %Render a plain movie
        end
        
        function PlainMovie = BarPlainMovie(this)
            stripHeight = this.ProjectorHandles.stripHeight;
            stripHeightResolution = this.ProjectorHandles.stripHeightResolution;
            stripWidth = this.ProjectorHandles.stripWidth;
            stripWidthResolution = this.ProjectorHandles.stripWidthResolution;

            Height=ceil(stripHeight/stripHeightResolution)+1;
            Width=ceil(stripWidth/stripWidthResolution)+1;
            PlainMovie = zeros(Height , Width , 3 , this.TotalFrames , 'uint8');
            %Variables List Initiation
            PlainMovie(:,:,1,:)=this.ProjectorHandles.backGroundColor(1)*255;
            PlainMovie(:,:,2,:)=this.ProjectorHandles.backGroundColor(2)*255;
            PlainMovie(:,:,3,:)=this.ProjectorHandles.backGroundColor(3)*255;
            Color = [0,0,0];
            [this.MeshX,this.MeshY] = meshgrid((-stripWidth/2:stripWidthResolution:stripWidth/2)*this.WHRatio,(-stripHeight/2:stripHeightResolution:stripHeight/2));
            for j = 1:this.TotalFrames
                Bars = false(Height , Width);
                StartPhase = rem(this.BarsProperties.Phase * this.BarsProperties.SeperateDegrees / 360 + (j-1)/this.Frames * this.BarsProperties.Speed - this.BarsProperties.Width,this.BarsProperties.SeperateDegrees);
                for Displacement = StartPhase - this.BarsProperties.SeperateDegrees : this.BarsProperties.SeperateDegrees:180+this.BarsProperties.SeperateDegrees
                    Time = Displacement/this.BarsProperties.Speed;
                    CurrentBar = this.MovingBarPatternFunction(this.BarsProperties.Width,this.BarsProperties.Speed,this.BarsProperties.Direction,Time);
                    Bars = or(Bars,CurrentBar);
                end
                for colorIndex = 1:3
                    BlankFrame = PlainMovie(:,:,colorIndex,j);
                    BlankFrame(Bars) = Color(colorIndex);
                    PlainMovie(:,:,colorIndex,j) = BlankFrame;
                end 
            end


            %Render a plain movie
            
        end
        
        function SpotMask = SolidPatternFunction(this,spotSize,Color,Time)
                %SolidPatternFunction will generate a solid spot in "Color", which is a N * M image matrix,
                %where N refers to the pixels of height, and M refers to the pixels
                %to the width.
                %Time is not used in SolidPatternFunction,unit in frame.
                spotHeight=spotSize*this.WHRatio;
                spotWidth=spotSize;
                XResolution = this.ProjectorHandles.stripWidthResolution;
                YResolution = this.ProjectorHandles.stripHeightResolution;
                SpotMask=zeros(floor(spotHeight * 2 / YResolution) + 1 , floor(spotWidth * 2 / XResolution)+1,3);
                for i=1:3
                SpotMask(:,:,i)=this.ProjectorHandles.backGroundColor(i)*255;
                end
                [x,y]=meshgrid(-spotWidth:XResolution:spotWidth,-spotHeight:YResolution:spotHeight);
                circle=x.^2+(y/this.WHRatio).^2<=(spotSize).^2;
                for i=1:3
                    tempObject=SpotMask(:,:,i);
                    tempObject(circle)=Color(i);
                    SpotMask(:,:,i)=tempObject;
                end
        end
        
        function SpotMask = CheckerBoardPatternFunction(this,spotSize,Color,Time)
            %Time unit in frame.
            ChangeRate = this.SpotsProperties.Parameters{this.SpotsProperties.Index}.ChangeRate; % unit in ms, 
            SubRow = this.SpotsProperties.Parameters{this.SpotsProperties.Index}.SubRow;
            SubColumn = this.SpotsProperties.Parameters{this.SpotsProperties.Index}.SubColumn;
            ChangeRate = ChangeRate/1000*this.Frames; %change unit to the frame
            if (rem(Time-1,ChangeRate)>=0 && rem(Time-1,ChangeRate)<1)
                
                CheckerBoardOrder = randi([0,1],1,SubRow*SubColumn);
            else
                CheckerBoardOrder = this.SpotsProperties.CheckerBoardOrder{this.SpotsProperties.Index}(Time-1,:);
            end
            this.SpotsProperties.CheckerBoardOrder{this.SpotsProperties.Index}(Time,:) = CheckerBoardOrder;
            spotHeight=spotSize*this.WHRatio;
            spotWidth=spotSize;
            XResolution = this.ProjectorHandles.stripWidthResolution;
            YResolution = this.ProjectorHandles.stripHeightResolution;
            SpotMask=zeros(floor(spotHeight * 2 / YResolution) + 1 , floor(spotWidth * 2 / XResolution)+1,3);
            for i=1:3
                SpotMask(:,:,i)=this.ProjectorHandles.backGroundColor(i)*255;
            end
            [x,y]=meshgrid(-spotWidth:XResolution:spotWidth,-spotHeight:YResolution:spotHeight);
            [m,n] = size(x);
            CheckerBoard = ones(m,n);
            for i = 1:SubRow*SubColumn
                RowIndex = floor((i-1)/SubRow)+1;
                ColumnIndex = rem(i-1,SubColumn)+1;
                SubRowLen = m/SubRow;
                SubColumnLen = n/SubColumn;
                CheckerBoard(round(SubRowLen*(RowIndex-1))+1:1:round(SubRowLen*(RowIndex)),round(SubColumnLen*(ColumnIndex-1))+1:1:round(SubColumnLen*(ColumnIndex))) = CheckerBoardOrder(i);
            end
            circle = x.^2+(y/this.WHRatio).^2<=(spotSize).^2;
            circle = circle.*CheckerBoard;
            circle = logical(circle);
            for i=1:3
                tempObject=SpotMask(:,:,i);
                tempObject(circle)=Color(i);
                SpotMask(:,:,i)=tempObject;
            end
            
            
        end
        
        function BarMask = MovingBarPatternFunction(this,BarWidth,MovingSpeed,Direction,Time)
       
            %Direnction is described in angle alpha, 90 > alpha > 0. BarWidth,Width unit in
            %angle too.Moving speed unit in mm/s. Time unit in seconds.Time
            %should be input in the unit of second.
%             BackGroundColor=this.ProjectorHandles.backGroundColor; %Blue background.
            stripHeight = this.ProjectorHandles.stripHeight;
            stripWidth = this.ProjectorHandles.stripWidth;
            XResolution = this.ProjectorHandles.stripWidthResolution;
            YResolution = this.ProjectorHandles.stripHeightResolution;
            Height=stripHeight/2;
            Width=stripWidth/2;
            Radius = this.ProjectorHandles.dishRadius;
            Direction = Direction * pi / 180;
            WHRatio = 1/180*pi*Radius;
            BarWidth = BarWidth * WHRatio; %Transfer the barwidth into mm.
            BarMask = abs(cos(Direction)*this.MeshX+sin(Direction)*this.MeshY+Height / 2 * sin(Direction) + Radius * Width /180 * pi* cos(Direction) - MovingSpeed*WHRatio * Time) < BarWidth;

            
        end


    end

end
