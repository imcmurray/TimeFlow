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

    async getTasksByDate(date) {
        const dateStr = this._formatDate(date);
        return this._getAllByIndex('tasks', 'date', dateStr);
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
        return date.toISOString().split('T')[0];
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
        container.appendChild(toast);

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
        const currentMinutes = Utils.getCurrentTimeMinutes();

        tasks.forEach(task => {
            const taskCard = this.createTaskCard(task, currentMinutes);
            timeline.appendChild(taskCard);
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
        card.dataset.taskId = task.id;
        card.style.top = `${top}px`;
        card.style.height = `${height}px`;

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

            // Load tasks for current date
            await this.loadTasksForDate(this.state.state.currentDate);

            // Set up event listeners
            this.setupEventListeners();

            // Start real-time updates
            this.startRealTimeUpdates();

            // Update header
            this.updateDateDisplay();

            console.log('TimeFlow initialized successfully');
        } catch (error) {
            console.error('Failed to initialize TimeFlow:', error);
            Toast.show('Failed to initialize app', 'error');
        }
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

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeTaskModal();
                this.closeSettingsModal();
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
    }

    // Task Management
    openTaskModal(task = null) {
        const modal = document.getElementById('task-modal');
        const form = document.getElementById('task-form');
        const title = document.getElementById('modal-title');
        const deleteBtn = document.getElementById('delete-task-btn');

        form.reset();

        if (task) {
            title.textContent = 'Edit Task';
            document.getElementById('task-id').value = task.id;
            document.getElementById('task-title').value = task.title;
            document.getElementById('task-start-time').value = task.startTime;
            document.getElementById('task-end-time').value = task.endTime;
            document.getElementById('task-description').value = task.description || '';
            document.getElementById('task-important').checked = task.isImportant || false;
            document.getElementById('task-reminder').value = task.reminderMinutes || '';
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
            deleteBtn.hidden = true;
            this.state.setState({ editingTask: null });
        }

        modal.hidden = false;
        document.getElementById('task-title').focus();
    }

    closeTaskModal() {
        document.getElementById('task-modal').hidden = true;
        this.state.setState({ editingTask: null });
    }

    async handleTaskSubmit(e) {
        e.preventDefault();

        const form = e.target;
        const formData = new FormData(form);

        const task = {
            id: formData.get('id') || null,
            title: formData.get('title').trim(),
            startTime: formData.get('startTime'),
            endTime: formData.get('endTime'),
            description: formData.get('description')?.trim() || '',
            isImportant: form.querySelector('#task-important').checked,
            reminderMinutes: formData.get('reminderMinutes') ? parseInt(formData.get('reminderMinutes')) : null,
            date: this.db._formatDate(this.state.state.currentDate),
            isCompleted: this.state.state.editingTask?.isCompleted || false
        };

        // Validation
        if (!task.title) {
            Toast.show('Please enter a task title', 'error');
            return;
        }

        const startMinutes = Utils.timeToMinutes(task.startTime);
        const endMinutes = Utils.timeToMinutes(task.endTime);

        if (endMinutes <= startMinutes) {
            Toast.show('End time must be after start time', 'error');
            return;
        }

        try {
            await this.db.saveTask(task);
            await this.loadTasksForDate(this.state.state.currentDate);
            this.closeTaskModal();
            Toast.show(task.id ? 'Task updated' : 'Task created', 'success');
        } catch (error) {
            console.error('Failed to save task:', error);
            Toast.show('Failed to save task', 'error');
        }
    }

    async editTask(taskId) {
        const task = await this.db.getTask(taskId);
        if (task) {
            this.openTaskModal(task);
        }
    }

    async deleteCurrentTask() {
        const { editingTask } = this.state.state;
        if (!editingTask) return;

        if (confirm('Are you sure you want to delete this task?')) {
            try {
                await this.db.deleteTask(editingTask.id);
                await this.loadTasksForDate(this.state.state.currentDate);
                this.closeTaskModal();
                Toast.show('Task deleted', 'success');
            } catch (error) {
                console.error('Failed to delete task:', error);
                Toast.show('Failed to delete task', 'error');
            }
        }
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
        this.renderSharePreview();
    }

    closeShareModal() {
        document.getElementById('share-modal').hidden = true;
    }

    renderSharePreview() {
        const { tasks, currentDate } = this.state.state;
        const preview = document.getElementById('share-preview');

        let html = `<h4>${Utils.formatDate(currentDate)}</h4><ul style="list-style: none; padding: 0;">`;
        tasks.forEach(task => {
            html += `<li style="padding: 8px 0; border-bottom: 1px solid var(--border-color);">
                <strong>${Utils.formatTime(task.startTime)} - ${Utils.formatTime(task.endTime)}</strong>: ${task.title}
            </li>`;
        });
        html += '</ul>';

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
        const { tasks, currentDate } = this.state.state;
        let text = `📅 ${Utils.formatDate(currentDate)}\n\n`;

        tasks.forEach(task => {
            const status = task.isCompleted ? '✅' : '⏰';
            text += `${status} ${Utils.formatTime(task.startTime)} - ${Utils.formatTime(task.endTime)}: ${task.title}\n`;
            if (task.description) {
                text += `   ${task.description}\n`;
            }
        });

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
        const { tasks, currentDate } = this.state.state;
        let text = `TimeFlow Schedule - ${Utils.formatDate(currentDate)}\n\n`;

        tasks.forEach(task => {
            text += `• ${Utils.formatTime(task.startTime)} - ${Utils.formatTime(task.endTime)}: ${task.title}\n`;
        });

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
