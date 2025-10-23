/**
 * Date utility functions for week boundaries and calculations
 */

/**
 * Get the start of the week (Sunday at 00:00:00) for a given date
 */
export function getWeekStart(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day; // Days since Sunday
  d.setDate(d.getDate() - diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

/**
 * Get the end of the week (Saturday at 23:59:59) for a given date
 */
export function getWeekEnd(date: Date): Date {
  const start = getWeekStart(date);
  const end = new Date(start);
  end.setDate(end.getDate() + 6);
  end.setHours(23, 59, 59, 999);
  return end;
}

/**
 * Get current week boundaries
 */
export function getCurrentWeekBoundaries(): { start: Date; end: Date } {
  const now = new Date();
  return {
    start: getWeekStart(now),
    end: getWeekEnd(now),
  };
}

/**
 * Format date as ISO string (YYYY-MM-DD)
 */
export function formatDateISO(date: Date): string {
  return date.toISOString().split('T')[0];
}

/**
 * Format week range as "Oct 13 - Oct 19"
 */
export function formatWeekRange(start: Date, end: Date): string {
  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  const startMonth = monthNames[start.getMonth()];
  const startDay = start.getDate();

  const endMonth = monthNames[end.getMonth()];
  const endDay = end.getDate();

  return `${startMonth} ${startDay} - ${endMonth} ${endDay}`;
}

/**
 * Check if a date is in the current week
 */
export function isCurrentWeek(date: Date): boolean {
  const { start, end } = getCurrentWeekBoundaries();
  return date >= start && date <= end;
}

/**
 * Get week boundaries for N weeks ago
 */
export function getWeekBoundaries(weeksAgo: number): { start: Date; end: Date } {
  const now = new Date();
  const targetDate = new Date(now);
  targetDate.setDate(targetDate.getDate() - weeksAgo * 7);

  return {
    start: getWeekStart(targetDate),
    end: getWeekEnd(targetDate),
  };
}

/**
 * Parse ISO date string to Date object
 */
export function parseISODate(dateString: string): Date {
  return new Date(dateString);
}

/**
 * Add days to a date
 */
export function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

/**
 * Subtract days from a date
 */
export function subtractDays(date: Date, days: number): Date {
  return addDays(date, -days);
}
