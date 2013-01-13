goog.provide 'honeybadger'

goog.require 'notice'

class Honeybadger
  @version: '0.0.1'

  @default_configuration:
    api_key: null
    host: 'api.honeybadger.io'
    ssl: true
    project_root: window.location.protocol + '//' + window.location.host
    environment: 'production'
    component: null
    action: null

  # TODO: Test partial override
  @configure: (options = {}) ->
    for k,v of options
      @configuration[k] = v
    this

  @configuration:
    reset: =>
      @configure(@default_configuration)

  @configuration.reset()

  @context: {}

  @resetContext: (options = {}) ->
    @context = options
    this

  @setContext: (options = {}) ->
    for k,v of options
      @context[k] = v
    this

  # TODO: Test setting options from notify
  @notify: (error, options = {}) ->
    options['error'] = error if error
    notice = new Notice(options)
    @_sendRequest(notice.toJSON())

  # http://www.w3.org/TR/cors/
  @_sendRequest: (data) ->
    url = 'http' + ((@configuration.ssl && 's') || '' ) + '://' + @configuration.host + '/v1/notices'
    @_crossDomainPost(url, data)

  # http://www.markandey.com/2011/10/design-of-cross-domain-post-api-in.html
  @_crossDomainPost = (url, payload) ->
    iframe = document.createElement('iframe')
    uniqueNameOfFrame = '_hb_' + (new Date).getTime()
    document.body.appendChild iframe
    iframe.style.display = 'none'
    iframe.contentWindow.name = uniqueNameOfFrame

    form = document.createElement('form')
    form.target = uniqueNameOfFrame
    form.action = url
    form.method = 'POST'

    input = document.createElement('input')
    input.type = 'hidden'
    input.name = "payload"
    input.value = payload
    form.appendChild input
    document.body.appendChild form

    input = document.createElement('input')
    input.type = 'hidden'
    input.name = "api_key"
    input.value = @configuration.api_key
    form.appendChild input
    document.body.appendChild form

    form.submit()

TraceKit.report.subscribe (stackInfo) ->
  Honeybadger.notify(null, { stackInfo: stackInfo })

# make sure to export the modules you want to expose,
# otherwise they won't be accessible by clients.
(exports ? this).Honeybadger = Honeybadger
