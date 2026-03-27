const fs = require('fs');

const id = process.env.SPOTIFY_CLIENT_ID || '';
const secret = process.env.SPOTIFY_CLIENT_SECRET || '';
const refresh = process.env.SPOTIFY_REFRESH_TOKEN || '';

fs.writeFileSync('config.js',
  `var SPOTIFY_CLIENT_ID='${id}';\n` +
  `var SPOTIFY_CLIENT_SECRET='${secret}';\n` +
  `var SPOTIFY_REFRESH_TOKEN='${refresh}';\n`
);

console.log('config.js written' + (id ? ' (credentials set)' : ' (no credentials — setup UI will show)'));
