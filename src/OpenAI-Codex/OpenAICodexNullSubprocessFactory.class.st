Class {
	#name : 'OpenAICodexNullSubprocessFactory',
	#superclass : 'OpenAICodexSubprocessFactory',
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'spawning' }
OpenAICodexNullSubprocessFactory >> spawnCommand: aCommand arguments: arguments workingDirectory: aPathOrNil [
	OpenAICodexTransportError signal: 'No subprocess factory configured for OpenAI-Codex stdio transport'
]
