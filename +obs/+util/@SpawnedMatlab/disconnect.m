function disconnect(S)
    % try to quit gracefully the spawned session (if it responds normally)

    if isa(S.Messenger,'obs.util.Messenger')

        % we check S.Status, because the logic is already in there.
        % If it is 'disconnected', we do not waste time in
        %  checking communication and getting a timeout without need.
        status=S.Status;
        if strcmp(status,'alive')
            S.Messenger.send('exit')
        end

        % if the slave is dead/unresponsive, or send() times out, kill it
        if isempty(S.Messenger.LastError)
            S.PID=[];
            S.Status='disconnected';
        else
            S.report(['graceful exit of slave session ' S.Id ...
                ' timed out'])
        end

        if ~isempty(S.PID)
            S.report('attempting to kill slave session %s\n',S.Id)
            S.kill
        end
    end
    S.PID=[];
    S.Status='disconnected';
end