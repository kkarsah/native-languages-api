const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3005;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        service: 'webhooks',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// Webhook endpoints
app.post('/v1/webhooks/subscribe', (req, res) => {
    res.json({
        message: 'Webhook subscription created',
        webhook_id: 'wh_' + Math.random().toString(36).substr(2, 9),
        url: req.body.url,
        events: req.body.events || ['usage.exceeded', 'payment.failed']
    });
});

app.get('/v1/webhooks', (req, res) => {
    res.json([
        { id: 'wh_123', url: 'https://example.com/webhook', events: ['usage.exceeded'] },
        { id: 'wh_456', url: 'https://another.com/hook', events: ['payment.failed'] }
    ]);
});

app.listen(PORT, () => {
    console.log(`Webhooks service running on port ${PORT}`);
});
