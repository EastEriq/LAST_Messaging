% test how messaging lives with timers: I suspect badly, because both rely
%  on noninterruptible callbacks (only uicontrols can define interruptible
%  callbacks).
% A messenger query done in a timer function does not receive its answer,
%  because the udp listener callback is executed after the timer function
%  and not within it.

% In a remote session, do: 
%  M2=obs.util.Messenger('localhost',5002,5001); M2.connect; M2.Verbose=2;

M1=obs.util.Messenger('localhost',5001,5002);
M1.connect
M1.whoIsThere  % this works as expected

% Now the same but within a timer
collector=timer('Name','ImageCollector',...
    'ExecutionMode','SingleShot','BusyMode','Queue',...
    'StartDelay',1,...
    'TimerFcn','M1.whoIsThere');
%    'StopFcn',@(mTimer,~)delete(mTimer));
start(collector)

% the message is received remotely, but its reply doesn't reach the sender,
%  which times out. But note, the data is silently read.
% If this is called after the timeout, it returns 0:
M1.StreamResource.BytesAvailable

% but if it is called before the timeout, it blocks till the end of the
% timeout
start(collector)
pause(1)
M1.StreamResource.BytesAvailable % and there are bytes available
% but when called shortly after, the bytes disappear
pause(0.1)
M1.StreamResource.BytesAvailable

% One could stealthy try to read the data before the listener callback
%  has a chance to run, but this creates more havoc, because the
%  listener callback is still armed
start(collector)
pause(1)
stream=char(fread(M1.StreamResource)')

% The way to make it work could be to renounce to the listener callback
M1.CallbackRespond=false;
start(collector)
