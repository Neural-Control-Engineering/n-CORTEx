function y = lowess_wrapped(x, args)
    span = args.span;
    y = lowess(x, span);
end