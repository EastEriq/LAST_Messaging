function terminate(S,killlisteners)
    % try to quit gracefully the spawned session (if it responds normally),
    %  otherwise kill it. Needs that .Messenger is connected, for normal
    %  operation
    % By default it is attempted to terminate or kill all processses which
    %  listen on the predefined udp ports. This is useful when multiple,
    %  stale sessions are created by mistake. If this is not what is wanted,
    %  pass false as argument
    if ~exist('killlisteners','var')
        killlisteners=true;
    end

    if isa(S.Messenger,'obs.util.Messenger')

        % we check S.Status, because the logic is already in there.
        % If it is 'disconnected', we do not waste time in
        %  checking communication and getting a timeout without need.
        status=S.Status;
        if strcmp(status,'alive')
            S.Messenger.send('exit')
        end

        thisPID=S.PID;
        % if the slave is dead/unresponsive, or send() times out, kill it
        if isempty(S.Messenger.LastError)
            S.PID=[];
            S.Status='disconnected';
        elseif ~isempty(thisPID)
            S.report(['graceful exit of slave session ' S.Id ...
                ' timed out\n'])
        end

        if ~isempty(S.PID)
            S.report('attempting to kill slave process by PID %s\n',S.Id)
            S.kill
        end

        S.PID=[];
        S.Status='disconnected';

        [LM,LR]=S.listeners;
        if ~isempty(thisPID)
            LM(LM==thisPID)=[];
            LR(LR==thisPID)=[];
        end
        if ~isempty(LM)
            S.report('there are still processes listening on udp port %d\n',...
                S.Messenger.DestinationPort)
        end
        if isa(S.Responder,'obs.util.Messenger') && ~isempty(LR)
            S.report('there are still processes listening on udp port %d\n',...
                S.Responder.DestinationPort)
        end
        L=unique([LM',LR']);
        if killlisteners && ~isempty(L)
            for p=L
                S.PID=p;
                S.report('killing process %d\n',p)
                % it would be cleaner to use S.terminate, and to attempt a
                %  clean exit, but I have issues with recursivity
                S.kill 
            end
        end
    else
        % I don't think that there is a point - if at creation we didn't
        %  even get as far as creating the Messenger, unlikely that PID is
        %  sane, unless the messenger has been deleted - but it is paranoid
        %  to protect against deliberate tampering
    end
    S.PID=[];
    S.Status='disconnected';
end