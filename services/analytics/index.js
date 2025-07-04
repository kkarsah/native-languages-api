const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3003;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        service: 'analytics',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// Analytics endpoints
app.get('/v1/analytics/usage', (req, res) => {
    res.json({
        total_requests: 15420,
        requests_today: 1240,
        active_users: 89,
        top_languages: [
            { language: 'swahili', requests: 5600 },
            { language: 'yoruba', requests: 3200 },
            { language: 'igbo', requests: 2800 }
        ]
    });
});

app.get('/v1/analytics/performance', (req, res) => {
    res.json({
        avg_response_time: 145,
        uptime_percentage: 99.9,
        error_rate: 0.1,
        cache_hit_rate: 85.4
    });
});

app.listen(PORT, () => {
    console.log(`Analytics service running on port ${PORT}`);
});
