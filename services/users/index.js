const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        service: 'users',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// Users endpoints
app.get('/v1/users', (req, res) => {
    res.json({ message: 'Users service operational' });
});

app.post('/v1/auth/login', (req, res) => {
    res.json({ 
        message: 'Login endpoint',
        token: 'demo-jwt-token'
    });
});

app.post('/v1/auth/register', (req, res) => {
    res.json({ 
        message: 'Registration endpoint',
        user_id: 'demo-user-id'
    });
});

app.listen(PORT, () => {
    console.log(`Users service running on port ${PORT}`);
});
