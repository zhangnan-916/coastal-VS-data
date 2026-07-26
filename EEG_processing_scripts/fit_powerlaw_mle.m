function alpha = fit_powerlaw_mle(x, xmin)
%FIT_POWERLAW_MLE Continuous approximation to the discrete power-law MLE.
%
% alpha = 1 + n / sum(log(x/(xmin - 0.5)))
%
% This estimator is commonly used as a practical approximation for
% discrete avalanche size/duration data. For publication-grade inference,
% also report xmin selection, goodness-of-fit, and comparison with
% alternative heavy-tailed distributions.

x = x(:);
x = x(isfinite(x) & x >= xmin);

if numel(x) < 10
    alpha = NaN;
    return;
end

alpha = 1 + numel(x) / sum(log(x ./ (xmin - 0.5)));
end