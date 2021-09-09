        function connect(S,host,messengerlocalport,messengerremoteport,...
                                responderlocalport,responderremoteport)
            % spawns one instance of matlab, creating two messengers in it,
            %  and two listeners in the base workspace of the issueing matlab session
            % The process belongs to the current user if host='localhost',
            %  and to RemoteUser for any other hostname (including the same
            %  machine by IP or by resolved name)
            % For consistency, matlab is always launched in $HOME, so that
            %  a startup.m file can be assumed to be always found there

            localdesktop=false;
            remoteterminal='xterm'; % xterm | gnome-terminal

            if ~isempty(S.PID)
                S.reportError('PID already exists, probably the slave is already connected')
                return
            end

            if exist('host','var')
                S.Host=host;
            elseif isempty(S.Host)
                S.Host='localhost';
            end
            
            if exist('messengerlocalport','var')
                S.MessengerLocalPort=messengerlocalport;
            elseif isempty(S.MessengerLocalPort)
                S.MessengerLocalPort=8001;
            end
            
            if exist('messengerremoteport','var')
                S.MessengerRemotePort=messengerremoteport;
            elseif isempty(S.MessengerRemotePort)
                S.MessengerRemotePort=8002;
            end
            
            if exist('responderlocalport','var')
                S.ResponderLocalPort=responderlocalport;
            elseif isempty(S.ResponderLocalPort)
                S.ResponderLocalPort=9001;
            end
            
            if exist('responderremoteport','var')
                S.ResponderRemotePort=responderremoteport;
            elseif isempty(S.ResponderRemotePort)
                S.ResponderRemotePort=9002;
            end
            
            % use xterm or gnome-terminal depending on which is
            %  installed sanely
            % dbus-launch from
            % https://unix.stackexchange.com/questions/407831/how-can-i-launch-gnome-terminal-remotely-on-my-headless-server-fails-to-launch
            switch remoteterminal
                case 'xterm'
                    xtitle=sprintf('-T "matlab_%s"',S.Id);
                    spawncommand=['cd ~; xterm ' xtitle ,...
                                  ' -e matlab -nosplash -nodesktop -r  '];
                case 'gnome-terminal'
                    spawncommand=['cd ~; export $(dbus-launch);'...
                        'gnome-terminal -- matlab -nosplash -nodesktop -r '];
            end

            % additional matlab commands if we want to rise the java frame:
            %  close the editor window, change title, ...
            desktopcommand = ['closeNoPrompt(matlab.desktop.editor.getAll); ', ...
                'jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance; ', ...
                sprintf('jDesktop.getMainFrame.setTitle(''spawn %d->%d''); ',...
                S.MessengerRemotePort,S.MessengerLocalPort), 'clear jDesktop;'];

            messengercommand = sprintf(['MasterMessenger=obs.util.Messenger(''%s'',%d,%d);'...
                'MasterMessenger.connect;'],...
                char(java.net.InetAddress.getLocalHost.getHostName),...
                S.MessengerLocalPort,S.MessengerRemotePort);
            % java trick to get the hostname from matlabcentral
            
            % we could check at this point: if there is already a corresponding Spawn
            %  messenger, and if it talks to a session (areYouThere), don't proceed.
            
            % TODO: the proper startup.m should be global
            if strcmp(S.Host,'localhost')
                if localdesktop
                    spawncommand='cd ~; matlab -nosplash -desktop -r ';
                    success= (system([spawncommand '"' desktopcommand messengercommand '"&'])==0);
                else
                    success= (system([spawncommand '"' messengercommand '" &'])==0);
                end
            else
                % Needs also a some mechanism of auto login. TODO.
                % cfr: http://rebol.com/docs/ssh-auto-login.html
                %      https://serverfault.com/questions/241588/how-to-automate-ssh-login-with-password

                % escape all characters which have to be escaped to
                %  transmit the command over ssh
                if strcmp(remoteterminal,'xterm')
                    messengercommand = strrep(messengercommand,'''','\''');
                    messengercommand = strrep(messengercommand,'(','\(');
                    messengercommand = strrep(messengercommand,')','\)');
                    messengercommand = strrep(messengercommand,';','\\;');
                end

                % we use ssh -X. This allows opening locally the remote
                %  matlab windows, though it may be slow (expecially
                %  graphics in software OpenGL)
                success= (system(['ssh -X ' S.RemoteUser '@' S.Host ' ' ...
                                  spawncommand '"' messengercommand '" &'])==0);
            end
            if success
                S.LastError='';
            else
                S.reportError('spawning new session failed')
            end

            % create a listener messenger
            S.Messenger=obs.util.Messenger(S.Host,S.MessengerRemotePort,...
                                           S.MessengerLocalPort);
            if ~isempty(S.Id)
                S.Messenger.Id=[S.Id '.Messenger'];
            else
                S.Messenger.Id='spawn.Messenger';
            end

            S.Messenger.connect; % can fail if the local port is busy

            % save the current verbose and timeout values, and temporarily
            %  set a shorter timeout
            v=S.Messenger.Verbose;
            t=S.Messenger.StreamResource.Timeout;
            S.Messenger.Verbose=false;
            S.Messenger.StreamResource.Timeout=1;
            retries=25; i=0;
            while ~S.Messenger.areYouThere && i<retries
                % retry enough times for the spawned session to be ready, tune it
                %  according to slowness of startup and timeout of the
                %  listener
                i=i+1;
            end               
            S.Messenger.Verbose=v;
            S.Messenger.StreamResource.Timeout=t;
            if i>=retries
                S.reportError(sprintf(['connection with session %s not ' ...
                                       'estabilished, aborting'], S.Id))
                return
            end
            S.PID=S.Messenger.query('feature(''getpid'')');
            
            % create a second "Responder" messenger, for dual communication
            %  without intermixing of messages. If we are here the
            %  MasterMessenger should already be functioning
            
            % local head
            S.Responder=obs.util.Messenger(S.Host,S.ResponderRemotePort,...
                                           S.ResponderLocalPort);
            if ~isempty(S.Id)
                S.Responder.Id=[S.Id '.Responder'];
            else
                S.Messenger.Id='spawn.Messenger';
            end
            S.Responder.connect; % can fail if the local port is busy
            % remote head
            respondercommand = sprintf(['MasterResponder=obs.util.Messenger(''%s'',%d,%d);'...
                'MasterResponder.connect;'],...
                char(java.net.InetAddress.getLocalHost.getHostName),...
                S.ResponderLocalPort,S.ResponderRemotePort);
            S.Messenger.query(respondercommand);

        end
