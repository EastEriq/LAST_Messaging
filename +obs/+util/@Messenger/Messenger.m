classdef Messenger <handle
    
    properties
        DestinationHost='localhost'; % Destination host. Named or IP. localhost valid
        DestinationPort=50001; % Port on the destination host
        LocalPort=50000; % port on the local host. Can be same as DestinationPort if Destination hot is not localhost
        EnablePortSharing='off'; % if 'on', different processses on the same localhost can receive on the same port
        Name
    end

    properties (Hidden)
        StreamResource
    end
    
    methods
        
        function Msng=Messenger(Host,DestinationPort,LocalPort,Name)
        % Messenger channel creator, with optional arguments
        %  
        % Host: the target host talked to. Can be an IP number or a
        %  resolved name. localhost as well as 127.0.0.1 are valid.
        %  0.0.0.0 is valid? (TBD)
        % DestinationPort: the port used on the target host
        % LocalPort: (default 50000) must not be identical to
        %  DestinationPort, if host is localhost, i.e. if the messenger
        %  channel is between processes running on the same computer
            if exist('host','var')
                Msng.DestinationHost=Host;
            end
            if exist('DestinationPort','var')
                Msng.DestinationPort=DestinationPort;
            end
            if exist('LocalPort','var')
                Msng.LocalPort=LocalPort;
            else
                if true % we should check here if Host resolves to localhost
                    Msng.LocalPort=Msng.DestinationPort;
                end
            end
            if exist('Name','var')
                Msng.Name=Name;
            end
            % now create the corresponding udp object: first clean up
            %  leftovers,
            try
                % try to delete a formed object with the same destination
                % (could also check for same name and local port, but that would be
                %  more errror prone, probably)
                delete(instrfind('RemoteHost',Msng.DestinationHost,'RemotePort',Msng.DestinationPort))
            catch
                Msng.LastError=['cannot delete udp object ' Msng.DestinationHost  ':' ...
                    num2str(Msng.DestinationPort) ];
            end
            % then create
            try
                Msng.StreamResource=udp(Msng.DestinationHost,Msng.DestinationPort,...
                    'LocalPort',Msng.DestinationPort,...
                    'EnablePortSharing','off',...
                    'Name',Msng.Name);
            catch
                Msng.LastError=['cannot create udp object ' Msng.DestinationHost  ':' ...
                    num2str(Msng.DestinationPort) ];
            end           
        end
        
    end
end