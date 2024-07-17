function success=connect(SV)
% attempts to connect to a [vector of] spawned matlab session, already created by
% .spawn, perhaps even by another matlab process

    success=false(1,numel(SV));

    for i=1:numel(SV)
        S=SV(i);
        if isempty(S.Host)
            S.Host='localhost';
        end
        
        if isempty(S.MessengerRemotePort)
            S.MessengerRemotePort=8002;
        end
        
        if isempty(S.ResponderRemotePort)
            S.ResponderRemotePort=9002;
        end
        
        % (re)create a messenger for talking to the spawned session
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
        retries=60; j=0;
        % pause(1.5) % give time to the remote messenger to start working
        while ~S.Messenger.areYouThere && j<retries
            % retry enough times for the spawned session to be ready, tune it
            %  according to slowness of startup and timeout of the
            %  listener
            j=j+1;
        end
        S.Messenger.Verbose=v;
        S.Messenger.StreamResource.Timeout=t;
        if j>=retries
            S.reportError(['connection with session %s not ' ...
                'estabilished, aborting'], S.Id)
            continue
        end
        
        % at this point, set the default MasterMessenger.DestinationPort
        %  in the slave (which was not known before the master side udp port was
        %  opened
        % S.Messenger.send(sprintf('MasterMessenger.DestinationPort=%d;',S.Messenger.LocalPort));
        
        S.PID=S.Messenger.query("feature('getpid')");
        
        hostname=S.LocalHost;
        
        % create a second "Responder" messenger, for dual communication
        %  without intermixing of messages. If we are here the
        %  MasterMessenger should already be functioning
        
        % display a takeover message on the spawned session, and on the
        %  original spawner
        % TODO: see that this works also for a RemoteMessengerFlavor='listener'
        if S.Messenger.query("exist('MasterResponder','var') && isa(MasterResponder,'obs.util.MessengerCommon')")
            msg=sprintf('PID %d on %s is now taking control of the spawned session',...
                feature('getpid'),hostname);
            % can we also find out the .Id of the spawned session on the originator?
            S.Messenger.send(sprintf('disp(''%s'')',msg));
            % use the old remote responder, to send the same takeover message
            % to the original controller. Does it always work?
            S.Messenger.send(sprintf("MasterResponder.send('disp(''%s'')');",...
                msg));
            % it would be nice to include in the message also the name or the Id
            %  of the spawned session that is being taken over, but how do we
            %  know how the SpawnedMatlab object is called in the original
            %  spawner?
        end
        % in fact we are not really "taking over". With Message.From and
        % .ReplyTo, anyone knowing DestinationPort can always send queries.
        
        % local Responder head
        S.Responder=obs.util.Messenger(S.Host,S.ResponderRemotePort,...
            S.ResponderLocalPort);
        if ~isempty(S.Id)
            S.Responder.Id=[S.Id '.Responder'];
        else
            S.Responder.Id='spawn.Responder';
        end
        
        S.Responder.connect; % can fail if the local port is busy
        
        % use the Messenger to create the remote Responder head. That may exist
        %  already in the remote session, but we recreate it anyway
        respondercommand = sprintf(['MasterResponder=obs.util.Messenger(''%s'',[%d],%d);'...
            'MasterResponder.connect;'],hostname,...
            S.ResponderLocalPort,S.ResponderRemotePort);
        S.Messenger.query(respondercommand);
        
        if ~S.Responder.areYouThere
            S.reportError('remote Responder not answering. Consider terminating and respawning')
        else
            S.ResponderLocalPort=S.Responder.LocalPort; % in case empty ->auto
            success(i)=true;
        end

    end
end
