Class {
	#name : 'OpenAICodexZnWebSocketConnectionFactory',
	#superclass : 'OpenAICodexWebSocketConnectionFactory',
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'opening' }
OpenAICodexZnWebSocketConnectionFactory >> openUrl: aString [
	^ OpenAICodexZnWebSocketConnection on: (ZnWebSocket to: aString)
]
