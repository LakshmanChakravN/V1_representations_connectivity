function [observed,p] = permTest(a,b,niter)

arguments
    a double
    b double
    niter double = 10000
end

pool = [a;b];
for iter = 1:niter
    randpool = pool(randperm(length(pool)));
    nullDist(iter) = mean(randpool(1:length(randpool)/2)) - ...
        mean(randpool(1+length(randpool)/2:end));
end

observed = mean(a) - mean(b);

if observed > 0
    p = length(find(nullDist>observed))/niter;
else
    p = length(find(nullDist<observed))/niter;
end

