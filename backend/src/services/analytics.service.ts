interface AnalyticsEvent {
  userId?: string;
  event: string;
  category: string;
  properties?: Record<string, any>;
  timestamp: Date;
}

export class AnalyticsService {
  private events: AnalyticsEvent[] = [];
  private readonly maxEvents = 50000;

  trackEvent(
    event: string,
    category: string,
    userId?: string,
    properties?: Record<string, any>
  ) {
    this.events.push({
      userId,
      event,
      category,
      properties,
      timestamp: new Date(),
    });

    // Limitar tamanho do array
    if (this.events.length > this.maxEvents) {
      this.events = this.events.slice(-this.maxEvents);
    }
  }

  getEvents(filters?: {
    userId?: string;
    category?: string;
    event?: string;
    startDate?: Date;
    endDate?: Date;
  }): AnalyticsEvent[] {
    let filtered = [...this.events];

    if (filters?.userId) {
      filtered = filtered.filter((e) => e.userId === filters.userId);
    }

    if (filters?.category) {
      filtered = filtered.filter((e) => e.category === filters.category);
    }

    if (filters?.event) {
      filtered = filtered.filter((e) => e.event === filters.event);
    }

    if (filters?.startDate) {
      filtered = filtered.filter((e) => e.timestamp >= filters.startDate!);
    }

    if (filters?.endDate) {
      filtered = filtered.filter((e) => e.timestamp <= filters.endDate!);
    }

    return filtered;
  }

  getEventCount(event: string, userId?: string): number {
    return this.getEvents({ event, userId }).length;
  }

  getCategoryStats(category: string, userId?: string) {
    const events = this.getEvents({ category, userId });
    const eventCounts = new Map<string, number>();

    events.forEach((e) => {
      eventCounts.set(e.event, (eventCounts.get(e.event) || 0) + 1);
    });

    return {
      total: events.length,
      events: Object.fromEntries(eventCounts),
    };
  }

  clear() {
    this.events = [];
  }
}

export const analyticsService = new AnalyticsService();

