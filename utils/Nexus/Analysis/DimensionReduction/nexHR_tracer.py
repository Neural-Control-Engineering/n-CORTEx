import traceback
import numpy as np

def fit_transform_traced(estimator, X):
    try:
        result = estimator.fit_transform(X)
        # Return the (now-fitted) estimator alongside the data — callers
        # must reassign their reference from this return value, not keep
        # using the pre-call handle, or fitted attributes (explained_
        # variance_ratio_, etc.) come back unreadable on the MATLAB side.
        return np.ascontiguousarray(result), estimator
    except Exception as e:
        msg = "".join(traceback.format_exception(type(e), e, e.__traceback__))
        raise RuntimeError(msg) from None

def transform_traced(estimator, X):
    try:
        result = estimator.transform(X)
        return np.ascontiguousarray(result)
    except Exception as e:
        msg = "".join(traceback.format_exception(type(e), e, e.__traceback__))
        raise RuntimeError(msg) from None
