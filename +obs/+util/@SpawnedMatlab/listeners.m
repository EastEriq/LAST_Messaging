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
        [~,a]=system(sprintf('ssh %s %s%s "lsof -ti :%d"', ...
            S.SshOptions, user, S.Messenger.DestinationHost, S.Messenger.DestinationPort));
    else
        if isempty(S.Messenger)
            % if the Messenger has not yet been created, check using the
            %  values of the relevant properties known to the SpawnedMatlab
            %  object itself
            [~,a]=system(sprintf('ssh %s %s%s "lsof -ti :%d"', ...
                S.SshOptions, user, S.Host, S.MessengerRemotePort));
        else
            S.reportError('.Messenger is not a messenger')
            a='';
        end
    end
    Mpids=str2num(a);
    
    if nargout>1
        if isa(S.Responder,'obs.util.Messenger')
            [~,a]=system(sprintf('ssh -o %s %s%s "lsof -ti :%d"', ...
                S.SshOptions, user, S.Responder.DestinationHost, S.Responder.DestinationPort));
        else
            if isempty(S.Responder)
                [~,a]=system(sprintf('ssh %s %s%s "lsof -ti :%d"', ...
                    S.SshOptions, user, S.Host, S.ResponderRemotePort));
            else
                S.reportError('.Responder is not a messenger')
                a='';
            end
        end
        Rpids=str2num(a);
    end
