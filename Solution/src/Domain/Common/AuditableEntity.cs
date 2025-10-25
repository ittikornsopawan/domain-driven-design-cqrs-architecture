using System;

namespace Domain.Common;

public class AuditableEntity : BaseEntity
{
    /// <summary>
    /// Indicates whether the entity is currently active.
    /// </summary>
    public bool isActive { get; set; }

    /// <summary>
    /// The date and time when the entity was deactivated, if applicable.
    /// </summary>
    public DateTime? deactivatedAt { get; set; }

    /// <summary>
    /// Indicates whether the entity has been marked as deleted.
    /// </summary>
    public bool isDeleted { get; set; }

    /// <summary>
    /// The identifier of the user who deleted the entity, if applicable.
    /// </summary>
    public string? deletedById { get; set; }

    /// <summary>
    /// The date and time when the entity was deleted, if applicable.
    /// </summary>
    public DateTime? deletedAt { get; set; }

    /// <summary>
    /// The identifier of the user who created the entity.
    /// </summary>
    public string? createdById { get; set; }

    /// <summary>
    /// The date and time when the entity was created.
    /// </summary>
    public DateTime createdAt { get; set; }

    /// <summary>
    /// The identifier of the user who last updated the entity, if applicable.
    /// </summary>
    public string? updatedById { get; set; }

    /// <summary>
    /// The date and time when the entity was last updated, if applicable.
    /// </summary>
    public DateTime? updatedAt { get; set; }
}
