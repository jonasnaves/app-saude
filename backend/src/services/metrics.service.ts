interface Metric {
  name: string;
  value: number;
  timestamp: Date;
  tags?: Record<string, string>;
}

export class MetricsService {
  private metrics: Metric[] = [];
  private readonly maxMetrics = 10000;

  recordMetric(name: string, value: number, tags?: Record<string, string>) {
    this.metrics.push({
      name,
      value,
      timestamp: new Date(),
      tags,
    });

    // Limitar tamanho do array
    if (this.metrics.length > this.maxMetrics) {
      this.metrics = this.metrics.slice(-this.maxMetrics);
    }
  }

  getMetrics(name?: string, startDate?: Date, endDate?: Date): Metric[] {
    let filtered = this.metrics;

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
    sum: number;
    avg: number;
    min: number;
    max: number;
  } {
    const metrics = this.getMetrics(name);
    if (metrics.length === 0) {
      return { count: 0, sum: 0, avg: 0, min: 0, max: 0 };
    }

    const values = metrics.map((m) => m.value);
    return {
      count: values.length,
      sum: values.reduce((a, b) => a + b, 0),
      avg: values.reduce((a, b) => a + b, 0) / values.length,
      min: Math.min(...values),
      max: Math.max(...values),
    };
  }

  clear() {
    this.metrics = [];
  }
}

export const metricsService = new MetricsService();

