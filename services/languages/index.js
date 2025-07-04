const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'languages', timestamp: new Date() });
});

// Languages endpoint
app.get('/v1/languages', (req, res) => {
    res.json([
        { code: 'swh', name: 'Swahili', native_name: 'Kiswahili' },
        { code: 'yor', name: 'Yoruba', native_name: 'Yorùbá' },
        { code: 'ibo', name: 'Igbo', native_name: 'Igbo' },
        { code: 'hau', name: 'Hausa', native_name: 'Hausa' },
        { code: 'amh', name: 'Amharic', native_name: 'አማርኛ' }
    ]);
});

app.listen(PORT, () => {
    console.log(`Languages service running on port ${PORT}`);
});

// Add root endpoint
app.get('/', (req, res) => {
    res.json({
        message: "🌍 Native Languages API",
        version: "1.0.0",
        documentation: "https://docs.nativetongueapis.com",
        endpoints: {
            languages: "/v1/languages",
            audio: "/v1/audio/{language}/{word}",
            health: "/health"
        },
        authentication: "X-API-Key header required for all endpoints except /health",
        supported_languages: [
            { code: "swh", name: "Swahili", speakers: "150M" },
            { code: "yor", name: "Yoruba", speakers: "45M" },
            { code: "ibo", name: "Igbo", speakers: "24M" },
            { code: "hau", name: "Hausa", speakers: "70M" },
            { code: "amh", name: "Amharic", speakers: "32M" }
        ],
        contact: "support@nativetongueapis.com"
    });
});
