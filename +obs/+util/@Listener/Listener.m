classdef Listener < obs.util.MessengerCommon 
% A version of Messenger without callback. Normally used in a session of
%  Matlab which polls it infinitely in a loob.
% To start an infinite while loop, use the method Listener.start.
% To abort the loop with a command sent via the messenger, send to it the
%  command 'return' from another messenger communicating with it.
    
    methods % creator and destructor (NonDestructor because of udp?)
        % do we need them at all? are those of the superclass sufficient?        
    end


end
