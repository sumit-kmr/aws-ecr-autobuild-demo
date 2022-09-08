var fs = require('fs')
var path = require('upath')
var Promise = require('bluebird')
fs = Promise.promisifyAll(fs)
var homeDir = require('home-dir')
var utils = require('./utils')

var CREDENTIALS_FILE = path.join('~/', '.anypoint/credentials')

function loadJSONFile (filePath) {
  return fs.readFileAsync(filePath, 'utf8')
    .then(function (data) {
      return JSON.parse(data)
    })
    .catch(
      () => ({/* return empty object */})
    )
}

function loadProfile (filePath) {
  return loadJSONFile(filePath)
    .then(function (data) {
      return data[process.env.ANYPOINT_PROFILE || 'default'] || {}
    })
}

/* Loads user credentials */
function load (argv) {
  return loadProfile(CREDENTIALS_FILE)
    .then(function (fileData) {
      var opts = {}
      opts.bearer = argv.bearer || process.env.ANYPOINT_BEARER
      opts.environment = argv.environment || process.env.ANYPOINT_ENV || fileData.environment
      opts.organization = argv.organization || process.env.ANYPOINT_ORG || fileData.organization
      opts.username = argv.username || process.env.ANYPOINT_USERNAME || fileData.username
      opts.password = argv.password || process.env.ANYPOINT_PASSWORD || fileData.password
      opts.client_id = argv.client_id || process.env.ANYPOINT_CLIENT_ID || fileData.client_id
      opts.client_secret = argv.client_secret || process.env.ANYPOINT_CLIENT_SECRET || fileData.client_secret
      opts.host = argv.host || process.env.ANYPOINT_HOST || fileData.host || utils.DEFAULT_HOST
      opts.interactive = true
      if (opts.username && opts.username.indexOf('@') > -1) {
        var parts = opts.username.split('@')
        opts.username = parts[0]
        opts.environment = parts[1]
      }
      opts.collectMetrics = argv.collectMetrics || process.env.COLLECT_METRICS || fileData.collectMetrics || true
      opts.collectMetrics = String(opts.collectMetrics) === "true"
      return opts
    })
}

/* Loads global output defaults */
function loadOpts (argv) {
  argv = argv || {}
  var filePath = path.join(homeDir(), '.anypoint/defaults')
  return loadProfile(filePath)
    .then(function (fileData) {
      var opts = {}
      opts.output = argv.output || process.env.ANYPOINT_OUTPUT || fileData.output
      opts.fields = argv.fields || process.env.ANYPOINT_FIELDS || fileData.fields
      return opts
    })
}

module.exports = {
  load: load,
  loadOpts: loadOpts,
  loadJSONFile: loadJSONFile,
  CREDENTIALS_FILE: CREDENTIALS_FILE
}
