classdef SpawnedMatlab < obs.LAST_Handle
    % Spawned matlab sessions object, including messengers for dual
    % communication

    properties
        Host  = 'localhost'; % the host on which to spawn a new matlab session
        RemoteUser=''; % username for connecting to a remote host. Empty if same user
        RemoteTerminal char {mustBeMember(RemoteTerminal,{'xterm','gnome-terminal','desktop','none'})} = 'xterm';
        RemoteMessengerFlavor char {mustBeMember(RemoteMessengerFlavor,{'messenger','listener'})} = 'messenger';
        Logging logical = false; % create stdout and stderr log files. Must be set BEFORE connect
        LoggingDir char ; % directory where to log. Must be set BEFORE connect
    end
    
    properties (Hidden)
        MessengerLocalPort uint16 =[]; % udp port on the origin computer
        MessengerRemotePort uint16 = 8002; % udp port on the destinaton host
        ResponderLocalPort  uint16 =[]; % udp port on the origin computer
        ResponderRemotePort uint16 = 9002; % udp port on the destinaton host
        % ssh options: avoid asking for a password, shorten timeout, and
        %  automatically accept instead of asking confirmation of
        %  fingerprint
        SshOptions char ='-o ConnectTimeout=5 -o PasswordAuthentication=no -o StrictHostKeyChecking=no';
    end

    properties (SetAccess=private)
        Status='disconnected'; % 'disconnected' | 'alive' | 'dead' | 'notresponding'
        PID   % process id of the new matlab session
        Messenger % the messenger between the master and the slave. Created upon .connect
        Responder % the messenger between the slave and the master. Created upon .connect
    end
    
    properties (SetAccess=private, Hidden, Transient)
        LocalHost char = obs.util.localHostName;
    end

    methods
        % creator
        function S=SpawnedMatlab(id)
            % creates the object, assigning an Id if provided, and loads
            %  the configuration. The actual spawning is done by the method
            %  .spawn, and communication is further established by .connect
            if ~exist('id','var')
                id='';
            end
            if ~isempty(id)
                S.Id=id;
            end
            % load configuration
            S.loadConfig(S.configFileName('create'))
        end

        % destructor
        function delete(S)
            % here we could consider to either to .terminate the spawned
            %  session or to .disconnect, it, leaving the slave available
            %  for reconnection from another master. The former is the use
            %  case of unitCS slaves, but the latter is more appropriate
            %  for superunits (e.g. in the case we want to end the
            %  superunit control session, and restart it somewhere else,
            %  while we keep monitoring existing slaves).
            % S.terminate
            if ~strcmp(S.Status,'disconnected')
                S.report('just disconnecting, not terminating the remote session %s\n',...
                    S.Id)
                S.disconnect;
            end
            if ~isempty(S.Responder)
                S.Responder.disconnect
                delete(S.Responder)
            end
            if ~isempty(S.Messenger)
                % conditional, to work also for incomplete objects
                S.disconnect
                S.Messenger.disconnect
                delete(S.Messenger)
            end
        end

        % getters and setters: propagate properties to messengers
        function set.Host(S,host)
            S.Host=host;
            if isa(S.Messenger,'obs.util.MessengerCommon')
                S.Messenger.DestinationHost=host;
            end
            if isa(S.Responder,'obs.util.MessengerCommon')
                S.Responder.DestinationHost=host;
            end
        end

        % getter for Status
        function s=get.Status(S)
            if isempty(S.PID)
                s='disconnected';
            else
                if S.Messenger.areYouThere
                    s='alive';
                else
                    s='notresponding';
                    %  if process doesn't exist anymore, then the slave is dead
                    pingcommand=['pidof MATLAB | grep ' num2str(S.PID)];
                    % not perfect, a short S.PID could match that of
                    %  another MATLAB process, but frankly it is pretty
                    %  unlikely. I can't quickly think of a better solution
                    if ~strcmp(S.Host,'localhost')
                        if isempty(S.RemoteUser)
                            user='';
                        else
                            user=[S.RemoteUser '@'];
                        end
                        pingcommand=['ssh ' S.SshOptions ' ' ...
                                     user S.Host ' ' pingcommand];
                    end
                    [result,~]=system(pingcommand); % to suppress output on stdout
                    if result
                        % system() returns 1 if grep errors, i.e. no PID
                        %   hopefully also if ssh fails
                        s='dead';
                    end
                end
            end
        end

        function set.Logging(S,tof)
            if ~isempty(S.PID)
                S.reportError('Logging state changes are effecive only before connecting!')
                return
            end
            S.Logging=tof;
        end

        function set.LoggingDir(S,path)
            if ~isempty(S.PID)
                S.reportError('Logging directory changes are effecive only before connecting!')
                return
            end
            if ~isfolder(path)
                try
                    mkdir(path);
                catch
                    S.reportError('logging directory nonexistent and impossible to be created')
                end
            end
            S.LoggingDir=path;
        end

    end

end