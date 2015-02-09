Reflux = require 'reflux'
Actions = require './onboarding-actions'
{EdgehillAPI} = require 'inbox-exports'
ipc = require 'ipc'

module.exports =
OnboardingStore = Reflux.createStore
  init: ->
    @_error = ''
    @_page = atom.getLoadSettings().page || 'welcome'
    @_pageStack = [@_page]

    defaultEnv = if atom.inDevMode() then 'staging' else 'production'
    atom.config.set('inbox.env', defaultEnv) unless atom.config.get('inbox.env')

    @listenTo Actions.setEnvironment, @_onSetEnvironment
    @listenTo Actions.moveToPreviousPage, @_onMoveToPreviousPage
    @listenTo Actions.moveToPage, @_onMoveToPage
    @listenTo Actions.startConnect, @_onStartConnect
    @listenTo Actions.finishedConnect, @_onFinishedConnect
    @listenTo Actions.createAccount, @_onCreateAccount
    @listenTo Actions.signIn, @_onSignIn

  page: ->
    @_page

  error: ->
    @_error

  environment: ->
    atom.config.get('inbox.env')

  connectType: ->
    @_connectType

  _onMoveToPreviousPage: ->
    current = @_pageStack.pop()
    prev = @_pageStack.pop()
    @_onMoveToPage(prev)

  _onMoveToPage: (page) ->
    @_error = null
    @_pageStack.push(page)
    @_page = page
    @trigger()

  _onSignIn: (fields) ->
    @_error = null
    @trigger()

    EdgehillAPI.signIn(fields)
    .then (user) =>
      if atom.config.get('inbox.token')
        @_onMoveToPage('add-account-success')
        setTimeout ->
          # Important: This delay is actually necessary, because
          # atom.config changes are not persisted instantly.
          ipc.send('onboarding-complete')
          atom.close()
        , 2500
      else
        @_onStartConnect('inbox')
    .catch (err) =>
      @_error = err
      @trigger()

  _onCreateAccount: (fields) ->
    @_error = null
    @trigger()

    EdgehillAPI.createAccount(fields)
    .then =>
      @_onStartConnect('inbox')
    .catch (err) =>
      @_error = err
      @trigger()

  _onStartConnect: (service) ->
    @_connectType = service
    @_onMoveToPage('add-account-auth')

  _onFinishedConnect: (token) ->
    EdgehillAPI.addTokens([token])
    @_onMoveToPage('add-account-success')

    setTimeout ->
      ipc.send('onboarding-complete')
      atom.close()
    , 2500

  _onSetEnvironment: (env) ->
    throw new Error("Environment #{env} is not allowed") unless env in ['development', 'staging', 'production']
    atom.config.set('inbox.env', env)
    @trigger()