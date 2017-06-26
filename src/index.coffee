_ = require 'lodash'
nconf = require 'nconf'
tinyreq = require 'tinyreq'
cheerio = require 'cheerio'
bunyan = require 'bunyan'
utilities = require './utilities'

# setup nconf
nconf.argv()
  .env()
  .file {file: 'config.json'}

# setup logger
logger = bunyan.createLogger
  name: 'mobitor-bot'
  streams: [
    level: 'info',
    stream: process.stdout
  ,
    level: 'error',
    path: 'logs/error.log'
  ,
    level: 'debug'
    path: 'logs/app.log'
  ]

# setup required variables
url = 'http://www1.ap.dell.com/content/topics/segtopic.aspx/products/quickship/au/en/monitors?c=au&l=en&s=dfo'

# configure search
modelRegex = /27"|P27|U27/g;

tinyreq url, (err, body) ->
  if err then return logger.error err

  $ = cheerio.load body
  trList = $('#maincontentcnt form table table table table tbody tr').get()
  # remove the first 3 rows, one is header, 2 are empty
  trList.shift()
  trList.shift()
  trList.shift()

  matchedProducts = utilities.getMatchedProducts $, trList, logger, { modelRegex }

  if matchedProducts.length is 0
    logger.info "No matched found"
    return

  # build and send email
  logger.info "Sending Email to #{_.join(nconf.get('subscriptions'), ', ')}"
  body = ''
  _.forEach matchedProducts, ({model, price, condition}) ->
    body += "Found #{model}(#{condition}) with price #{price}<br />"

  utilities.sendEmail
    from: '"lightbringer-bot" <lightbringer_bot@zoho.com>'
    to: _.join(nconf.get('subscriptions'), ', ')
    subject: 'Matched DELL monitor watcher'
    html: body
  , (err, info) ->
      if error then logger.error "Email sent failed: #{err}"
      else logger.info "Email sent successfully"
