function success=connect(S)
% attempts to connect to a spawned matlab session, already created by
% .spawn, perhaps even by another matlab process
% Connecting to a session spawned by another matlab process is in most cases
%  a bad idea, because that session will have messengers pointing to its
%  originator. An additional connection will break the assumed bidirectionality

    success=false;

    if isempty(S.Host)
        S.Host='localhost';
    end
    
    if isempty(S.MessengerRemotePort)
        S.MessengerRemotePort=8002;
    end
    
    if isempty(S.ResponderRemotePort)
        S.ResponderRemotePort=9002;
    end
    
    % create a listener messenger
    S.Messenger=obs.util.Messenger(S.Host,S.MessengerRemotePort,...
        S.MessengerLocalPort);
    if ~isempty(S.Id)
        S.Messenger.Id=[S.Id '.Messenger'];
    else
        S.Messenger.Id='spawn.Messenger';
    end

    S.Messenger.connect; % can fail if the local port is busy

    % save the current verbose and timeout values, and temporarily
    %  set a shorter timeout
    v=S.Messenger.Verbose;
    t=S.Messenger.StreamResource.Timeout;
    S.Messenger.Verbose=false;
    S.Messenger.StreamResource.Timeout=1;
    retries=40; i=0;
    pause(1.5) % give time to the remote messenger to start working
    while ~S.Messenger.areYouThere && i<retries
        % retry enough times for the spawned session to be ready, tune it
        %  according to slowness of startup and timeout of the
        %  listener
        i=i+1;
    end               
    S.Messenger.Verbose=v;
    S.Messenger.StreamResource.Timeout=t;
    if i>=retries
        S.reportError(['connection with session %s not ' ...
                               'estabilished, aborting'], S.Id)
        return
    end
    S.PID=S.Messenger.query('feature(''getpid'')');

    % create a second "Responder" messenger, for dual communication
    %  without intermixing of messages. If we are here the
    %  MasterMessenger should already be functioning

    % local Responder head
    S.Responder=obs.util.Messenger(S.Host,S.ResponderRemotePort,...
                                   S.ResponderLocalPort);
    if ~isempty(S.Id)
        S.Responder.Id=[S.Id '.Responder'];
    else
        S.Responder.Id='spawn.Responder';
    end

    % use the Messenger to create the remote Responder head. That may exist
    %  already in the remote session, but we recreate it anyway
    respondercommand = sprintf(['MasterResponder=obs.util.Messenger(''%s'',%d,%d);'...
        'MasterResponder.connect;'],...
        char(java.net.InetAddress.getLocalHost.getHostName),...
        S.ResponderLocalPort,S.ResponderRemotePort);
    S.Messenger.query(respondercommand);

    if ~S.Responder.connect % can fail if the local port is busy
        S.reportError('remote Responder not answering. Consider terminating and respawning')
    else
        success=true;
    end

end
