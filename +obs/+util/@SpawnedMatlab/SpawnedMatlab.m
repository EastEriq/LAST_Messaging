classdef SpawnedMatlab < obs.LAST_Handle
    % Spawned matlab sessions object, including messengers for dual
    % communication

    properties
        Host  % the host on which to spawn a new matlab session
        LocalPort % udp port on the origin computer
        RemotePort % udp port on the destinaton host
    end

    properties (SetAccess=private)
        Status='disconnected'; % 'disconnected' | 'alive' | 'dead' | 'notresponding'
        PID   % process id of the new matlab session
        Messenger % the messenger for exchanging commands betwen the master and the slave
        RemoteUser='last'; % username for connecting to a remote host
    end

    methods
        % creator
        function S=SpawnedMatlab(id)
            % creates the object, assigning an Id if provided, and loads
            %  the configuration. The actual spawning is done by the method
            %  .connect
            if ~isempty(id)
                S.Id=id;
            end
             % load configuration
            S.loadConfig(S.configFileName('create'))
        end

        % destructor
        function delete(S)
            if ~isempty(S.Messenger)
                % conditional, to work also for incomplete objects
                S.disconnect
                S.Messenger.disconnect
                delete(S.Messenger)
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
                    pingcommand=['pidof MATLAB | grep ^' num2str(S.PID)];          
                    if ~strcmp(S.Host,'localhost')
                        pingcommand=['ssh ' S.RemoteUser '@' S.Host ' ' pingcommand];
                    end
                    if system(pingcommand)
                        % system() returns 1 if grep errors, i.e. no PID
                        s='dead';
                    end
                end
            end
        end

    end

end