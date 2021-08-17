function disconnect(S)
    % try to quit gracefully the spawned session (if it responds normally)
    if isa(S.Messenger,'obs.util.Messenger')
        S.Messenger.send('exit')
        % if this times out, kill
        if ~isempty(S.Messenger.LastError)
            S.report(['graceful exit of slave session ' S.Id ...
                ' timed out, attempting to kill\n'])
            S.kill
        end
    end
    S.PID=[];
    S.Status='disconnected';
end