function resp=areYouThere(Msng)
% simple method to check if the destination is a live Matlab session:
%  send a query evaluating to true
    try
        resp=~isempty(query(Msng,'true'));
    catch
        Msng.reportError('no response received by %s: does the other end exist?',...
                                  Msng.Name)
        resp=false;
    end
