classdef SpawnedMatlab < obs.LAST_Handle
    % Spawned matlab sessions objects, including messengers for dual
    % communication

    properties (SetAccess=private)
        Host
        PID
        Listener
        RemoteUser='physics';
    end

    methods
        % creator
        function S=SpawnedMatlab(host,localport,remoteport)
            % spawns one instance of matlab, creating a messenger in it,
            %  and a listener in the base workspace of the issueing matlab session
            % The process belongs to the current user if host='localhost',
            %  and to RemoteUser for any other hostname (including the same
            %  machine by IP or by resolved name)
            
            if ~exist('host','var')
                host='localhost';
            end
            if ~exist('localport','var')
                localport=8001;
            end
            if ~exist('remoteport','var')
                remoteport=8002;
            end

            S.Host=host;
            
            % additional matlab commands if we want to rise the java frame:
            %  close the editor window, change title, ...
            desktopcommand = ['closeNoPrompt(matlab.desktop.editor.getAll); ', ...
                'jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance; ', ...
                sprintf('jDesktop.getMainFrame.setTitle(''spawn %d->%d''); ',...
                remoteport,localport)];

            messengercommand = sprintf(['MasterMessenger=obs.util.Messenger(''%s'',%d,%d);'...
                'MasterMessenger.connect;'],...
                char(java.net.InetAddress.getLocalHost.getHostName),...
                localport,remoteport);
            % java trick to get the hostname from matlabcentral
            
            % we could check at this point: if there is already a corresponding Spawn
            %  messenger, and if it talks to a session (areYouThere), don't proceed.
            
            % TODO: the proper startup.m should be global
            if strcmp(host,'localhost')
                %    spawncommand='matlab -nosplash -desktop -r ';
                %    success= (system([spawncommand '"' desktopcommand messengercommand '"&'])==0);
                spawncommand='gnome-terminal -- matlab -nosplash -nodesktop -r ';
                success= (system([spawncommand '"' messengercommand '"&'])==0);
            else
                % could use rsh (ssh) (but if we want to open a window on a display,
                %   more complicate) (ssh -X perhaps for local display).
                % Needs also a some mechanism of auto login. TODO.
                % cfr: http://rebol.com/docs/ssh-auto-login.html
                %      https://serverfault.com/questions/241588/how-to-automate-ssh-login-with-password
                spawncommand='matlab -nosplash -nodesktop -r ';
                success= (system(['ssh ' S.RemoteUser '@' host ' ' ...
                                  spawncommand '"' messengercommand '"&'])==0);
            end
            if ~success
                S.reportError('spawning new session failed')
            end

            % create a listener messenger
            S.Listener=obs.util.Messenger(host,remoteport,localport);
            % live dangerously: connect the local messenger, pass to base the copy
            S.Listener.connect; % can fail if the local port is busy

            v=S.Listener.Verbose;
            S.Listener.Verbose=false;
            retries=3; i=0;
            while ~S.Listener.areYouThere && i<retries
                % retry enough times for the spawned session to be ready, tune it
                %  according to slowness of startup and timeout of the
                %  listener
                i=i+1;
            end
            S.Listener.Verbose=v;
            S.PID=S.Listener.query('feature(''getpid'')');
        end

        % destructor
        function delete(S)
            % try to quit gracefully the spawned session (if it responds normally)
            if ~isempty(S.Listener)
                % conditional, to work also for incomplete objects
                S.Listener.send('exit')
                % if this times out, kill
                if ~isempty(S.Listener.LastError)
                    S.report('graceful exit of slave session timed out, attempting to kill')
                    S.kill
                end
                S.Listener.disconnect
                delete(S.Listener)
            end
        end

    end

end