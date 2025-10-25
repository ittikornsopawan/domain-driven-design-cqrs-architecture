using System;
using MediatR;
using System.Collections.Generic;

namespace Domain.Common;

public abstract class BaseEntity : IEntity
{
    /// <summary>
    /// Unique identifier for the entity.
    /// </summary>
    public Guid id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// Unique code for the entity.
    /// </summary>
    public string code { get; set; } = default!;

    private List<INotification> _domainEvents = new();
    public IReadOnlyCollection<INotification> DomainEvents => _domainEvents;

    protected void AddDomainEvent(INotification eventItem)
    {
        _domainEvents.Add(eventItem);
    }

    public void ClearDomainEvents()
    {
        _domainEvents.Clear();
    }
}
