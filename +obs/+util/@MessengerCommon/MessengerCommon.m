classdef MessengerCommon < obs.LAST_Handle % common superclass of Messenger and Listener
    
    properties
        DestinationHost='localhost'; % (default) Destination host. Named or IP. localhost valid.
        DestinationPort=50001; % (default) port on the destination host
        LocalPort; % port on the local host. Can be same as DestinationPort if DestinationHost is not localhost
        EnablePortSharing='on'; % if 'on', different processses on the same localhost can receive on the same port
        Name % free text, useful for labelling the Messenger object
        MessagesSent=0; % incrementing number of messages sent
    end

    properties (Hidden)
        StreamResource
        LastMessage % storing the last received message, to implement query responses
    end
    
    properties (SetAccess=private, Hidden, Transient)
        % this good to get the local hostname without racing on stdout
        %  (unlike the private method. localHostName), but cannot get the IP.
        %  Whithin LAST domain it may be ok, but if the IP is needed, the
        %  property needs to be rewritten otherwise. OTOH, the name is
        %  never expected to change within the lifetime of the Messenger
        LocalHost char =char(java.net.InetAddress.getLocalHost.getHostName);
    end

   methods % creator and destructor (NonDestructor because of udp?)
        
        function Msng=MessengerCommon(Host,DestinationPort,LocalPort,Name)
        % Messenger channel creator, with optional arguments
        %  
        % Host: the target host talked to. Can be an IP number or a
        %  resolved name. localhost as well as 127.0.0.1 are valid.
        %  0.0.0.0 is valid? (TBD)
        %  Overridden when replying to messages received from other
        %  hosts/ports
        % DestinationPort: the port used on the target host
        % LocalPort: (default []) must not be identical to
        %  DestinationPort, if host is localhost, i.e. if the messenger
        %  channel is between processes running on the same computer
        % Name: free text name (default:
        %   'localhost:LocalPort->Host:DestinationPort')
            if exist('Host','var')
                Msng.DestinationHost=Host;
            end
            if exist('DestinationPort','var') && ~isempty(DestinationPort)
                Msng.DestinationPort=DestinationPort;
            else
                Msng.DestinationPort=50001;
            end
            if exist('LocalPort','var')
                Msng.LocalPort=LocalPort;
            else
                LocalPort=[]; % this means, let the system assign at random
            end
            if strcmp(resolvehost(Msng.DestinationHost,'address'),...
                            resolvehost('localhost','address'))
               if ~isempty(LocalPort) && ~isempty(Msng.DestinationPort) &&...
                       Msng.DestinationPort==LocalPort
                 warning('using the same ports for messengers on the same host is not reccommended')
               end
            end

            if exist('Name','var')
                Msng.Name=Name;
            else
                Msng.Name=sprintf('%s:%d->%s:%d',resolvehost('localhost','name'),...
                                  LocalPort,Msng.DestinationHost,...
                                  Msng.DestinationPort);       
            end
            % now create the corresponding udp object: first clean up
            %  leftovers,
            try
                % try to delete former udp objects with the same destination
                delete(instrfind('RemoteHost',Msng.DestinationHost,'RemotePort',Msng.DestinationPort))
            catch
                Msng.reportError('cannot delete udp object %s:%d',...
                    Msng.DestinationHost, Msng.DestinationPort);
            end
            try
                % try to delete former udp objects pointing to the same
                %  remote host:port. They are per se legitimate,
                %  but it may be better to remove duplicates
                delete(instrfind('RemotePort',Msng.DestinationPort,...
                                 'RemoteHost',Msng.DestinationHost))
            catch
                Msng.reportError('cannot delete udp object %s:%d',...
                     Msng.DestinationHost, Msng.DestinationPort);
            end
            % then create
            try
                Msng.StreamResource=udp(Msng.DestinationHost,Msng.DestinationPort,...
                    'EnablePortSharing','on',...
                    'InputBufferSize',4096,...
                    'OutputBufferSize',4096,...
                    'Name',Msng.Name);
                if ~isempty(LocalPort)
                    Msng.StreamResource.LocalPort = LocalPort;
                else
                    % Msng.LocalPort will get a value only when connected
                end
            catch
                Msng.reportError('cannot create udp object %s:%d',...
                    Msng.DestinationHost,Msng.DestinationPort);
            end
            % do this as last; maybe it mitigates the race on stdout,
            %  which produces bogus readouts when redirecting stdout for logging 
            Msng.LocalHost=Msng.localHostName;
        end
        
        function delete(Msng)
            % this is not called when clearing the object? Probably it is a
            % NonDestructor, because it calls subproperties of .StreamResource
            % Thus:
            % M=obs.util.Messenger(....); M.connect; M.disconnect; clear M
            %   and
            % M=obs.util.Messenger(....); M.connect; delete(M)
            %   correctly delete the udp resource (which disappears from instrfind), but
            % M=obs.util.Messenger(....); M.connect; clear M
            %    not. Why?
            % Moreover, delete(instrfind) in the latter case enters this
            %  destructor, which is odd.
            % (Maybe, that is an issue for Messengers, but not for Listeners?)
            try
                Msng.disconnect;
                delete(Msng.StreamResource); % doesn't delete it? I still see it in instrfind
            catch
                Msng.reportError('cannot delete udp resource of %s %s',...
                    class(Msng),Msng.Name)
                % this cannot be reported in Msng.LastError, nor the error
                %  can contain more identifying information, because the
                %  object is not anymore
            end
        end
        
    end
    
    methods % setters and getters of properties which must be propagated to StreamResource
        
        function set.LocalPort(Msng,port)
            try
                if isempty(port)
                    % quirk of udp, which lets only scalar ports to be set
                    % - but 0 translates in []
                    Msng.StreamResource.LocalPort=0;
                else
                    Msng.StreamResource.LocalPort=port;
                end
                Msng.LocalPort=port;
            catch
                Msng.reportError('could not change LocalPort. Maybe connection is open?')
            end
        end
        
        function set.DestinationPort(Msng,port)
            try
                Msng.StreamResource.RemotePort=port;
                Msng.DestinationPort=port;
            catch
                Msng.reportError('could not change DestinationPort. Maybe connection is open?')
            end
        end
        
        
        function set.DestinationHost(Msng,host)
            % seems that this can be changed even with udp opened
            try
                Msng.StreamResource.RemoteHost=host;
                Msng.DestinationHost=host;
            catch
                Msng.reportError('could not change DestinationHost. Maybe connection is open?')
            end
        end
        
        function set.EnablePortSharing(Msng,state)
            % accept state='on', 'off', true, false, 0, 1
            if ischar(state)
                if ~strcmp(state,'on') && ~strcmp(state,'off')
                    Msng.reportError('invalid EnablePortSharing. Should be ''on'' or ''off''')
                end
            elseif islogical(state) || isa(state,'numeric')
                if state
                    state='on';
                else
                    state='off';
                end
            else
            end
            try
                Msng.StreamResource.EnablePortSharing=state;
                Msng.EnablePortSharing=state;
            catch
                Msng.reportError('could not change EnablePortSharing. Maybe connection is open?')
            end
        end

        function set.Name(Msng,name)
            % seems that this can be changed with udp opened
            try
                Msng.StreamResource.Name=name;
                Msng.Name=name;
            catch
                Msng.reportError('could not change Name')
            end
        end

        % getters directly from StreamResource, not to lose sync with it:
        %  would be a good idea, but we have a problem at creation, because
        %  StreamResource is created last. try-catch those cases
        function port=get.LocalPort(Msng)
            try
                port=Msng.StreamResource.LocalPort;
            catch
                Msng.reportError('could not get LocalPort. StreamResource not created?')
            end
        end

        % don't get these properties from StreamResource, whose desination
        %  can be changed on the fly to reply to out-of-channel mesages
        % Rather, the values stored in the property should be the fallback
        %  ones for the preferred reply channel
%         function port=get.DestinationPort(Msng)
%             port=Msng.StreamResource.RemotePort;
%         end
% 
%         function host=get.DestinationHost(Msng)
%             try
%                 host=Msng.StreamResource.RemoteHost;
%             catch
%                 host=Msng.DestinationHost;
%             end
%         end
        
        function state=get.EnablePortSharing(Msng)
            state=Msng.StreamResource.EnablePortSharing;
        end
        
        function name=get.Name(Msng)
            name=Msng.StreamResource.Name;
        end
        
    end
end
