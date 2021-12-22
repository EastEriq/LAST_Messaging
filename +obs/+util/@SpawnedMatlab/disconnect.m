function disconnect(S)
    % try to quit gracefully the spawned session (if it responds normally)
    if isa(S.Messenger,'obs.util.Messenger')
        alive=S.Messenger.areYouThere;
        if alive
            S.Messenger.send('exit')
        end
        % if the slave is dead/unresponsive, or send times out, kill
        if ~alive || ~isempty(S.Messenger.LastError)
            S.report(['graceful exit of slave session ' S.Id ...
                ' timed out, attempting to kill\n'])
            S.kill
        end
    end
    S.PID=[];
    S.Status='disconnected';
end