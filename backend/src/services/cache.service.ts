import NodeCache from 'node-cache';

export class CacheService {
  private cache: NodeCache;

  constructor(ttlSeconds: number = 3600) {
    this.cache = new NodeCache({
      stdTTL: ttlSeconds,
      checkperiod: ttlSeconds * 0.2,
      useClones: false,
    });
  }

  get<T>(key: string): T | undefined {
    return this.cache.get<T>(key);
  }

  set<T>(key: string, value: T, ttl?: number): boolean {
    return this.cache.set(key, value, ttl || 0);
  }

  del(key: string): number {
    return this.cache.del(key);
  }

  flush(): void {
    this.cache.flushAll();
  }

  has(key: string): boolean {
    return this.cache.has(key);
  }

  // Cache keys
  static readonly KEYS = {
    user: (id: string) => `user:${id}`,
    consultations: (userId: string) => `consultations:${userId}`,
    stats: (userId: string) => `stats:${userId}`,
    drugs: (search?: string) => `drugs:${search || 'all'}`,
  };
}

export const cacheService = new CacheService(3600); // 1 hora default

