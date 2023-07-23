classdef Messenger < obs.LAST_Handle % not of class handle, if has to have a private callback
    
    properties
        DestinationHost='localhost'; % Destination host. Named or IP. localhost valid
        DestinationPort=50001; % Port on the destination host
        LocalPort; % port on the local host. Can be same as DestinationPort if DestinationHost is not localhost
        EnablePortSharing='on'; % if 'on', different processses on the same localhost can receive on the same port
        Name % free text, useful for labelling the Messenger object
        MessagesSent=0; % incrementing number of messages sent
    end

    properties (Hidden)
        StreamResource
        LastMessage % storing the last received message, to implement query responses
        CallbackRespond=true; % the datagramParser callback processes incoming commands. If false, incoming data must be explicitely read!
    end
    
    methods % creator and destructor (NonDestructor because of udp?)
        
        function Msng=Messenger(Host,DestinationPort,LocalPort,Name)
        % Messenger channel creator, with optional arguments
        %  
        % Host: the target host talked to. Can be an IP number or a
        %  resolved name. localhost as well as 127.0.0.1 are valid.
        %  0.0.0.0 is valid? (TBD)
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
                % try to delete a formed object with the same destination
                % (could also check for same name and local port, but that would be
                %  more errror prone, probably)
                delete(instrfind('RemoteHost',Msng.DestinationHost,'RemotePort',Msng.DestinationPort))
            catch
                Msng.reportError('cannot delete udp object %s:%d',...
                    Msng.DestinationHost, Msng.DestinationPort);
            end
            % then create
            try
                Msng.StreamResource=udp(Msng.DestinationHost,Msng.DestinationPort,...
                    'EnablePortSharing','on',...
                    'InputBufferSize',2048,...
                    'OutputBufferSize',2048,...
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
            try
                Msng.disconnect;
                delete(Msng.StreamResource); % doesn't delete it? I still see it in instrfind
            catch
                Msng.reportError('cannot delete Messenger udp resource')
                % this cannot be reported in Msng.LastError, nor the error
                %  can contain more identifying information, because the
                %  object is not anymore
            end
        end
        
    end
    
    methods % setters and getters of properties which must be propagated to StreamResource
        
        function set.LocalPort(Msng,port)
            try
                Msng.StreamResource.LocalPort=port;
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
                Msng.reportError('could get LocalPort. StreamResource not created?')
            end
        end
 
        function port=get.DestinationPort(Msng)
            port=Msng.StreamResource.RemotePort;
        end

        function host=get.DestinationHost(Msng)
            try
                host=Msng.StreamResource.RemoteHost;
            catch
                host=Msng.DestinationHost;
            end
        end
        
        function state=get.EnablePortSharing(Msng)
            state=Msng.StreamResource.EnablePortSharing;
        end
        
        function name=get.Name(Msng)
            name=Msng.StreamResource.Name;
        end
        
        function set.CallbackRespond(Msng,flag)
            if flag
                Msng.StreamResource.DatagramReceivedFcn=@Msng.datagramParser;
            else
                Msng.StreamResource.DatagramReceivedFcn='';
            end
            Msng.CallbackRespond=flag;
        end

    end
    
end