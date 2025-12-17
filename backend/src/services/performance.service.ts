interface PerformanceMetric {
  name: string;
  duration: number;
  timestamp: Date;
  metadata?: Record<string, any>;
}

export class PerformanceService {
  private metrics: PerformanceMetric[] = [];
  private readonly maxMetrics = 10000;

  recordMetric(name: string, duration: number, metadata?: Record<string, any>) {
    this.metrics.push({
      name,
      duration,
      timestamp: new Date(),
      metadata,
    });

    if (this.metrics.length > this.maxMetrics) {
      this.metrics = this.metrics.slice(-this.maxMetrics);
    }
  }

  startTimer(name: string): () => void {
    const start = Date.now();
    return () => {
      const duration = Date.now() - start;
      this.recordMetric(name, duration);
    };
  }

  getMetrics(name?: string, startDate?: Date, endDate?: Date): PerformanceMetric[] {
    let filtered = [...this.metrics];

    if (name) {
      filtered = filtered.filter((m) => m.name === name);
    }

    if (startDate) {
      filtered = filtered.filter((m) => m.timestamp >= startDate);
    }

    if (endDate) {
      filtered = filtered.filter((m) => m.timestamp <= endDate);
    }

    return filtered;
  }

  getStats(name: string): {
    count: number;
    avg: number;
    min: number;
    max: number;
    p50: number;
    p95: number;
    p99: number;
  } {
    const metrics = this.getMetrics(name);
    if (metrics.length === 0) {
      return { count: 0, avg: 0, min: 0, max: 0, p50: 0, p95: 0, p99: 0 };
    }

    const durations = metrics.map((m) => m.duration).sort((a, b) => a - b);
    const sum = durations.reduce((a, b) => a + b, 0);

    return {
      count: durations.length,
      avg: sum / durations.length,
      min: durations[0],
      max: durations[durations.length - 1],
      p50: durations[Math.floor(durations.length * 0.5)],
      p95: durations[Math.floor(durations.length * 0.95)],
      p99: durations[Math.floor(durations.length * 0.99)],
    };
  }

  clear() {
    this.metrics = [];
  }
}

export const performanceService = new PerformanceService();

