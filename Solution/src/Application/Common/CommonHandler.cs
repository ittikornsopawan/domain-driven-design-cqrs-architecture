using System;
using System.Net;
using Shared.Common;

namespace Application.Common;

public class CommonHandler
{
    public CommonHandler()
    {

    }

    protected ResponseModel SuccessResponse(HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        return new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode
            }
        };
    }

    protected ResponseModel FailResponse(HttpStatusCode statusCode, string bizErrorCode)
    {
        return new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorCode = bizErrorCode
            }
        };
    }

    protected ResponseModel FailMessageResponse(HttpStatusCode statusCode, string bizErrorMessage)
    {
        return new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorMessage = bizErrorMessage
            }
        };
    }

    protected ResponseModel<T> SuccessResponse<T>(T data, HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        return new ResponseModel<T>
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode
            },
            data = data
        };
    }

    protected ResponseModel<T> FailResponse<T>(HttpStatusCode statusCode, string bizErrorCode)
    {
        return new ResponseModel<T>
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorCode = bizErrorCode
            },
            data = default!
        };
    }

    protected ResponseModel<T> FailMessageResponse<T>(HttpStatusCode statusCode, string bizErrorMessage)
    {
        return new ResponseModel<T>
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorMessage = bizErrorMessage
            },
            data = default!
        };
    }
}

public class CommonHandler<T> : CommonHandler
{
    public T _repository;
    public CommonHandler(T repository)
    {
        this._repository = repository;
    }
}
