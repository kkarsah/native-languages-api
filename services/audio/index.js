const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'audio', timestamp: new Date() });
});

app.get('/v1/audio/:lang/:word', (req, res) => {
    const { lang, word } = req.params;
    res.json({ 
        message: `Audio for ${word} in ${lang}`,
        audio_url: `https://cdn.nativetongueapis.com/audio/${lang}/${word}.mp3`
    });
});

app.listen(PORT, () => {
    console.log(`Audio service running on port ${PORT}`);
});
