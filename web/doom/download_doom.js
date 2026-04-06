const https = require('https');
const fs = require('fs');
const path = require('path');

const url = 'https://cdn.dos.zone/custom/dos/doom.jsdos';
const output = 'd:\\Project\\portofolio\\web\\doom\\doom.jsdos';

function download(url, filePath) {
    https.get(url, (res) => {
        if (res.statusCode === 301 || res.statusCode === 302) {
            console.log('Redirecting to ' + res.headers.location);
            return download(res.headers.location, filePath);
        }

        console.log('Status:', res.statusCode);
        console.log('Headers:', res.headers);

        const file = fs.createWriteStream(filePath);
        res.pipe(file);

        file.on('finish', () => {
            file.close();
            console.log('Download complete');
            const stats = fs.statSync(filePath);
            console.log('Final Size:', stats.size);
        });
    }).on('error', (err) => {
        console.error('Error:', err.message);
    });
}

download(url, output);
