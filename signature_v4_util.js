const aws4  = require('./aws4');
const fs = require('fs');
const args = process.argv.slice(2);

if(args[0] == "get_secret") {
    getSecret();
}

if(args[0] == "parse_secret") {
    parseSecretString();
}

function getSecret() {
    const creds = JSON.parse(args[1]);
    var opts = JSON.parse(args[2]);
    aws4.sign(opts, creds);
    fs.writeFileSync("tempFile", opts.headers['Authorization'] + "\n");
    fs.writeFileSync("tempFile", opts.headers['X-Amz-Date'], {flag: "a"});
}

function parseSecretString() {
    var secret = fs.readFileSync("response.json").toString();
    secret = JSON.parse(secret).SecretString;
    secret = JSON.parse(secret);
    secret = secret[Object.keys(secret)[0]];
    fs.writeFileSync("tempFile", secret);
}
