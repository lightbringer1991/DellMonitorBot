_ = require 'lodash'
nconf = require 'nconf'
nodemailer = require 'nodemailer'
Entities = require('html-entities').AllHtmlEntities
entities = new Entities()

columnIndex = {
  bundle: 0,
  condition: 1,
  model: 2,
  warranty: 3,
  color: 4,
  software: 5,
  quantity: 6,
  price: 7
}

getMatchedProducts = ($, trList, logger, { modelRegex }) ->
  matchedProducts = []
  totalColumns = _.keys(columnIndex).length

  _.forEach trList, (tr, index) ->
    tdList = $(tr).find('td').get()
    if tdList.length isnt totalColumns then return logger.error "Invalid data at row #{index}"

    model = entities.decode $(tdList[columnIndex.model]).html().trim()
    if modelRegex.test model
      price = entities.decode $(tdList[columnIndex.price]).html().trim()
      condition = entities.decode $(tdList[columnIndex.condition]).html().trim()

      matchedProducts.push { model, price, condition }
      logger.info "Found matched model #{model}"

  return matchedProducts

#mailOptions = {
#  from: '',
#  to: '',
#  subject: '',
#  text: '',
#  html: ''
#}
sendEmail = (mailOptions, cb) ->
  transporter = nodemailer.createTransport nconf.get 'email'
  transporter.sendMail mailOptions, cb

module.exports = {
  sendEmail
  getMatchedProducts
}
