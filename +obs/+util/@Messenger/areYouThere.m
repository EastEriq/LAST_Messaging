function resp=areYouThere(Msng)
% simple method to check if the destination is a live Matlab session:
%  send a query evaluating to true
     resp=~isempty(query(Msng,'true'));
