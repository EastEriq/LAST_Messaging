        function connect(S,host,localport,remoteport)
            % spawns one instance of matlab, creating a messenger in it,
            %  and a listener in the base workspace of the issueing matlab session
            % The process belongs to the current user if host='localhost',
            %  and to RemoteUser for any other hostname (including the same
            %  machine by IP or by resolved name)
            
            if exist('host','var')
                S.Host=host;
            elseif isempty(S.Host)
                S.Host='localhost';
            end
            
            if exist('localport','var')
                S.LocalPort=localport;
            elseif isempty(S.LocalPort)
                S.LocalPort=8001;
            end
            
            if exist('remoteport','var')
                S.RemotePort=remoteport;
            elseif isempty(S.RemotePort)
                S.RemotePort=8002;
            end
            
            % additional matlab commands if we want to rise the java frame:
            %  close the editor window, change title, ...
            desktopcommand = ['closeNoPrompt(matlab.desktop.editor.getAll); ', ...
                'jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance; ', ...
                sprintf('jDesktop.getMainFrame.setTitle(''spawn %d->%d''); ',...
                S.RemotePort,S.LocalPort)];

            messengercommand = sprintf(['MasterMessenger=obs.util.Messenger(''%s'',%d,%d);'...
                'MasterMessenger.connect;'],...
                char(java.net.InetAddress.getLocalHost.getHostName),...
                S.LocalPort,S.RemotePort);
            % java trick to get the hostname from matlabcentral
            
            % we could check at this point: if there is already a corresponding Spawn
            %  messenger, and if it talks to a session (areYouThere), don't proceed.
            
            % TODO: the proper startup.m should be global
            if strcmp(S.Host,'localhost')
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
                success= (system(['ssh ' S.RemoteUser '@' S.Host ' ' ...
                                  spawncommand '"' messengercommand '"&'])==0);
            end
            if ~success
                S.reportError('spawning new session failed')
            end

            % create a listener messenger
            S.Messenger=obs.util.Messenger(S.Host,S.RemotePort,S.LocalPort);
            S.Messenger.connect; % can fail if the local port is busy

            v=S.Messenger.Verbose;
            S.Messenger.Verbose=false;
            retries=3; i=0;
            while ~S.Messenger.areYouThere && i<retries
                % retry enough times for the spawned session to be ready, tune it
                %  according to slowness of startup and timeout of the
                %  listener
                i=i+1;
            end
            S.Messenger.Verbose=v;
            S.PID=S.Messenger.query('feature(''getpid'')');
        end
