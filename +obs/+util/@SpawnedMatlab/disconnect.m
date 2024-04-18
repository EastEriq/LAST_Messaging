function disconnect(S)
    % only disconnect the Messenger and Responder from the spawner side
    %  but do not attempt to terminate the spawned session

    % we check S.Status, because the logic is already in there.
    % If it is 'disconnected', we do not waste time in
    %  checking communication and getting a timeout without need.
    status=S.Status;
    if isa(S.Messenger,'obs.util.MessengerCommon')
        if ~strcmp(status,'disconnected')
            S.Messenger.disconnect;
        end
    else
        S.reportError('object %s does not have a sane .Messenger',S.Id)
    end
    if isa(S.Responder,'obs.util.MessengerCommon')
        if ~strcmp(status,'disconnected')
            S.Responder.disconnect;
        end
    else
        S.reportError('object %s does not have a sane .Responder',S.Id)
    end
    
    if   (isa(S.Messenger,'obs.util.MessengerCommon') && isempty(S.Messenger.LastError) ||...
             isempty(S.Messenger)) && ...
            (isa(S.Responder,'obs.util.MessengerCommon') && isempty(S.Responder.LastError) ||...
             isempty(S.Responder))
        S.Status='disconnected';
    else
        S.reportError('cannot disconnect %s Messenger or Responder',S.Id)
    end

end