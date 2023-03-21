function net = cnntrain1d(net, x, y, opts)
m = size(x, 2);
numbatches = floor(m / opts.batchsize);
%{
if rem(numbatches, 1) ~= 0
    error('numbatches not integer');
end
%}
net.rL = [];
net.Ls=[];
for i = 1 : opts.numepochs
    disp(['epoch ' num2str(i) '/' num2str(opts.numepochs)]);
    tic;
    kk = randperm(m);Ls=0;
    for l = 1 : numbatches
        batch_x = x(:, kk((l - 1) * opts.batchsize + 1 : l * opts.batchsize));
        batch_y = y(:, kk((l - 1) * opts.batchsize + 1 : l * opts.batchsize));
        
        net = cnnff1d(net, batch_x);
        net = cnnbp1d(net, batch_y,opts);
        % check grad
%          cnngradcheck(net,batch_x,batch_y);
        net = cnnapplygrads1d(net, opts);
        if isempty(net.rL)
            net.rL(1) = net.L;
        end
        net.rL(end + 1) = 0.99 * net.rL(end) + 0.01 * net.L;
		Ls=Ls+net.L;
    end
	if l*opts.batchsize<m
		batch_x = x(:, kk((l * opts.batchsize + 1 ): m));
        batch_y = y(:, kk((l * opts.batchsize + 1 ): m));
        
        net = cnnff1d(net, batch_x);
        net = cnnbp1d(net, batch_y,opts);
        % check grad
%          cnngradcheck(net,batch_x,batch_y);
        net = cnnapplygrads1d(net, opts);
        if isempty(net.rL)
            net.rL(1) = net.L;
        end
        net.rL(end + 1) = 0.99 * net.rL(end) + 0.01 * net.L;
		Ls=Ls+net.L;
	end
	net.Ls(end+1)=Ls/(ceil(m/opts.batchsize));
	disp(['Mean Loss:',num2str(net.Ls(end))]);
    toc;
end

end
