classdef SpawnedMatlab < obs.LAST_Handle
    % Spawned matlab sessions object, including messengers for dual
    % communication

    properties
        Host  % the host on which to spawn a new matlab session
        RemoteUser=''; % username for connecting to a remote host. Empty if same user
        RemoteTerminal char ='xterm'; % 'xterm' | 'gnome-terminal' | 'desktop' | 'none'
        Logging logical =false; % create stdout and stderr log files. Must be set BEFORE connect
    end
    
    properties (Hidden)
        MessengerLocalPort % udp port on the origin computer
        MessengerRemotePort % udp port on the destinaton host
        ResponderLocalPort % udp port on the origin computer
        ResponderRemotePort % udp port on the destinaton host
    end

    properties (SetAccess=private)
        Status='disconnected'; % 'disconnected' | 'alive' | 'dead' | 'notresponding'
        PID   % process id of the new matlab session
        Messenger % the messenger between the master and the slave. Created upon .connect
        Responder % the messenger between the slave and the master. Created upon .connect
    end

    methods
        % creator
        function S=SpawnedMatlab(id)
            % creates the object, assigning an Id if provided, and loads
            %  the configuration. The actual spawning is done by the method
            %  .connect
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
            if isa(S.Messenger,'obs.util.Messenger')
                S.Messenger.DestinationHost=host;
            end
            if isa(S.Responder,'obs.util.Messenger')
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
                    %  if process doesn't exist anymore, then it the slave is dead
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
                        pingcommand=['ssh -o PasswordAuthentication=no' ...
                                      user S.Host ' ' pingcommand];
                    end
                    if system(pingcommand)
                        % system() returns 1 if grep errors, i.e. no PID
                        %   hopefully also if ssh fails
                        s='dead';
                    end
                end
            end
        end

        function set.Logging(S,tof)
            if ~isempty(S.PID)
                S.reportError('Logging state changes are effecive only before connecting')
            end
            S.Logging=tof;
        end

    end

end