classdef Messenger < obs.util.MessengerCommon 
% a version of Messenger without callback
 % not of class handle, if has to have a private callback
    
    properties (Hidden)
        CallbackRespond=true; % the datagramParser callback processes incoming commands. If false, incoming data must be explicitely read!
    end
    
    methods % creator and destructor (NonDestructor because of udp?)
        % do we need them at all? are those of the superclass sufficient?
    end
    
    methods % setters and getters of properties which must be propagated to StreamResource
        
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
