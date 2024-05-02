function kill(S)
% tries to kill forcefully a (non-responding perhaps) spawned Matlab
%  session, by PID
if ~isempty(S.PID)
    [~,r]=system(''); % to flush previous stdout
    if strcmp(S.Host,'localhost')
        success=system(['kill -9 ' num2str(S.PID)]);
    else
        % try with ssh
        if ~isempty(S.RemoteUser)
            account = [S.RemoteUser '@' S.Host];
        else
            % no user specified, i.e. automatic login with the same user
            %  name
            account = S.Host;
        end
        success=system(['ssh ' account ' kill -9 ' num2str(S.PID)]);
    end
    if success==0
        S.PID=[];
        S.Status='disconnected';
    end
else
    S.report('empty process ID, no idea about what to kill\n')
end
