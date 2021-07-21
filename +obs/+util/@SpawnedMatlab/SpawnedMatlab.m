classdef SpawnedMatlab < obs.LAST_Handle
    % Spawned matlab sessions object, including messengers for dual
    % communication

    properties
        Host  % the host on which to spawn a new matlab session
        LocalPort % udp port on the origin computer
        RemotePort % udp port on the destinaton host
    end

    properties (SetAccess=private)
        PID   % process id of the new matlab session
        Messenger % the messenger for exchanging commands betwen the master and the slave
        RemoteUser='physics'; % username for connecting to a remote host
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
            % try to quit gracefully the spawned session (if it responds normally)
            if ~isempty(S.Messenger)
                % conditional, to work also for incomplete objects
                S.Messenger.send('exit')
                % if this times out, kill
                if ~isempty(S.Messenger.LastError)
                    S.report('graceful exit of slave session timed out, attempting to kill')
                    S.kill
                end
                S.Messenger.disconnect
                delete(S.Messenger)
            end
        end

    end

end