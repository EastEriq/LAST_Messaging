function kill(S)
% tries to kill forcefully a (non-responding perhaps) spawned Matlab
%  session, by PID
if ~isempty(S.PID)
    if strcmp(S.Host,'localhost')
        system(['kill -9 ' num2str(S.PID)]);
    else
        % try with ssh - TODO
        system(['ssh ' S.RemoteUser '@' S.Host ' kill -9 ' num2str(S.PID)]);
    end
    S.PID=[];
end
    S.Status='disconnected';
end
