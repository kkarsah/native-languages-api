const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3004;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        service: 'admin',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// Admin endpoints
app.get('/v1/admin/dashboard', (req, res) => {
    res.json({
        platform_status: 'operational',
        total_users: 1250,
        total_api_keys: 89,
        system_health: {
            cpu_usage: 45.2,
            memory_usage: 62.8,
            disk_usage: 34.1
        }
    });
});

app.get('/v1/admin/users', (req, res) => {
    res.json([
        { id: 1, email: 'user1@example.com', tier: 'pro', status: 'active' },
        { id: 2, email: 'user2@example.com', tier: 'free', status: 'active' }
    ]);
});

app.listen(PORT, () => {
    console.log(`Admin service running on port ${PORT}`);
});
