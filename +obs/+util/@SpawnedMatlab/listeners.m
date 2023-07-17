function [Mpids,Rpids]=listeners(S)
% Find PIDs of processes connected to the destination ports of the
%  .Messenger and .Responder. Useful for detecting nonresponsive slaves,
%  multiple listeners, etc.
  
    if isempty(S.RemoteUser)
        user='';
    else
        user=[S.RemoteUser '@'];
    end
    
    if isa(S.Messenger,'obs.util.Messenger')
        [~,a]=system(sprintf('rsh -o PasswordAuthentication=no %s%s "lsof -ti :%d"', ...
            user, S.Messenger.DestinationHost, S.Messenger.DestinationPort));
        Mpids=str2num(a);
    else
        if ~isempty(S.Messenger)
            S.reportError('.Messenger is not a messenger')
        end
        Mpids=[];
    end
    
    if nargout>1
        if isa(S.Responder,'obs.util.Messenger')
            [~,a]=system(sprintf('rsh -o PasswordAuthentication=no %s%s "lsof -ti :%d"', ...
                user, S.Responder.DestinationHost, S.Responder.DestinationPort));
            Rpids=str2num(a);
        else
            if ~isempty(S.Responder)
                S.reportError('.Responder is not a messenger')
            end
            Rpids=[];
        end
    end
