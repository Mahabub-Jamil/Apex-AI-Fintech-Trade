import https from 'https';
import fs from 'fs';
import path from 'path';

const envPath = path.resolve('.env');
const envContent = fs.readFileSync(envPath, 'utf-8');
const keyMatch = envContent.match(/GEMINI_API_KEY=(.*)/);

if (!keyMatch || !keyMatch[1]) {
    console.log("No key found in .env");
    process.exit(1);
}

const key = keyMatch[1].trim().replace(/^"|"$/g, '');

const options = {
    hostname: 'generativelanguage.googleapis.com',
    path: `/v1beta/models?key=${key}`,
    method: 'GET',
};

const req = https.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => {
        data += chunk;
    });
    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            if (json.models) {
                fs.writeFileSync('models.json', JSON.stringify(json.models.map(m => m.name), null, 2));
                console.log("Written to models.json");
            } else {
                console.log("Response:", json);
            }
        } catch (e) {
            console.log("Parse error:", e);
            console.log("Raw:", data);
        }
    });
});

req.on('error', (e) => {
    console.error("HTTP Request Error:", e);
});
req.end();
