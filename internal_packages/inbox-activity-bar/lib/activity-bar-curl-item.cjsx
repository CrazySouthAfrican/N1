React = require 'react/addons'

module.exports =
ActivityBarCurlItem = React.createClass
  displayName: 'ActivityBarCurlItem'

  render: ->
    <div className={"item status-code-#{@props.item.statusCode}"}>
      <div className="code">{@props.item.statusCode}</div>
      <a onClick={@_onRunCommand}>Run</a>
      <a onClick={@_onCopyCommand}>Copy</a>
      {@props.item.command}
    </div>

  _onCopyCommand: ->
    clipboard = require('clipboard')
    clipboard.writeText(@props.item.command)

  _onRunCommand: ->
    curlFile = "#{atom.getConfigDirPath()}/curl.command"
    fs = require 'fs-plus'
    if fs.existsSync(curlFile)
      fs.unlinkSync(curlFile)
    fs.writeFileSync(curlFile, @props.item.command)
    fs.chmodSync(curlFile, '777')
    shell = require 'shell'
    shell.openItem(curlFile)