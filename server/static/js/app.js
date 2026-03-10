// Runner Race Timer - Web App JavaScript

class RaceTimerApp {
    constructor() {
        this.token = localStorage.getItem('token');
        this.user = null;
        this.apiBase = '/api';
        this.ws = null;
        this.syncInterval = null;
        
        this.init();
    }
    
    init() {
        this.bindEvents();
        if (this.token) {
            this.validateToken();
        }
    }
    
    bindEvents() {
        // Login/Register
        document.getElementById('login-form')?.addEventListener('submit', (e) => this.handleLogin(e));
        document.getElementById('register-form')?.addEventListener('submit', (e) => this.handleRegister(e));
        document.getElementById('show-register')?.addEventListener('click', (e) => {
            e.preventDefault();
            document.getElementById('login-form').style.display = 'none';
            document.getElementById('register-form').style.display = 'block';
        });
        document.getElementById('hide-register')?.addEventListener('click', () => {
            document.getElementById('login-form').style.display = 'block';
            document.getElementById('register-form').style.display = 'none';
        });
        document.getElementById('logout-btn')?.addEventListener('click', () => this.logout());
        
        // Tabs
        document.querySelectorAll('.tab').forEach(tab => {
            tab.addEventListener('click', (e) => this.switchTab(e.target.dataset.tab));
        });
        
        // Race actions
        document.getElementById('new-race-btn')?.addEventListener('click', () => this.showNewRaceModal());
        document.getElementById('results-race-select')?.addEventListener('change', (e) => this.loadResults(e.target.value));
        document.getElementById('entries-race-select')?.addEventListener('change', (e) => this.loadEntries(e.target.value));
        document.getElementById('new-entry-btn')?.addEventListener('click', () => this.showNewEntryModal());
        document.getElementById('generate-server-qr')?.addEventListener('click', () => this.generateServerQR());
    }
    
    // API Methods
    async api(endpoint, options = {}) {
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers,
        };
        
        if (this.token) {
            headers['Authorization'] = `Bearer ${this.token}`;
        }
        
        const response = await fetch(`${this.apiBase}${endpoint}`, {
            ...options,
            headers,
        });
        
        if (response.status === 401) {
            this.logout();
            throw new Error('Unauthorized');
        }
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.detail || 'Request failed');
        }
        
        return data;
    }
    
    // Authentication
    async handleLogin(e) {
        e.preventDefault();
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        
        try {
            const data = await this.api('/auth/login', {
                method: 'POST',
                body: JSON.stringify({ username, password }),
            });
            
            this.token = data.access_token;
            this.user = data.user;
            localStorage.setItem('token', this.token);
            
            this.showMainScreen();
        } catch (error) {
            alert(error.message);
        }
    }
    
    async handleRegister(e) {
        e.preventDefault();
        const username = document.getElementById('reg-username').value;
        const email = document.getElementById('reg-email').value;
        const full_name = document.getElementById('reg-fullname').value;
        const password = document.getElementById('reg-password').value;
        
        try {
            await this.api('/auth/register', {
                method: 'POST',
                body: JSON.stringify({ username, email, full_name, password }),
            });
            
            alert('Registration successful! Please login.');
            document.getElementById('register-form').style.display = 'none';
            document.getElementById('login-form').style.display = 'block';
        } catch (error) {
            alert(error.message);
        }
    }
    
    async validateToken() {
        try {
            const data = await this.api('/auth/me');
            this.user = data;
            this.showMainScreen();
        } catch (error) {
            this.logout();
        }
    }
    
    logout() {
        this.token = null;
        this.user = null;
        localStorage.removeItem('token');
        document.getElementById('login-screen').style.display = 'block';
        document.getElementById('main-screen').style.display = 'none';
        if (this.ws) {
            this.ws.close();
        }
        if (this.syncInterval) {
            clearInterval(this.syncInterval);
        }
    }
    
    // UI Methods
    showMainScreen() {
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('main-screen').style.display = 'block';
        document.getElementById('user-display').textContent = this.user?.full_name || this.user?.username;
        
        this.loadRaces();
        this.connectWebSocket();
    }
    
    switchTab(tabName) {
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        
        document.querySelector(`[data-tab="${tabName}"]`)?.classList.add('active');
        document.getElementById(`${tabName}-tab`)?.classList.add('active');
        
        if (tabName === 'races') this.loadRaces();
        if (tabName === 'results') this.loadRaceSelect('results-race-select');
        if (tabName === 'entries') this.loadRaceSelect('entries-race-select');
    }
    
    // Races
    async loadRaces() {
        try {
            const races = await this.api('/races?active_only=false');
            const container = document.getElementById('races-list');
            container.innerHTML = races.map(race => this.renderRaceCard(race)).join('');
        } catch (error) {
            console.error('Failed to load races:', error);
        }
    }
    
    renderRaceCard(race) {
        const statusBadge = race.is_active 
            ? '<span class="badge badge-success">Active</span>' 
            : '<span class="badge">Inactive</span>';
        
        return `
            <div class="card">
                <h3>${race.name}</h3>
                <p>${race.description || 'No description'}</p>
                <p><strong>Date:</strong> ${new Date(race.race_date).toLocaleDateString()}</p>
                <p><strong>Distance:</strong> ${race.race_time || 'N/A'}</p>
                <p><strong>Entries:</strong> ${race.entry_count || 0}</p>
                <p><strong>Scans:</strong> ${race.scan_count || 0}</p>
                <div style="margin: 1rem 0;">${statusBadge}</div>
                <div class="card-actions">
                    ${!race.is_active ? `<button class="btn btn-success btn-small" onclick="app.startRace('${race.id}')">Start</button>` : ''}
                    ${race.is_active ? `<button class="btn btn-danger btn-small" onclick="app.stopRace('${race.id}')">Stop</button>` : ''}
                    <button class="btn btn-secondary btn-small" onclick="app.viewRace('${race.id}')">View</button>
                </div>
            </div>
        `;
    }
    
    showNewRaceModal() {
        const modal = document.getElementById('modal-content');
        modal.innerHTML = `
            <h2>Create New Race</h2>
            <form id="new-race-form">
                <div class="form-group">
                    <label>Race Name</label>
                    <input type="text" name="name" required>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" rows="3"></textarea>
                </div>
                <div class="form-group">
                    <label>Race Date</label>
                    <input type="date" name="race_date" required>
                </div>
                <div class="form-group">
                    <label>Distance/Time</label>
                    <input type="text" name="race_time" placeholder="e.g., 5K, 10K, Marathon">
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn btn-secondary" onclick="app.closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Create</button>
                </div>
            </form>
        `;
        
        document.getElementById('new-race-form').addEventListener('submit', (e) => this.handleNewRace(e));
        document.getElementById('modal-overlay').style.display = 'flex';
    }
    
    async handleNewRace(e) {
        e.preventDefault();
        const formData = new FormData(e.target);
        const data = {
            name: formData.get('name'),
            description: formData.get('description'),
            race_date: new Date(formData.get('race_date')).toISOString(),
            race_time: formData.get('race_time'),
        };
        
        try {
            await this.api('/races', {
                method: 'POST',
                body: JSON.stringify(data),
            });
            this.closeModal();
            this.loadRaces();
        } catch (error) {
            alert(error.message);
        }
    }
    
    async startRace(raceId) {
        try {
            await this.api(`/races/${raceId}/start`, { method: 'POST' });
            this.loadRaces();
        } catch (error) {
            alert(error.message);
        }
    }
    
    async stopRace(raceId) {
        try {
            await this.api(`/races/${raceId}/stop`, { method: 'POST' });
            this.loadRaces();
        } catch (error) {
            alert(error.message);
        }
    }
    
    // Results
    async loadRaceSelect(elementId) {
        try {
            const races = await this.api('/races');
            const select = document.getElementById(elementId);
            select.innerHTML = '<option value="">Select a Race</option>' +
                races.map(r => `<option value="${r.id}">${r.name}</option>`).join('');
        } catch (error) {
            console.error('Failed to load races:', error);
        }
    }
    
    async loadResults(raceId) {
        if (!raceId) {
            document.querySelector('#results-table tbody').innerHTML = '';
            return;
        }
        
        try {
            const data = await this.api(`/races/${raceId}/results`);
            const tbody = document.querySelector('#results-table tbody');
            
            tbody.innerHTML = data.results.map((result, index) => `
                <tr>
                    <td>${index + 1}</td>
                    <td>${result.entry.runner_name}</td>
                    <td>${result.entry.runner_guid_short}</td>
                    <td>${result.lap_count}</td>
                    <td>${this.formatTime(result.total_time)}</td>
                    <td>${this.formatTime(result.best_lap_time)}</td>
                </tr>
            `).join('');
        } catch (error) {
            console.error('Failed to load results:', error);
        }
    }
    
    // Entries
    async loadEntries(raceId) {
        if (!raceId) {
            document.getElementById('entries-list').innerHTML = '';
            return;
        }
        
        try {
            const entries = await this.api(`/entries?race_id=${raceId}`);
            const container = document.getElementById('entries-list');
            
            container.innerHTML = entries.map(entry => `
                <div class="card">
                    <h3>${entry.runner_name}</h3>
                    <p><strong>ID:</strong> ${entry.runner_guid_short}</p>
                    <p><strong>Sex:</strong> ${entry.sex || 'N/A'}</p>
                    <p><strong>DOB:</strong> ${entry.date_of_birth ? new Date(entry.date_of_birth).toLocaleDateString() : 'N/A'}</p>
                    <p><strong>Bib:</strong> ${entry.bib_number || 'N/A'}</p>
                    <div class="card-actions">
                        <button class="btn btn-secondary btn-small" onclick="app.downloadQR('${raceId}', '${entry.id}')">Download QR</button>
                    </div>
                </div>
            `).join('');
        } catch (error) {
            console.error('Failed to load entries:', error);
        }
    }
    
    showNewEntryModal() {
        const raceId = document.getElementById('entries-race-select').value;
        if (!raceId) {
            alert('Please select a race first');
            return;
        }
        
        const modal = document.getElementById('modal-content');
        modal.innerHTML = `
            <h2>Add Race Entry</h2>
            <form id="new-entry-form">
                <div class="form-group">
                    <label>Runner Name</label>
                    <input type="text" name="runner_name" required>
                </div>
                <div class="form-group">
                    <label>Sex</label>
                    <select name="sex">
                        <option value="">Select...</option>
                        <option value="M">Male</option>
                        <option value="F">Female</option>
                        <option value="O">Other</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Date of Birth</label>
                    <input type="date" name="date_of_birth">
                </div>
                <div class="form-group">
                    <label>Bib Number</label>
                    <input type="number" name="bib_number">
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn btn-secondary" onclick="app.closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Add Entry</button>
                </div>
            </form>
        `;
        
        document.getElementById('new-entry-form').addEventListener('submit', (e) => this.handleNewEntry(e, raceId));
        document.getElementById('modal-overlay').style.display = 'flex';
    }
    
    async handleNewEntry(e, raceId) {
        e.preventDefault();
        const formData = new FormData(e.target);
        const data = {
            race_id: raceId,
            user_id: this.user.id,
            runner_name: formData.get('runner_name'),
            sex: formData.get('sex') || null,
            date_of_birth: formData.get('date_of_birth') ? new Date(formData.get('date_of_birth')).toISOString() : null,
            bib_number: formData.get('bib_number') ? parseInt(formData.get('bib_number')) : null,
        };
        
        try {
            await this.api('/entries', {
                method: 'POST',
                body: JSON.stringify(data),
            });
            this.closeModal();
            this.loadEntries(raceId);
        } catch (error) {
            alert(error.message);
        }
    }
    
    // WebSocket
    connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/api/scans/ws/general`;
        
        this.ws = new WebSocket(wsUrl);
        
        this.ws.onopen = () => {
            console.log('WebSocket connected');
            // Start auto-sync
            this.syncInterval = setInterval(() => this.syncData(), 5000);
        };
        
        this.ws.onmessage = (event) => {
            const message = JSON.parse(event.data);
            if (message.type === 'scan') {
                this.handleScanAnnouncement(message.data);
            }
        };
        
        this.ws.onclose = () => {
            console.log('WebSocket disconnected');
            // Reconnect after 5 seconds
            setTimeout(() => this.connectWebSocket(), 5000);
        };
    }
    
    handleScanAnnouncement(data) {
        // Speak the announcement
        this.speakAnnouncement(data);
        
        // Show in UI
        const container = document.getElementById('live-announcements');
        const announcement = document.createElement('div');
        announcement.className = 'announcement';
        announcement.innerHTML = `
            <span><strong>${data.runner_name}</strong> (${data.runner_id}) - Lap ${data.lap_number}</span>
            <span class="announcement-time">${data.race_time} (Lap: ${data.lap_time})</span>
        `;
        container.insertBefore(announcement, container.firstChild);
        
        // Keep only last 10 announcements
        while (container.children.length > 10) {
            container.removeChild(container.lastChild);
        }
        
        // Refresh results if viewing
        const selectedRace = document.getElementById('results-race-select').value;
        if (selectedRace) {
            this.loadResults(selectedRace);
        }
    }
    
    speakAnnouncement(data) {
        if ('speechSynthesis' in window) {
            const text = `Runner ${data.runner_name}, ID ${data.runner_id}, Lap ${data.lap_number}, Time ${data.race_time}, Lap Time ${data.lap_time}`;
            const utterance = new SpeechSynthesisUtterance(text);
            speechSynthesis.speak(utterance);
        }
    }
    
    async syncData() {
        // Auto-sync logic here
        // This would sync local scans to server and get latest data
    }
    
    // QR Code
    async generateServerQR() {
        try {
            // Generate a new race for demo or use existing
            const races = await this.api('/races');
            if (races.length === 0) {
                alert('Please create a race first');
                return;
            }
            
            const raceId = races[0].id;
            const qrData = await this.api(`/races/${raceId}/qr-join`);
            
            // For now, just show the data
            document.getElementById('server-qr-container').innerHTML = `
                <p><strong>Race:</strong> ${qrData.race_name}</p>
                <p><strong>Shared Secret:</strong> ${qrData.shared_secret.substring(0, 20)}...</p>
                <p><strong>Sync Interval:</strong> ${qrData.sync_interval}s</p>
                <p class="text-muted">Scan this QR code with the mobile app to connect</p>
            `;
        } catch (error) {
            alert(error.message);
        }
    }
    
    // Utilities
    closeModal() {
        document.getElementById('modal-overlay').style.display = 'none';
    }
    
    formatTime(seconds) {
        if (seconds === null || seconds === undefined) return '--:--';
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        const ms = Math.floor((seconds % 1) * 100);
        return `${mins}:${secs.toString().padStart(2, '0')}.${ms.toString().padStart(2, '0')}`;
    }
}

// Initialize app
const app = new RaceTimerApp();
