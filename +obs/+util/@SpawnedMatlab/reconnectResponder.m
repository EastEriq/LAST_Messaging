function success=reconnectResponder(S)
% tentative saveass function if the master of an already created spawned
% session is defective or blocked, but the responder might be available

    success=false;

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
        success=S.Responder.areYouThere;
        if success
            S.PID=S.Responder.query('feature(''getpid'')');
        end
    end

end
