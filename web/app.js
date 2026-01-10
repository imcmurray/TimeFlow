/**
 * TimeFlow - Experience time as a gentle flowing river
 * Main Application JavaScript
 */

// ============================================================================
// Database Layer (IndexedDB)
// ============================================================================

class Database {
    constructor() {
        this.dbName = 'TimeFlowDB';
        this.dbVersion = 1;
        this.db = null;
    }

    async init() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.dbName, this.dbVersion);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                this.db = request.result;
                resolve(this.db);
            };

            request.onupgradeneeded = (event) => {
                const db = event.target.result;

                // Tasks store
                if (!db.objectStoreNames.contains('tasks')) {
                    const taskStore = db.createObjectStore('tasks', { keyPath: 'id' });
                    taskStore.createIndex('date', 'date', { unique: false });
                    taskStore.createIndex('startTime', 'startTime', { unique: false });
                }

                // Settings store
                if (!db.objectStoreNames.contains('settings')) {
                    db.createObjectStore('settings', { keyPath: 'key' });
                }
            };
        });
    }

    // Task operations
    async getAllTasks() {
        return this._getAll('tasks');
    }

    async getAllTaskTitles() {
        const tasks = await this._getAll('tasks');
        const uniqueTitles = [...new Set(tasks.map(t => t.title))];
        return uniqueTitles;
    }

    async getTasksByDate(date) {
        const dateStr = this._formatDate(date);
        const directTasks = await this._getAllByIndex('tasks', 'date', dateStr);

        // Also include recurring tasks that match this date
        const allTasks = await this._getAll('tasks');
        const recurringTasks = allTasks.filter(task => {
            if (!task.recurring || task.date === dateStr) return false;
            return this._matchesRecurringPattern(task, date);
        });

        // Create virtual instances of recurring tasks for this date
        const recurringInstances = recurringTasks.map(task => ({
            ...task,
            originalId: task.id,
            id: `${task.id}_${dateStr}`, // Virtual ID for this instance
            date: dateStr,
            isRecurringInstance: true
        }));

        return [...directTasks, ...recurringInstances];
    }

    _matchesRecurringPattern(task, targetDate) {
        const taskDate = new Date(task.date + 'T00:00:00');
        const target = new Date(this._formatDate(targetDate) + 'T00:00:00');

        // Only match dates after the original task date
        if (target <= taskDate) return false;

        const dayOfWeek = target.getDay(); // 0 = Sunday, 6 = Saturday

        switch (task.recurring) {
            case 'daily':
                return true;
            case 'weekly':
                // Same day of week
                return taskDate.getDay() === dayOfWeek;
            case 'weekdays':
                return dayOfWeek >= 1 && dayOfWeek <= 5; // Mon-Fri
            case 'monthly':
                // Same day of month
                return taskDate.getDate() === target.getDate();
            default:
                return false;
        }
    }

    async getTask(id) {
        return this._get('tasks', id);
    }

    async saveTask(task) {
        if (!task.id) {
            task.id = this._generateId();
        }
        task.updatedAt = new Date().toISOString();
        if (!task.createdAt) {
            task.createdAt = task.updatedAt;
        }
        return this._put('tasks', task);
    }

    async deleteTask(id) {
        return this._delete('tasks', id);
    }

    // Settings operations
    async getSetting(key) {
        const result = await this._get('settings', key);
        return result?.value;
    }

    async setSetting(key, value) {
        return this._put('settings', { key, value });
    }

    async getAllSettings() {
        const settings = await this._getAll('settings');
        return settings.reduce((acc, { key, value }) => {
            acc[key] = value;
            return acc;
        }, {});
    }

    // Helper methods
    _generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }

    _formatDate(date) {
        // Use local timezone instead of UTC to avoid date shifting
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    _getAll(storeName) {
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction(storeName, 'readonly');
            const store = transaction.objectStore(storeName);
            const request = store.getAll();
            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    _getAllByIndex(storeName, indexName, value) {
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction(storeName, 'readonly');
            const store = transaction.objectStore(storeName);
            const index = store.index(indexName);
            const request = index.getAll(value);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    _get(storeName, key) {
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction(storeName, 'readonly');
            const store = transaction.objectStore(storeName);
            const request = store.get(key);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    _put(storeName, data) {
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction(storeName, 'readwrite');
            const store = transaction.objectStore(storeName);
            const request = store.put(data);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(data);
        });
    }

    _delete(storeName, key) {
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction(storeName, 'readwrite');
            const store = transaction.objectStore(storeName);
            const request = store.delete(key);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve();
        });
    }
}

// ============================================================================
// State Management
// ============================================================================

class AppState {
    constructor() {
        this._state = {
            currentDate: new Date(),
            tasks: [],
            settings: {
                theme: 'light',
                notificationsEnabled: true,
                defaultReminderMinutes: 15,
                timelineDensity: 1
            },
            editingTask: null
        };
        this._listeners = new Set();
    }

    get state() {
        return this._state;
    }

    setState(updates) {
        this._state = { ...this._state, ...updates };
        this._notifyListeners();
    }

    subscribe(listener) {
        this._listeners.add(listener);
        return () => this._listeners.delete(listener);
    }

    _notifyListeners() {
        this._listeners.forEach(listener => listener(this._state));
    }
}

// ============================================================================
// Utility Functions
// ============================================================================

const Utils = {
    formatTime(date) {
        if (typeof date === 'string') {
            // Handle HH:MM format
            const [hours, minutes] = date.split(':').map(Number);
            const period = hours >= 12 ? 'PM' : 'AM';
            const displayHours = hours % 12 || 12;
            return `${displayHours}:${minutes.toString().padStart(2, '0')} ${period}`;
        }
        return date.toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
    },

    formatDate(date) {
        const today = new Date();
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);

        if (this.isSameDay(date, today)) return 'Today';
        if (this.isSameDay(date, tomorrow)) return 'Tomorrow';
        if (this.isSameDay(date, yesterday)) return 'Yesterday';

        return date.toLocaleDateString('en-US', {
            weekday: 'long',
            month: 'short',
            day: 'numeric'
        });
    },

    formatDateSubtitle(date) {
        return date.toLocaleDateString('en-US', {
            weekday: 'long',
            month: 'long',
            day: 'numeric',
            year: 'numeric'
        });
    },

    isSameDay(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getDate() === d2.getDate();
    },

    timeToMinutes(time) {
        if (typeof time === 'string') {
            const [hours, minutes] = time.split(':').map(Number);
            return hours * 60 + minutes;
        }
        return time.getHours() * 60 + time.getMinutes();
    },

    minutesToTime(minutes) {
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;
        return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
    },

    getCurrentTimeMinutes() {
        const now = new Date();
        return now.getHours() * 60 + now.getMinutes();
    },

    // Screen reader announcement helper
    announceToScreenReader(message) {
        const announcer = document.getElementById('sr-announcements');
        if (announcer) {
            // Clear and set to trigger announcement
            announcer.textContent = '';
            setTimeout(() => {
                announcer.textContent = message;
            }, 100);
        }
    }
};

// ============================================================================
// Toast Notifications
// ============================================================================

class Toast {
    static show(message, type = 'info', duration = 3000) {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;

        // Add ARIA attributes for screen reader announcement
        toast.setAttribute('role', type === 'error' ? 'alert' : 'status');
        toast.setAttribute('aria-live', type === 'error' ? 'assertive' : 'polite');

        container.appendChild(toast);

        // Also announce to screen reader via dedicated announcer
        Utils.announceToScreenReader(message);

        setTimeout(() => {
            toast.style.opacity = '0';
            toast.style.transform = 'translateY(20px)';
            setTimeout(() => toast.remove(), 300);
        }, duration);
    }
}

// ============================================================================
// Timeline Renderer
// ============================================================================

class TimelineRenderer {
    constructor(container, state) {
        this.container = container;
        this.state = state;
        this.hourHeight = 80;
        this.autoScrollEnabled = true;
        this.scrollTimeout = null;
    }

    render(tasks) {
        const timeline = document.getElementById('timeline');
        timeline.innerHTML = '';

        // Create hour blocks for 24 hours
        for (let hour = 0; hour < 24; hour++) {
            const hourBlock = document.createElement('div');
            hourBlock.className = 'hour-block';
            hourBlock.dataset.hour = hour;

            const hourLabel = document.createElement('span');
            hourLabel.className = 'hour-label';
            hourLabel.textContent = Utils.formatTime(`${hour.toString().padStart(2, '0')}:00`);

            hourBlock.appendChild(hourLabel);
            timeline.appendChild(hourBlock);
        }

        // Render tasks
        this.renderTasks(tasks, timeline);

        // Initial scroll to current time
        this.scrollToCurrentTime();
    }

    renderTasks(tasks, timeline) {
        // Remove any existing empty state
        const existingEmpty = timeline.querySelector('.empty-state');
        if (existingEmpty) existingEmpty.remove();

        // Show empty state if no tasks
        if (tasks.length === 0) {
            const emptyState = document.createElement('div');
            emptyState.className = 'empty-state';
            emptyState.innerHTML = `
                <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
                <h3>No tasks today</h3>
                <p>Tap the + button to add your first task and start planning your day.</p>
            `;
            timeline.appendChild(emptyState);
            return;
        }

        const currentMinutes = Utils.getCurrentTimeMinutes();

        // Create or update SVG overlay for reminder lines
        let svgOverlay = timeline.querySelector('.reminder-lines-svg');
        if (!svgOverlay) {
            svgOverlay = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
            svgOverlay.classList.add('reminder-lines-svg');
            timeline.appendChild(svgOverlay);
        }

        tasks.forEach(task => {
            const taskCard = this.createTaskCard(task, currentMinutes);
            timeline.appendChild(taskCard);
        });

        // Render reminder indicators for tasks with reminders
        this.renderReminderIndicators(tasks, timeline, currentMinutes);

        // Render reminder lines connecting tasks to their reminder times
        this.renderReminderLines(tasks, timeline, currentMinutes);
    }

    renderReminderIndicators(tasks, timeline, currentMinutes) {
        // Remove any existing reminder indicators
        timeline.querySelectorAll('.reminder-indicator').forEach(el => el.remove());

        tasks.forEach(task => {
            if (!task.reminderMinutes || task.isCompleted) return;

            const startMinutes = Utils.timeToMinutes(task.startTime);
            const reminderMinutes = startMinutes - task.reminderMinutes;

            // Skip if reminder time is negative (would be before midnight) or task has already started
            if (reminderMinutes < 0 || startMinutes <= currentMinutes) return;

            // Calculate position on timeline
            const top = (reminderMinutes / 60) * this.hourHeight;

            // Create reminder indicator
            const indicator = document.createElement('div');
            indicator.className = 'reminder-indicator';
            if (task.color) indicator.classList.add(`color-${task.color}`);

            // Determine the state of the reminder
            const minutesUntilReminder = reminderMinutes - currentMinutes;
            const isTriggered = reminderMinutes <= currentMinutes;
            const isApproaching = minutesUntilReminder <= 15 && minutesUntilReminder > 0;

            if (isTriggered) {
                indicator.classList.add('triggered');
            } else if (isApproaching) {
                indicator.classList.add('approaching');
            }

            indicator.style.top = `${top}px`;
            indicator.dataset.taskId = task.id;
            indicator.setAttribute('title', `Reminder for "${task.title}" - ${task.reminderMinutes}m before`);

            const statusText = isTriggered ? ' (triggered)' : '';
            indicator.setAttribute('aria-label', `Reminder indicator: ${task.title} reminder at ${Utils.formatTime(Utils.minutesToTime(reminderMinutes))}${statusText}`);

            indicator.innerHTML = `
                <div class="reminder-indicator-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                </div>
                <span class="reminder-indicator-time">${Utils.formatTime(Utils.minutesToTime(reminderMinutes))}</span>
            `;

            timeline.appendChild(indicator);
        });
    }

    renderReminderLines(tasks, timeline, currentMinutes) {
        const svgOverlay = timeline.querySelector('.reminder-lines-svg');
        if (!svgOverlay) return;

        // Clear existing lines
        svgOverlay.innerHTML = '';

        // Set SVG dimensions to match timeline
        svgOverlay.setAttribute('width', '100%');
        svgOverlay.setAttribute('height', timeline.scrollHeight);

        tasks.forEach(task => {
            if (!task.reminderMinutes || task.isCompleted) return;

            const startMinutes = Utils.timeToMinutes(task.startTime);
            const reminderMinutes = startMinutes - task.reminderMinutes;
            const minutesUntilReminder = reminderMinutes - currentMinutes;

            // Only show within 1 hour window and before triggered
            if (minutesUntilReminder <= 0 || minutesUntilReminder > 60) return;

            // Skip if reminder time is negative (before midnight)
            if (reminderMinutes < 0) return;

            // Calculate positions
            const taskY = (startMinutes / 60) * this.hourHeight;
            const reminderY = (reminderMinutes / 60) * this.hourHeight;
            const lineX = 75;

            // Determine state based on time until reminder
            let state = 'distant';
            if (minutesUntilReminder <= 5) {
                state = 'imminent';
            } else if (minutesUntilReminder <= 15) {
                state = 'approaching';
            }

            // Create vertical line from reminder time up to task
            const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            line.setAttribute('x1', lineX);
            line.setAttribute('y1', reminderY);
            line.setAttribute('x2', lineX);
            line.setAttribute('y2', taskY);
            line.classList.add('reminder-line', `state-${state}`);
            line.dataset.taskId = task.id;

            svgOverlay.appendChild(line);
        });
    }

    createTaskCard(task, currentMinutes) {
        const startMinutes = Utils.timeToMinutes(task.startTime);
        const endMinutes = Utils.timeToMinutes(task.endTime);
        const durationMinutes = endMinutes - startMinutes;

        // Calculate position
        const top = (startMinutes / 60) * this.hourHeight;
        const height = Math.max((durationMinutes / 60) * this.hourHeight - 8, 40);

        // Determine status
        let status = 'upcoming';
        if (task.isCompleted) {
            status = 'completed';
        } else if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
            status = 'current';
        } else if (currentMinutes >= endMinutes) {
            status = 'past';
        }

        const card = document.createElement('div');
        card.className = `task-card ${status}`;
        if (task.isImportant) card.classList.add('important');
        if (task.color) card.classList.add(`color-${task.color}`);
        card.dataset.taskId = task.id;
        card.style.top = `${top}px`;
        card.style.height = `${height}px`;

        // Accessibility attributes for screen readers
        card.setAttribute('role', 'listitem');
        card.setAttribute('tabindex', '0');
        const statusText = task.isCompleted ? 'completed' : (status === 'current' ? 'in progress' : status);
        const importantText = task.isImportant ? ', important' : '';
        const ariaLabel = `${task.title}, ${Utils.formatTime(task.startTime)} to ${Utils.formatTime(task.endTime)}, ${statusText}${importantText}`;
        card.setAttribute('aria-label', ariaLabel);

        card.innerHTML = `
            <div class="task-header">
                <h3 class="task-title">${this.escapeHtml(task.title)}</h3>
                <span class="task-time">${Utils.formatTime(task.startTime)} - ${Utils.formatTime(task.endTime)}</span>
            </div>
            ${task.description ? `<p class="task-description">${this.escapeHtml(task.description)}</p>` : ''}
            <div class="task-indicators">
                ${task.isImportant ? `
                    <span class="task-indicator">
                        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
                        Important
                    </span>
                ` : ''}
                ${task.reminderMinutes ? `
                    <span class="task-indicator">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                        ${task.reminderMinutes}m before
                    </span>
                ` : ''}
                ${task.recurring ? `
                    <span class="task-indicator recurring-indicator">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 1l4 4-4 4"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><path d="M7 23l-4-4 4-4"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg>
                        ${task.recurring === 'daily' ? 'Daily' : task.recurring === 'weekly' ? 'Weekly' : task.recurring === 'weekdays' ? 'Weekdays' : 'Monthly'}
                    </span>
                ` : ''}
                ${task.attachmentData ? `
                    <span class="task-indicator task-attachment-indicator">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path></svg>
                        Photo
                    </span>
                ` : ''}
            </div>
            <button class="complete-btn" aria-label="${task.isCompleted ? 'Mark incomplete' : 'Mark complete'}">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                    <polyline points="20,6 9,17 4,12"></polyline>
                </svg>
            </button>
        `;

        // Event listeners
        card.addEventListener('click', (e) => {
            if (!e.target.closest('.complete-btn')) {
                window.app.editTask(task.id);
            }
        });

        // Keyboard support for accessibility
        card.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                window.app.editTask(task.id);
            }
        });

        card.querySelector('.complete-btn').addEventListener('click', (e) => {
            e.stopPropagation();
            window.app.toggleTaskComplete(task.id);
        });

        // Swipe to complete functionality
        let startX = 0;
        let startY = 0;
        let currentX = 0;
        let isDragging = false;
        const SWIPE_THRESHOLD = 100;

        const handleSwipeStart = (clientX, clientY) => {
            startX = clientX;
            startY = clientY;
            currentX = 0;
            isDragging = true;
            card.style.transition = 'none';
        };

        const handleSwipeMove = (clientX, clientY) => {
            if (!isDragging) return;
            const deltaX = clientX - startX;
            const deltaY = clientY - startY;

            // Only allow horizontal swipe if more horizontal than vertical
            if (Math.abs(deltaX) > Math.abs(deltaY)) {
                currentX = Math.max(0, deltaX); // Only allow right swipe
                card.style.transform = `translateX(${currentX}px)`;
                card.style.opacity = Math.max(0.3, 1 - currentX / 200);
            }
        };

        const handleSwipeEnd = () => {
            if (!isDragging) return;
            isDragging = false;
            card.style.transition = 'transform 0.3s ease, opacity 0.3s ease';

            if (currentX >= SWIPE_THRESHOLD && !task.isCompleted) {
                // Complete the task with animation
                card.style.transform = 'translateX(100%)';
                card.style.opacity = '0';
                setTimeout(() => {
                    window.app.toggleTaskComplete(task.id);
                }, 300);
            } else {
                // Reset position
                card.style.transform = 'translateX(0)';
                card.style.opacity = '1';
            }
        };

        // Mouse events
        card.addEventListener('mousedown', (e) => {
            if (e.target.closest('.complete-btn')) return;
            handleSwipeStart(e.clientX, e.clientY);
        });

        document.addEventListener('mousemove', (e) => {
            handleSwipeMove(e.clientX, e.clientY);
        });

        document.addEventListener('mouseup', () => {
            handleSwipeEnd();
        });

        // Touch events
        card.addEventListener('touchstart', (e) => {
            if (e.target.closest('.complete-btn')) return;
            const touch = e.touches[0];
            handleSwipeStart(touch.clientX, touch.clientY);
        });

        card.addEventListener('touchmove', (e) => {
            const touch = e.touches[0];
            handleSwipeMove(touch.clientX, touch.clientY);
        });

        card.addEventListener('touchend', () => {
            handleSwipeEnd();
        });

        return card;
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    scrollToCurrentTime(smooth = false) {
        const timeline = document.getElementById('timeline');
        const currentMinutes = Utils.getCurrentTimeMinutes();
        const targetScroll = (currentMinutes / 60) * this.hourHeight - (timeline.clientHeight * 0.7);

        if (smooth) {
            // Smooth scroll animation
            timeline.scrollTo({
                top: Math.max(0, targetScroll),
                behavior: 'smooth'
            });
        } else {
            timeline.scrollTop = Math.max(0, targetScroll);
        }
    }

    updateNowLine() {
        const now = new Date();
        const nowTimeEl = document.getElementById('now-time');
        nowTimeEl.textContent = Utils.formatTime(now);
    }

    // Auto-scroll to keep current time in view
    autoScroll() {
        if (!this.autoScrollEnabled) return;

        const timeline = document.getElementById('timeline');
        const currentMinutes = Utils.getCurrentTimeMinutes();
        const targetScroll = (currentMinutes / 60) * this.hourHeight - (timeline.clientHeight * 0.7);
        const currentScroll = timeline.scrollTop;

        // Only auto-scroll if user hasn't manually scrolled away significantly
        const scrollDifference = Math.abs(targetScroll - currentScroll);
        if (scrollDifference > 5) {
            // Smooth incremental scroll (about 1 pixel per second for gentle flow)
            const scrollStep = Math.sign(targetScroll - currentScroll) * Math.min(1, scrollDifference / 10);
            timeline.scrollTop = currentScroll + scrollStep;
        }
    }

    // Pause auto-scroll when user is interacting
    pauseAutoScroll(duration = 5000) {
        this.autoScrollEnabled = false;
        clearTimeout(this.scrollTimeout);
        this.scrollTimeout = setTimeout(() => {
            this.autoScrollEnabled = true;
        }, duration);
    }
}

// ============================================================================
// Main Application
// ============================================================================

class TimeFlowApp {
    constructor() {
        this.db = new Database();
        this.state = new AppState();
        this.renderer = null;
        this.updateInterval = null;
    }

    async init() {
        try {
            // Initialize database
            await this.db.init();
            console.log('Database initialized');

            // Load settings
            const settings = await this.db.getAllSettings();
            if (Object.keys(settings).length > 0) {
                this.state.setState({ settings: { ...this.state.state.settings, ...settings } });
            }

            // Apply theme
            this.applyTheme(this.state.state.settings.theme);

            // Initialize renderer
            this.renderer = new TimelineRenderer(
                document.getElementById('timeline-container'),
                this.state
            );

            // Apply timeline density
            this.applyTimelineDensity(this.state.state.settings.timelineDensity);

            // Check for deep link date in URL hash
            const initialDate = this.getDateFromUrl() || this.state.state.currentDate;

            // Load tasks for initial date
            await this.loadTasksForDate(initialDate);

            // Set up event listeners
            this.setupEventListeners();

            // Start real-time updates
            this.startRealTimeUpdates();

            // Update header
            this.updateDateDisplay();

            // Initialize notifications
            await this.initNotifications();

            // Initialize cross-tab sync for concurrent edit handling
            this.initCrossTabSync();

            // Check if onboarding should be shown
            await this.checkOnboarding();

            console.log('TimeFlow initialized successfully');
        } catch (error) {
            console.error('Failed to initialize TimeFlow:', error);
            Toast.show('Failed to initialize app', 'error');
        }
    }

    async checkOnboarding() {
        const hasSeenOnboarding = await this.db.getSetting('hasSeenOnboarding');
        if (!hasSeenOnboarding) {
            this.showOnboarding();
        }
    }

    // Notification System
    async initNotifications() {
        this.scheduledNotifications = new Map();

        // Request notification permission if not already granted
        if ('Notification' in window) {
            if (Notification.permission === 'default') {
                // Don't request immediately - wait for user interaction
                console.log('Notification permission not yet requested');
            } else if (Notification.permission === 'granted') {
                console.log('Notifications enabled');
                // Schedule notifications for today's tasks
                await this.scheduleNotificationsForToday();
            }
        }

        // Start notification check interval (every 10 seconds)
        this.notificationInterval = setInterval(() => {
            this.checkAndTriggerNotifications();
        }, 10000);
    }

    async requestNotificationPermission() {
        if (!('Notification' in window)) {
            Toast.show('Notifications not supported in this browser', 'info');
            return false;
        }

        if (Notification.permission === 'granted') {
            return true;
        }

        if (Notification.permission !== 'denied') {
            const permission = await Notification.requestPermission();
            if (permission === 'granted') {
                Toast.show('Notifications enabled!', 'success');
                await this.scheduleNotificationsForToday();
                return true;
            }
        }

        return false;
    }

    async scheduleNotificationsForToday() {
        // Clear existing scheduled notifications
        this.scheduledNotifications.clear();

        const today = new Date();
        const tasks = await this.db.getTasksByDate(today);

        tasks.forEach(task => {
            if (task.reminderMinutes && !task.isCompleted) {
                this.scheduleNotificationForTask(task, today);
            }
        });

        console.log(`Scheduled ${this.scheduledNotifications.size} notifications for today`);
    }

    scheduleNotificationForTask(task, date) {
        if (!task.reminderMinutes) return;

        // Parse task start time
        const [hours, minutes] = task.startTime.split(':').map(Number);
        const taskDate = new Date(date);
        taskDate.setHours(hours, minutes, 0, 0);

        // Calculate notification time (X minutes before task)
        const notificationTime = new Date(taskDate.getTime() - task.reminderMinutes * 60 * 1000);

        // Don't schedule if notification time is in the past
        if (notificationTime <= new Date()) {
            return;
        }

        // Store the notification data
        this.scheduledNotifications.set(task.id, {
            taskId: task.id,
            title: task.title,
            startTime: task.startTime,
            reminderMinutes: task.reminderMinutes,
            notificationTime: notificationTime,
            triggered: false
        });
    }

    checkAndTriggerNotifications() {
        if (Notification.permission !== 'granted') return;

        // Check if notifications are globally enabled in settings
        if (!this.state.state.settings.notificationsEnabled) {
            return;
        }

        const now = new Date();

        this.scheduledNotifications.forEach((notification, taskId) => {
            if (notification.triggered) return;

            if (now >= notification.notificationTime) {
                this.triggerNotification(notification);
                notification.triggered = true;
            }
        });
    }

    // Cross-tab synchronization for concurrent edit handling
    initCrossTabSync() {
        // Use BroadcastChannel API for cross-tab communication
        if ('BroadcastChannel' in window) {
            this.syncChannel = new BroadcastChannel('timeflow-sync');

            this.syncChannel.onmessage = (event) => {
                this.handleCrossTabMessage(event.data);
            };
        }

        // Fallback: Use localStorage events for older browsers
        window.addEventListener('storage', (event) => {
            if (event.key === 'timeflow-task-update') {
                try {
                    const data = JSON.parse(event.newValue);
                    this.handleCrossTabMessage(data);
                } catch (e) {
                    // Ignore parsing errors
                }
            }
        });

        console.log('Cross-tab sync initialized');
    }

    broadcastTaskUpdate(taskId, action) {
        const message = {
            type: 'task-update',
            taskId,
            action, // 'saved', 'deleted', 'editing'
            timestamp: Date.now(),
            tabId: this.tabId || (this.tabId = Math.random().toString(36).substr(2, 9))
        };

        // Broadcast using BroadcastChannel
        if (this.syncChannel) {
            this.syncChannel.postMessage(message);
        }

        // Also use localStorage for fallback
        localStorage.setItem('timeflow-task-update', JSON.stringify(message));
    }

    handleCrossTabMessage(data) {
        if (!data || data.tabId === this.tabId) return; // Ignore own messages

        if (data.type === 'task-update') {
            const editingTask = this.state.state.editingTask;

            if (data.action === 'saved' || data.action === 'deleted') {
                // Another tab saved or deleted a task - refresh our view
                this.loadTasksForDate(this.state.state.currentDate);

                // If we're editing the same task that was modified elsewhere
                if (editingTask && editingTask.id === data.taskId) {
                    if (data.action === 'deleted') {
                        Toast.show('This task was deleted in another window', 'info');
                        this.closeTaskModal();
                    } else {
                        Toast.show('This task was updated in another window. Your changes may be overwritten.', 'warning');
                    }
                }
            } else if (data.action === 'editing' && editingTask && editingTask.id === data.taskId) {
                // Another tab is also editing this task
                Toast.show('This task is being edited in another window', 'info');
            }
        }
    }

    triggerNotification(notification) {
        const formattedTime = Utils.formatTime(notification.startTime);

        try {
            const browserNotification = new Notification('TimeFlow Reminder', {
                body: `${notification.title} starts at ${formattedTime}`,
                icon: '/favicon.ico',
                tag: `task-${notification.taskId}`,
                requireInteraction: false,
                silent: false
            });

            browserNotification.onclick = () => {
                window.focus();
                this.editTask(notification.taskId);
                browserNotification.close();
            };

            // Also show toast notification
            Toast.show(`Reminder: ${notification.title} at ${formattedTime}`, 'info');

            console.log(`Notification triggered for task: ${notification.title}`);
        } catch (error) {
            console.error('Failed to trigger notification:', error);
            // Fallback to toast only
            Toast.show(`Reminder: ${notification.title} at ${formattedTime}`, 'info');
        }
    }

    showOnboarding() {
        const modal = document.getElementById('onboarding-modal');
        const nextBtn = document.getElementById('onboarding-next-btn');
        const skipBtn = document.getElementById('onboarding-skip-btn');
        const dotsContainer = document.getElementById('onboarding-dots');

        let currentSlide = 0;
        const totalSlides = 4;

        const updateSlide = (newSlide) => {
            const slides = document.querySelectorAll('.onboarding-slide');
            const dots = document.querySelectorAll('.onboarding-dot');

            // Mark current slide as exiting
            slides[currentSlide].classList.remove('active');
            slides[currentSlide].classList.add('exiting');

            // Short delay before activating new slide
            setTimeout(() => {
                slides[currentSlide].classList.remove('exiting');
            }, 300);

            // Activate new slide
            currentSlide = newSlide;
            slides[currentSlide].classList.add('active');

            // Update dots
            dots.forEach((dot, index) => {
                dot.classList.toggle('active', index === currentSlide);
            });

            // Update next button text
            if (currentSlide === totalSlides - 1) {
                nextBtn.textContent = 'Get Started';
            } else {
                nextBtn.textContent = 'Next';
            }
        };

        const completeOnboarding = async () => {
            modal.hidden = true;
            await this.db.setSetting('hasSeenOnboarding', true);
            Toast.show('Welcome to TimeFlow!', 'success');
        };

        // Next button click
        nextBtn.addEventListener('click', () => {
            if (currentSlide < totalSlides - 1) {
                updateSlide(currentSlide + 1);
            } else {
                completeOnboarding();
            }
        });

        // Skip button click
        skipBtn.addEventListener('click', () => {
            completeOnboarding();
        });

        // Dot clicks
        dotsContainer.addEventListener('click', (e) => {
            const dot = e.target.closest('.onboarding-dot');
            if (dot) {
                const slideIndex = parseInt(dot.dataset.slide);
                if (slideIndex !== currentSlide) {
                    updateSlide(slideIndex);
                }
            }
        });

        // Show the modal
        modal.hidden = false;
    }

    setupEventListeners() {
        // Navigation
        document.getElementById('prev-day-btn').addEventListener('click', () => this.navigateDay(-1));
        document.getElementById('next-day-btn').addEventListener('click', () => this.navigateDay(1));

        // FAB - Add task
        document.getElementById('add-task-btn').addEventListener('click', () => this.openTaskModal());

        // Task modal
        document.getElementById('close-modal-btn').addEventListener('click', () => this.closeTaskModal());
        document.getElementById('task-modal').addEventListener('click', (e) => {
            if (e.target.id === 'task-modal') this.closeTaskModal();
        });
        document.getElementById('task-form').addEventListener('submit', (e) => this.handleTaskSubmit(e));
        document.getElementById('delete-task-btn').addEventListener('click', () => this.deleteCurrentTask());

        // Title suggestions
        const titleInput = document.getElementById('task-title');
        const suggestionsContainer = document.getElementById('title-suggestions');

        titleInput.addEventListener('input', () => this.showTitleSuggestions());
        titleInput.addEventListener('focus', () => this.showTitleSuggestions());
        titleInput.addEventListener('blur', () => {
            // Delay hiding to allow click on suggestion
            setTimeout(() => suggestionsContainer.hidden = true, 200);
        });

        suggestionsContainer.addEventListener('click', (e) => {
            const item = e.target.closest('.suggestion-item');
            if (item) {
                titleInput.value = item.textContent;
                suggestionsContainer.hidden = true;
            }
        });

        // Duration presets
        document.getElementById('duration-presets').addEventListener('click', (e) => {
            const btn = e.target.closest('.duration-preset-btn');
            if (btn) {
                const duration = parseInt(btn.dataset.duration);
                this.applyDurationPreset(duration);

                // Highlight active button
                document.querySelectorAll('.duration-preset-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
            }
        });

        // Color picker
        document.getElementById('task-color-picker').addEventListener('click', (e) => {
            const btn = e.target.closest('.color-btn');
            if (btn) {
                const color = btn.dataset.color;
                document.getElementById('task-color').value = color;
                this.setSelectedColor(color);
            }
        });

        // Attachment handling
        const attachmentBtn = document.getElementById('attachment-btn');
        const attachmentInput = document.getElementById('task-attachment');
        const attachmentPreview = document.getElementById('attachment-preview');
        const attachmentPreviewImg = document.getElementById('attachment-preview-img');
        const removeAttachmentBtn = document.getElementById('remove-attachment-btn');

        attachmentBtn.addEventListener('click', () => attachmentInput.click());

        attachmentInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                this.handleAttachmentFile(file);
            }
        });

        removeAttachmentBtn.addEventListener('click', () => {
            this.clearAttachment();
        });

        // Virtual keyboard handling - ensure inputs stay visible
        this.setupVirtualKeyboardHandling();

        // Settings modal
        document.getElementById('settings-btn').addEventListener('click', () => this.openSettingsModal());
        document.getElementById('close-settings-btn').addEventListener('click', () => this.closeSettingsModal());
        document.getElementById('settings-modal').addEventListener('click', (e) => {
            if (e.target.id === 'settings-modal') this.closeSettingsModal();
        });

        // Settings changes
        document.getElementById('theme-select').addEventListener('change', (e) => this.updateSetting('theme', e.target.value));
        document.getElementById('notifications-enabled').addEventListener('change', (e) => this.updateSetting('notificationsEnabled', e.target.checked));
        document.getElementById('default-reminder').addEventListener('change', (e) => this.updateSetting('defaultReminderMinutes', parseInt(e.target.value)));
        document.getElementById('timeline-density').addEventListener('input', (e) => this.updateSetting('timelineDensity', parseFloat(e.target.value)));

        // Share modal
        document.getElementById('share-btn').addEventListener('click', () => this.openShareModal());
        document.getElementById('close-share-btn')?.addEventListener('click', () => this.closeShareModal());
        document.getElementById('share-modal').addEventListener('click', (e) => {
            if (e.target.id === 'share-modal') this.closeShareModal();
        });
        document.getElementById('share-image-btn')?.addEventListener('click', () => this.shareAsImage());
        document.getElementById('share-text-btn')?.addEventListener('click', () => this.shareAsText());
        document.getElementById('copy-link-btn')?.addEventListener('click', () => this.copyLink());
        document.getElementById('share-hide-details')?.addEventListener('change', () => this.renderSharePreview());
        document.getElementById('share-start-time')?.addEventListener('change', () => this.renderSharePreview());
        document.getElementById('share-end-time')?.addEventListener('change', () => this.renderSharePreview());
        document.getElementById('share-reset-range')?.addEventListener('click', () => this.resetShareTimeRange());

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                // Close modals in order of priority (most recent first)
                const confirmModal = document.getElementById('confirm-modal');
                const shareModal = document.getElementById('share-modal');
                const settingsModal = document.getElementById('settings-modal');
                const taskModal = document.getElementById('task-modal');

                if (!confirmModal.hidden) {
                    // If confirm modal is open, close it but keep task modal
                    confirmModal.hidden = true;
                } else if (!shareModal.hidden) {
                    this.closeShareModal();
                } else if (!settingsModal.hidden) {
                    this.closeSettingsModal();
                } else if (!taskModal.hidden) {
                    this.closeTaskModal();
                }
            }
            if (e.key === 'n' && !e.target.matches('input, textarea')) {
                e.preventDefault();
                this.openTaskModal();
            }
        });
    }

    startRealTimeUpdates() {
        // Update NOW line every second
        this.updateInterval = setInterval(() => {
            this.renderer.updateNowLine();
            this.renderer.autoScroll();
        }, 1000);

        // Update reminder lines every 10 seconds (state changes at 15min and 5min thresholds)
        this.reminderLineInterval = setInterval(() => {
            const timeline = document.getElementById('timeline');
            const tasks = this.state.state.tasks;
            const currentMinutes = Utils.getCurrentTimeMinutes();
            this.renderer.renderReminderLines(tasks, timeline, currentMinutes);
        }, 10000);

        // Initial update
        this.renderer.updateNowLine();

        // Set up scroll listener to pause auto-scroll when user scrolls manually
        const timeline = document.getElementById('timeline');
        const jumpToNowBtn = document.getElementById('jump-to-now-btn');
        let userScrolling = false;

        timeline.addEventListener('scroll', () => {
            if (!userScrolling) {
                userScrolling = true;
                this.renderer.pauseAutoScroll(10000); // Pause for 10 seconds after manual scroll
                setTimeout(() => { userScrolling = false; }, 100);
            }

            // Show/hide jump to NOW button based on scroll position
            const currentMinutes = Utils.getCurrentTimeMinutes();
            const targetScroll = (currentMinutes / 60) * this.renderer.hourHeight - (timeline.clientHeight * 0.7);
            const scrollDiff = Math.abs(timeline.scrollTop - targetScroll);

            // Show button if scrolled more than 200px away from current time
            if (scrollDiff > 200) {
                jumpToNowBtn.hidden = false;
            } else {
                jumpToNowBtn.hidden = true;
            }
        });

        // Jump to NOW button click handler
        jumpToNowBtn.addEventListener('click', () => {
            this.renderer.scrollToCurrentTime(true);
            jumpToNowBtn.hidden = true;
        });

        // Pinch to zoom timeline functionality
        this.setupPinchToZoom(timeline);
    }

    setupPinchToZoom(timeline) {
        let initialDistance = 0;
        let initialDensity = 1;
        let isPinching = false;

        // Calculate distance between two touch points
        const getDistance = (touch1, touch2) => {
            const dx = touch1.clientX - touch2.clientX;
            const dy = touch1.clientY - touch2.clientY;
            return Math.sqrt(dx * dx + dy * dy);
        };

        timeline.addEventListener('touchstart', (e) => {
            if (e.touches.length === 2) {
                isPinching = true;
                initialDistance = getDistance(e.touches[0], e.touches[1]);
                initialDensity = this.state.state.settings.timelineDensity;
                e.preventDefault();
            }
        }, { passive: false });

        timeline.addEventListener('touchmove', (e) => {
            if (isPinching && e.touches.length === 2) {
                const currentDistance = getDistance(e.touches[0], e.touches[1]);
                const scale = currentDistance / initialDistance;

                // Calculate new density (clamped between 0.5 and 2)
                let newDensity = initialDensity * scale;
                newDensity = Math.max(0.5, Math.min(2, newDensity));

                // Apply the new density
                this.applyTimelineDensity(newDensity);

                // Pause auto-scroll during pinch
                this.renderer.pauseAutoScroll(5000);

                e.preventDefault();
            }
        }, { passive: false });

        timeline.addEventListener('touchend', (e) => {
            if (isPinching && e.touches.length < 2) {
                isPinching = false;

                // Save the final density to settings
                const finalDensity = parseFloat(document.documentElement.style.getPropertyValue('--hour-height') || '80') / 80;
                const clampedDensity = Math.max(0.5, Math.min(2, finalDensity));
                this.updateSetting('timelineDensity', clampedDensity);

                // Update settings slider to reflect new value
                const densitySlider = document.getElementById('timeline-density');
                if (densitySlider) {
                    densitySlider.value = clampedDensity;
                }
            }
        });

        // Also support wheel zoom for desktop (Ctrl + scroll)
        timeline.addEventListener('wheel', (e) => {
            if (e.ctrlKey) {
                e.preventDefault();
                const delta = e.deltaY > 0 ? -0.1 : 0.1;
                const currentDensity = this.state.state.settings.timelineDensity;
                let newDensity = currentDensity + delta;
                newDensity = Math.max(0.5, Math.min(2, newDensity));

                this.applyTimelineDensity(newDensity);
                this.updateSetting('timelineDensity', newDensity);

                // Update settings slider
                const densitySlider = document.getElementById('timeline-density');
                if (densitySlider) {
                    densitySlider.value = newDensity;
                }
            }
        }, { passive: false });
    }

    async loadTasksForDate(date) {
        const tasks = await this.db.getTasksByDate(date);
        tasks.sort((a, b) => Utils.timeToMinutes(a.startTime) - Utils.timeToMinutes(b.startTime));
        this.state.setState({ tasks, currentDate: date });
        this.renderer.render(tasks);
    }

    updateDateDisplay() {
        const { currentDate } = this.state.state;
        document.getElementById('current-date').textContent = Utils.formatDate(currentDate);
        document.getElementById('date-subtitle').textContent = Utils.formatDateSubtitle(currentDate);
    }

    async navigateDay(delta) {
        const { currentDate } = this.state.state;
        const newDate = new Date(currentDate);
        newDate.setDate(newDate.getDate() + delta);
        await this.loadTasksForDate(newDate);
        this.updateDateDisplay();
        this.updateUrlHash();
    }

    // Deep linking support
    getDateFromUrl() {
        const hash = window.location.hash;
        const match = hash.match(/date=(\d{4}-\d{2}-\d{2})/);
        if (match) {
            const dateStr = match[1];
            const date = new Date(dateStr + 'T00:00:00');
            // Validate the date is valid
            if (!isNaN(date.getTime())) {
                return date;
            }
        }
        return null;
    }

    updateUrlHash() {
        const { currentDate } = this.state.state;
        const dateStr = this.db._formatDate(currentDate);
        const today = this.db._formatDate(new Date());

        // Only show hash if not today (cleaner URLs)
        if (dateStr === today) {
            history.replaceState(null, '', window.location.pathname);
        } else {
            history.replaceState(null, '', `#date=${dateStr}`);
        }
    }

    // Navigate to a specific date (for deep linking)
    async navigateToDate(date) {
        await this.loadTasksForDate(date);
        this.updateDateDisplay();
        this.updateUrlHash();
    }

    // Task Management
    openTaskModal(task = null) {
        const modal = document.getElementById('task-modal');
        const form = document.getElementById('task-form');
        const title = document.getElementById('modal-title');
        const deleteBtn = document.getElementById('delete-task-btn');

        form.reset();
        this.clearAttachment(); // Reset attachment state

        if (task) {
            title.textContent = 'Edit Task';
            document.getElementById('task-id').value = task.id;
            document.getElementById('task-title').value = task.title;
            document.getElementById('task-start-time').value = task.startTime;
            document.getElementById('task-end-time').value = task.endTime;
            document.getElementById('task-description').value = task.description || '';
            document.getElementById('task-important').checked = task.isImportant || false;
            document.getElementById('task-reminder').value = task.reminderMinutes || '';
            document.getElementById('task-recurring').value = task.recurring || '';
            document.getElementById('task-color').value = task.color || '';
            this.setSelectedColor(task.color || '');

            // Handle attachment
            if (task.attachmentData) {
                document.getElementById('task-attachment-data').value = task.attachmentData;
                this.setAttachmentPreview(task.attachmentData);
            }

            deleteBtn.hidden = false;
            this.state.setState({ editingTask: task });
        } else {
            title.textContent = 'New Task';
            // Set default times
            const now = new Date();
            const currentHour = now.getHours();
            const startTime = `${currentHour.toString().padStart(2, '0')}:00`;
            const endTime = `${(currentHour + 1).toString().padStart(2, '0')}:00`;
            document.getElementById('task-start-time').value = startTime;
            document.getElementById('task-end-time').value = endTime;
            document.getElementById('task-color').value = '';
            this.setSelectedColor('');
            deleteBtn.hidden = true;
            this.state.setState({ editingTask: null });
        }

        modal.hidden = false;
        document.getElementById('task-title').focus();
    }

    setSelectedColor(color) {
        const buttons = document.querySelectorAll('#task-color-picker .color-btn');
        buttons.forEach(btn => {
            btn.classList.toggle('selected', btn.dataset.color === color);
        });
    }

    handleAttachmentFile(file) {
        // Validate file type (images only)
        if (!file.type.startsWith('image/')) {
            Toast.show('Please select an image file', 'error');
            return;
        }

        // Validate file size (max 5MB)
        const maxSize = 5 * 1024 * 1024;
        if (file.size > maxSize) {
            Toast.show('Image too large. Maximum size is 5MB', 'error');
            return;
        }

        const reader = new FileReader();
        reader.onload = (e) => {
            const dataUrl = e.target.result;
            this.setAttachmentPreview(dataUrl);
            document.getElementById('task-attachment-data').value = dataUrl;
        };
        reader.onerror = () => {
            Toast.show('Failed to read file', 'error');
        };
        reader.readAsDataURL(file);
    }

    setAttachmentPreview(dataUrl) {
        const preview = document.getElementById('attachment-preview');
        const previewImg = document.getElementById('attachment-preview-img');
        const attachmentBtn = document.getElementById('attachment-btn');

        if (dataUrl) {
            previewImg.src = dataUrl;
            preview.hidden = false;
            attachmentBtn.textContent = 'Change Photo/File';
        } else {
            previewImg.src = '';
            preview.hidden = true;
            attachmentBtn.innerHTML = `
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path>
                </svg>
                Add Photo/File`;
        }
    }

    clearAttachment() {
        document.getElementById('task-attachment').value = '';
        document.getElementById('task-attachment-data').value = '';
        this.setAttachmentPreview(null);
    }

    setupVirtualKeyboardHandling() {
        // Use Visual Viewport API if available
        if (window.visualViewport) {
            const taskModal = document.getElementById('task-modal');
            const settingsModal = document.getElementById('settings-modal');

            const handleViewportResize = () => {
                const { height, offsetTop } = window.visualViewport;

                // When keyboard is open, visual viewport height is less than layout viewport
                const keyboardOpen = window.innerHeight - height > 100;

                if (keyboardOpen) {
                    // Find the focused element
                    const focusedElement = document.activeElement;
                    if (focusedElement && (focusedElement.tagName === 'INPUT' || focusedElement.tagName === 'TEXTAREA' || focusedElement.tagName === 'SELECT')) {
                        // Scroll the focused element into view after a small delay
                        setTimeout(() => {
                            focusedElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        }, 100);
                    }
                }
            };

            window.visualViewport.addEventListener('resize', handleViewportResize);
            window.visualViewport.addEventListener('scroll', handleViewportResize);
        }

        // Fallback for browsers without Visual Viewport API
        // Use scroll-margin-bottom on form inputs
        const formInputs = document.querySelectorAll('.task-form input, .task-form textarea, .task-form select');
        formInputs.forEach(input => {
            input.addEventListener('focus', (e) => {
                // Small delay to allow keyboard to appear
                setTimeout(() => {
                    e.target.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }, 300);
            });
        });
    }

    closeTaskModal() {
        document.getElementById('task-modal').hidden = true;
        this.state.setState({ editingTask: null });
    }

    applyDurationPreset(durationMinutes) {
        const startInput = document.getElementById('task-start-time');
        const endInput = document.getElementById('task-end-time');

        // If no start time, use current time rounded to nearest 15 minutes
        if (!startInput.value) {
            const now = new Date();
            const minutes = Math.ceil(now.getMinutes() / 15) * 15;
            now.setMinutes(minutes);
            now.setSeconds(0);
            startInput.value = now.toTimeString().slice(0, 5);
        }

        // Calculate end time from start time + duration
        const [hours, mins] = startInput.value.split(':').map(Number);
        const startMinutes = hours * 60 + mins;
        const endMinutes = startMinutes + durationMinutes;

        const endHours = Math.floor(endMinutes / 60) % 24;
        const endMins = endMinutes % 60;
        endInput.value = `${String(endHours).padStart(2, '0')}:${String(endMins).padStart(2, '0')}`;
    }

    async showTitleSuggestions() {
        const titleInput = document.getElementById('task-title');
        const suggestionsContainer = document.getElementById('title-suggestions');
        const query = titleInput.value.trim().toLowerCase();

        if (query.length < 2) {
            suggestionsContainer.hidden = true;
            return;
        }

        // Get all unique task titles from history
        const allTasks = await this.db.getAllTaskTitles();
        const suggestions = allTasks.filter(title =>
            title.toLowerCase().includes(query) && title.toLowerCase() !== query
        ).slice(0, 5); // Limit to 5 suggestions

        if (suggestions.length === 0) {
            suggestionsContainer.hidden = true;
            return;
        }

        suggestionsContainer.innerHTML = suggestions
            .map(title => `<div class="suggestion-item">${title}</div>`)
            .join('');
        suggestionsContainer.hidden = false;
    }

    async handleTaskSubmit(e) {
        e.preventDefault();

        const form = e.target;
        const formData = new FormData(form);
        const saveBtn = form.querySelector('button[type="submit"]');

        const editingTask = this.state.state.editingTask;
        const attachmentData = document.getElementById('task-attachment-data').value || null;
        const task = {
            id: formData.get('id') || null,
            title: formData.get('title').trim(),
            startTime: formData.get('startTime'),
            endTime: formData.get('endTime'),
            description: formData.get('description')?.trim() || '',
            isImportant: form.querySelector('#task-important').checked,
            reminderMinutes: formData.get('reminderMinutes') ? parseInt(formData.get('reminderMinutes')) : null,
            recurring: formData.get('recurring') || null,
            color: formData.get('color') || null,
            attachmentData: attachmentData,
            date: this.db._formatDate(this.state.state.currentDate),
            isCompleted: editingTask?.isCompleted || false,
            createdAt: editingTask?.createdAt || null
        };

        // Validation
        if (!task.title || !task.title.trim()) {
            Toast.show('Please enter a task title', 'error');
            const titleField = document.getElementById('task-title');
            titleField?.focus();
            titleField?.setAttribute('aria-invalid', 'true');
            return;
        }

        const startMinutes = Utils.timeToMinutes(task.startTime);
        const endMinutes = Utils.timeToMinutes(task.endTime);

        if (endMinutes <= startMinutes) {
            Toast.show('End time must be after start time', 'error');
            const endTimeField = document.getElementById('task-end-time');
            endTimeField?.focus();
            endTimeField?.setAttribute('aria-invalid', 'true');
            return;
        }

        // Clear any previous aria-invalid states
        document.getElementById('task-title')?.removeAttribute('aria-invalid');
        document.getElementById('task-end-time')?.removeAttribute('aria-invalid');

        // Show loading state
        this.setButtonLoading(saveBtn, true);
        const isNewTask = !task.id;

        try {
            const savedTask = await this.db.saveTask(task);
            await this.loadTasksForDate(this.state.state.currentDate);

            // Broadcast update to other tabs
            this.broadcastTaskUpdate(savedTask.id, 'saved');

            // Reschedule notifications if this is for today
            if (task.reminderMinutes) {
                const today = new Date();
                const taskDateStr = this.db._formatDate(today);
                if (task.date === taskDateStr) {
                    this.scheduleNotificationForTask(savedTask, today);
                }
            }

            this.closeTaskModal();
            const message = isNewTask ? 'Task created' : 'Task updated';
            Toast.show(message, 'success');
            Utils.announceToScreenReader(`${task.title} ${message.toLowerCase()}`);
        } catch (error) {
            console.error('Failed to save task:', error);
            Toast.show('Failed to save task', 'error');
            Utils.announceToScreenReader('Failed to save task');
        } finally {
            // Clear loading state
            this.setButtonLoading(saveBtn, false);
        }
    }

    setButtonLoading(button, isLoading) {
        if (isLoading) {
            button.disabled = true;
            button.classList.add('loading');
            button.dataset.originalText = button.textContent;
            button.innerHTML = '<span class="spinner"></span> Saving...';
        } else {
            button.disabled = false;
            button.classList.remove('loading');
            if (button.dataset.originalText) {
                button.textContent = button.dataset.originalText;
            }
        }
    }

    async editTask(taskId) {
        // Check if this is a recurring instance (virtual ID format: originalId_date)
        const tasks = this.state.state.tasks;
        let task = tasks.find(t => t.id === taskId);

        // If not in current state, try to get from DB
        if (!task) {
            task = await this.db.getTask(taskId);
        }

        if (task) {
            // If editing a recurring instance, show choice dialog
            if (task.isRecurringInstance && task.originalId) {
                this.showRecurringEditChoice(task);
            } else {
                this.openTaskModal(task);
            }
        }
    }

    showRecurringEditChoice(task) {
        const modal = document.getElementById('confirm-modal');
        const titleEl = document.getElementById('confirm-title');
        const messageEl = document.getElementById('confirm-message');
        const cancelBtn = document.getElementById('confirm-cancel-btn');
        const confirmBtn = document.getElementById('confirm-delete-btn');

        titleEl.textContent = 'Edit Recurring Task';
        messageEl.textContent = `"${task.title}" is a recurring task. What would you like to edit?`;

        // Change button texts
        cancelBtn.textContent = 'This occurrence only';
        confirmBtn.textContent = 'All occurrences';

        modal.hidden = false;

        const cleanup = () => {
            cancelBtn.removeEventListener('click', handleThisOnly);
            confirmBtn.removeEventListener('click', handleAll);
            modal.removeEventListener('click', handleOverlayClick);
            cancelBtn.textContent = 'Cancel';
            confirmBtn.textContent = 'Delete';
        };

        const handleThisOnly = async () => {
            modal.hidden = true;
            cleanup();
            // Create a new standalone task for this date only
            const newTask = {
                ...task,
                id: null, // Will generate new ID
                recurring: null, // Not recurring
                isRecurringInstance: false,
                originalId: undefined
            };
            this.openTaskModal(newTask);
        };

        const handleAll = async () => {
            modal.hidden = true;
            cleanup();
            // Edit the original recurring task
            const originalTask = await this.db.getTask(task.originalId);
            if (originalTask) {
                this.openTaskModal(originalTask);
            }
        };

        const handleOverlayClick = (e) => {
            if (e.target === modal) {
                modal.hidden = true;
                cleanup();
            }
        };

        cancelBtn.addEventListener('click', handleThisOnly);
        confirmBtn.addEventListener('click', handleAll);
        modal.addEventListener('click', handleOverlayClick);
    }

    async deleteCurrentTask() {
        const { editingTask } = this.state.state;
        if (!editingTask) return;

        const taskTitle = editingTask.title;

        // If this is a recurring task instance, delete the original task (all instances)
        if (editingTask.isRecurringInstance && editingTask.originalId) {
            this.showConfirmDialog(
                'Delete Recurring Task',
                `Are you sure you want to delete "${taskTitle}" and all its recurring instances? This action cannot be undone.`,
                async () => {
                    try {
                        await this.db.deleteTask(editingTask.originalId);
                        await this.loadTasksForDate(this.state.state.currentDate);
                        this.broadcastTaskUpdate(editingTask.originalId, 'deleted');
                        this.closeTaskModal();
                        Toast.show('Recurring task deleted', 'success');
                        Utils.announceToScreenReader(`${taskTitle} and all instances deleted`);
                    } catch (error) {
                        console.error('Failed to delete task:', error);
                        Toast.show('Failed to delete task', 'error');
                        Utils.announceToScreenReader('Failed to delete task');
                    }
                }
            );
        } else if (editingTask.recurring) {
            // Original recurring task - delete it and all future instances
            this.showConfirmDialog(
                'Delete Recurring Task',
                `Are you sure you want to delete "${taskTitle}" and all its future occurrences? This action cannot be undone.`,
                async () => {
                    try {
                        await this.db.deleteTask(editingTask.id);
                        await this.loadTasksForDate(this.state.state.currentDate);
                        this.broadcastTaskUpdate(editingTask.id, 'deleted');
                        this.closeTaskModal();
                        Toast.show('Recurring task deleted', 'success');
                        Utils.announceToScreenReader(`${taskTitle} and all instances deleted`);
                    } catch (error) {
                        console.error('Failed to delete task:', error);
                        Toast.show('Failed to delete task', 'error');
                        Utils.announceToScreenReader('Failed to delete task');
                    }
                }
            );
        } else {
            // Regular one-time task
            this.showConfirmDialog(
                'Delete Task',
                `Are you sure you want to delete "${taskTitle}"? This action cannot be undone.`,
                async () => {
                    try {
                        await this.db.deleteTask(editingTask.id);
                        await this.loadTasksForDate(this.state.state.currentDate);
                        this.broadcastTaskUpdate(editingTask.id, 'deleted');
                        this.closeTaskModal();
                        Toast.show('Task deleted', 'success');
                        Utils.announceToScreenReader(`${taskTitle} deleted`);
                    } catch (error) {
                        console.error('Failed to delete task:', error);
                        Toast.show('Failed to delete task', 'error');
                        Utils.announceToScreenReader('Failed to delete task');
                    }
                }
            );
        }
    }

    showConfirmDialog(title, message, onConfirm) {
        const modal = document.getElementById('confirm-modal');
        const titleEl = document.getElementById('confirm-title');
        const messageEl = document.getElementById('confirm-message');
        const cancelBtn = document.getElementById('confirm-cancel-btn');
        const confirmBtn = document.getElementById('confirm-delete-btn');

        titleEl.textContent = title;
        messageEl.textContent = message;
        modal.hidden = false;

        // Store the callback and set up event listeners
        const cleanup = () => {
            cancelBtn.removeEventListener('click', handleCancel);
            confirmBtn.removeEventListener('click', handleConfirm);
            modal.removeEventListener('click', handleOverlayClick);
        };

        const handleCancel = () => {
            modal.hidden = true;
            cleanup();
        };

        const handleConfirm = () => {
            modal.hidden = true;
            cleanup();
            onConfirm();
        };

        const handleOverlayClick = (e) => {
            if (e.target === modal) {
                handleCancel();
            }
        };

        cancelBtn.addEventListener('click', handleCancel);
        confirmBtn.addEventListener('click', handleConfirm);
        modal.addEventListener('click', handleOverlayClick);

        // Focus the cancel button for accessibility
        cancelBtn.focus();
    }

    async toggleTaskComplete(taskId) {
        const task = await this.db.getTask(taskId);
        if (task) {
            task.isCompleted = !task.isCompleted;
            await this.db.saveTask(task);
            await this.loadTasksForDate(this.state.state.currentDate);
            Toast.show(task.isCompleted ? 'Task completed' : 'Task reopened', 'success');
        }
    }

    // Settings
    openSettingsModal() {
        const { settings } = this.state.state;
        document.getElementById('theme-select').value = settings.theme;
        document.getElementById('notifications-enabled').checked = settings.notificationsEnabled;
        document.getElementById('default-reminder').value = settings.defaultReminderMinutes;
        document.getElementById('timeline-density').value = settings.timelineDensity;
        document.getElementById('settings-modal').hidden = false;
    }

    closeSettingsModal() {
        document.getElementById('settings-modal').hidden = true;
    }

    async updateSetting(key, value) {
        const { settings } = this.state.state;
        settings[key] = value;
        this.state.setState({ settings });
        await this.db.setSetting(key, value);

        if (key === 'theme') {
            this.applyTheme(value);
        }

        if (key === 'timelineDensity') {
            this.applyTimelineDensity(value);
        }
    }

    applyTimelineDensity(density) {
        const baseHeight = 80;
        const newHeight = baseHeight * density;
        this.renderer.hourHeight = newHeight;
        document.documentElement.style.setProperty('--hour-height', `${newHeight}px`);
        // Re-render tasks with new density
        this.renderer.render(this.state.state.tasks);
    }

    applyTheme(theme) {
        if (theme === 'auto') {
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            document.documentElement.dataset.theme = prefersDark ? 'dark' : 'light';
        } else {
            document.documentElement.dataset.theme = theme;
        }
    }

    // Share functionality
    openShareModal() {
        document.getElementById('share-modal').hidden = false;
        // Reset privacy option
        document.getElementById('share-hide-details').checked = false;
        // Set default time range to full day (00:00 to 23:59)
        document.getElementById('share-start-time').value = '00:00';
        document.getElementById('share-end-time').value = '23:59';
        this.renderSharePreview();
    }

    closeShareModal() {
        document.getElementById('share-modal').hidden = true;
    }

    isHideDetailsEnabled() {
        return document.getElementById('share-hide-details')?.checked || false;
    }

    getShareTimeRange() {
        const startTime = document.getElementById('share-start-time')?.value || '00:00';
        const endTime = document.getElementById('share-end-time')?.value || '23:59';
        return { startTime, endTime };
    }

    resetShareTimeRange() {
        document.getElementById('share-start-time').value = '00:00';
        document.getElementById('share-end-time').value = '23:59';
        this.renderSharePreview();
    }

    getFilteredTasksForShare() {
        const { tasks } = this.state.state;
        const { startTime, endTime } = this.getShareTimeRange();

        // Parse time range into minutes from midnight
        const [startH, startM] = startTime.split(':').map(Number);
        const [endH, endM] = endTime.split(':').map(Number);
        const rangeStart = startH * 60 + startM;
        const rangeEnd = endH * 60 + endM;

        return tasks.filter(task => {
            // Task startTime and endTime are stored as time strings like "09:30"
            const [taskStartH, taskStartM] = task.startTime.split(':').map(Number);
            const [taskEndH, taskEndM] = task.endTime.split(':').map(Number);
            const taskStart = taskStartH * 60 + taskStartM;
            const taskEnd = taskEndH * 60 + taskEndM;

            // Task is included if it overlaps with the time range
            // A task overlaps if: task starts before range ends AND task ends after range starts
            return taskStart < rangeEnd && taskEnd > rangeStart;
        });
    }

    renderSharePreview() {
        const { currentDate } = this.state.state;
        const preview = document.getElementById('share-preview');
        const hideDetails = this.isHideDetailsEnabled();
        const { startTime, endTime } = this.getShareTimeRange();
        const filteredTasks = this.getFilteredTasksForShare();

        let html = `<h4>${Utils.formatDate(currentDate)}</h4>`;
        html += `<p style="font-size: 0.875rem; color: var(--text-secondary); margin-bottom: 12px;">Showing tasks from ${startTime} to ${endTime}</p>`;

        if (filteredTasks.length === 0) {
            html += `<p style="text-align: center; color: var(--text-hint); padding: 20px;">No tasks in this time range</p>`;
        } else {
            html += `<ul style="list-style: none; padding: 0;">`;
            filteredTasks.forEach(task => {
                html += `<li style="padding: 8px 0; border-bottom: 1px solid var(--border-color);">
                    <strong>${Utils.formatTime(task.startTime)} - ${Utils.formatTime(task.endTime)}</strong>: ${task.title}`;
                if (!hideDetails && task.description) {
                    html += `<br><small style="color: var(--text-secondary);">${task.description}</small>`;
                }
                html += `</li>`;
            });
            html += '</ul>';
        }

        preview.innerHTML = html;
    }

    async shareAsImage() {
        const preview = document.getElementById('share-preview');
        try {
            // Use html2canvas if available, otherwise show a message
            if (typeof html2canvas !== 'undefined') {
                const canvas = await html2canvas(preview);
                canvas.toBlob(async (blob) => {
                    if (navigator.share && navigator.canShare && navigator.canShare({ files: [new File([blob], 'schedule.png', { type: 'image/png' })] })) {
                        const file = new File([blob], 'schedule.png', { type: 'image/png' });
                        await navigator.share({
                            files: [file],
                            title: 'My Schedule'
                        });
                    } else {
                        // Download the image
                        const url = URL.createObjectURL(blob);
                        const a = document.createElement('a');
                        a.href = url;
                        a.download = `schedule-${new Date().toISOString().split('T')[0]}.png`;
                        a.click();
                        URL.revokeObjectURL(url);
                        Toast.show('Image downloaded!', 'success');
                    }
                });
            } else {
                Toast.show('Image sharing not available', 'info');
            }
        } catch (error) {
            Toast.show('Failed to share as image', 'error');
        }
    }

    async shareAsText() {
        const { currentDate } = this.state.state;
        const hideDetails = this.isHideDetailsEnabled();
        const { startTime, endTime } = this.getShareTimeRange();
        const filteredTasks = this.getFilteredTasksForShare();
        let text = `📅 ${Utils.formatDate(currentDate)}\n`;
        text += `⏱️ ${startTime} - ${endTime}\n\n`;

        if (filteredTasks.length === 0) {
            text += 'No tasks in this time range\n';
        } else {
            filteredTasks.forEach(task => {
                const status = task.isCompleted ? '✅' : '⏰';
                text += `${status} ${Utils.formatTime(task.startTime)} - ${Utils.formatTime(task.endTime)}: ${task.title}\n`;
                if (!hideDetails && task.description) {
                    text += `   ${task.description}\n`;
                }
            });
        }

        try {
            if (navigator.share) {
                await navigator.share({
                    title: 'My Schedule',
                    text: text
                });
            } else {
                await navigator.clipboard.writeText(text);
                Toast.show('Schedule copied to clipboard!', 'success');
            }
        } catch (error) {
            Toast.show('Failed to share', 'error');
        }
    }

    async copyLink() {
        // In a real app, this would generate a shareable link
        // For now, we'll copy the text version
        const { currentDate } = this.state.state;
        const { startTime, endTime } = this.getShareTimeRange();
        const filteredTasks = this.getFilteredTasksForShare();
        let text = `TimeFlow Schedule - ${Utils.formatDate(currentDate)}\n`;
        text += `Time Range: ${startTime} - ${endTime}\n\n`;

        if (filteredTasks.length === 0) {
            text += 'No tasks in this time range\n';
        } else {
            filteredTasks.forEach(task => {
                text += `• ${Utils.formatTime(task.startTime)} - ${Utils.formatTime(task.endTime)}: ${task.title}\n`;
            });
        }

        try {
            await navigator.clipboard.writeText(text);
            Toast.show('Schedule copied to clipboard!', 'success');
        } catch (error) {
            Toast.show('Failed to copy', 'error');
        }
    }
}

// ============================================================================
// Initialize App
// ============================================================================

window.app = new TimeFlowApp();
document.addEventListener('DOMContentLoaded', () => {
    window.app.init();
});
