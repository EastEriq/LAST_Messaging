function kill(SV)
% tries to kill forcefully a (non-responding perhaps) spawned Matlab
%  session, by PID if known, if not by looking for listeners
    for i=1:numel(SV)
        S=SV(i);
        if isempty(S.PID)
            % try to recover PID from listeners
            [Mpids,Rpids]=S.listeners;
            PID=unique([Mpids,Rpids]);
            if ~isempty(PID)
                % if there is more than one zombie, relate to the first
                S.PID=PID(1);
            end
        end
        if ~isempty(S.PID)
            [~,r]=system(''); % to flush previous stdout
            if strcmp(S.Host,'localhost')
                [success,r]=system(['kill -9 ' num2str(S.PID)]);
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
                S.LastError='';
            else
                if ~contains(r,'No such process') % fragile
                    % we don't want to set LastError if the process
                    %  vanished by itself, we do if we can't execute
                    %  commands
                    S.reportError('cannot send kill command on %s',S.Host)
                end
            end
        else
            S.report('empty process ID, no idea about what to kill\n')
        end
    end