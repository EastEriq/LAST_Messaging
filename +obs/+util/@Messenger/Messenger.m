classdef Messenger <handle
    
    properties
        Address={'localhost',50000}; % Destination host and port
        Name='';
    end

    properties (Hidden)
        StreamResource
    end
    
    methods
        
        function Msng=Messenger(host,port,name)
        % creator, with optional arguments host, port and name
            if exist('host','var')
                Msng.Address{1}=host;
            end
            if exist('port','var')
                Msng.Address{2}=port;
            end
            if exist('name','var')
                Msng.Name=name;
            end
        end
        
    end
end