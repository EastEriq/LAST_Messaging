function success=reconnectResponder(SV)
% tentative saveass function if the master of an already created spawned
% session is defective or blocked, but the responder might be available

    success=false(1,numel(SV));

    for i=1:numel(SV)
        S=SV(i);
        
        if isempty(S.Host)
            S.Host='localhost';
        end
        
        if isempty(S.ResponderRemotePort)
            S.ResponderRemotePort=9002;
        end
        
        % local Responder head
        S.Responder=obs.util.Messenger(S.Host,S.ResponderRemotePort,...
            S.ResponderLocalPort);
        if ~isempty(S.Id)
            S.Responder.Id=[S.Id '.Responder'];
        else
            S.Responder.Id='spawn.Responder';
        end
        
        if ~S.Responder.connect % can fail if the local port is busy
            S.reportError('remote Responder not answering. Consider terminating and respawning')
        else
            S.ResponderLocalPort=S.Responder.LocalPort; % in cause empty ->auto
            success(i)=S.Responder.areYouThere;
            if success(i)
                S.PID=S.Responder.query('feature(''getpid'')');
            end
        end
        
    end
