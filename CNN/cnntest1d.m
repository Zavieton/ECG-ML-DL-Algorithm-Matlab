function [er,bad,out] = cnntest1d(net, x, y)
    %  feedforward
    net = cnnff1d(net, x);
     [~, h] = max(net.o);
     [~, a] = max(y);
%     bad2 = find(abs(h-a) >= 2);
     bad = find(h ~= a);
% 
    er = numel(bad) / size(y, 2);
%     er2 = numel(bad2)/size(y, 2);
    
    out = net.o;
    
end
