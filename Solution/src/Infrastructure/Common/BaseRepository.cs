using System;
using Infrastructure.Persistence;

namespace Infrastructure.Common;

public class BaseRepository
{
    protected readonly AppDbContext _dbContext;
    public BaseRepository(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }
}

public class BaseRepository<T> : BaseRepository where T : class
{
    public BaseRepository(AppDbContext dbContext) : base(dbContext)
    {
    }
}
