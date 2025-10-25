using System;

namespace Domain.Common;

public interface IEntity
{
    Guid id { get; set; }
}
