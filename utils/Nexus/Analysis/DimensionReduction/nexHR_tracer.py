import traceback
import numpy as np

def fit_transform_traced(estimator, X):
    try:
        result = estimator.fit_transform(X)
        return np.ascontiguousarray(result)
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
