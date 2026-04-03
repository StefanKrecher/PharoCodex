Class {
	#name : #OpenAICodexWebSocketConnection,
	#superclass : #Object,
	#category : #'OpenAI-Codex-Transport-WebSocket',
	#package : #'OpenAI-Codex'
}

{ #category : #lifecycle }
OpenAICodexWebSocketConnection >> close [
	self subclassResponsibility
]

{ #category : #testing }
OpenAICodexWebSocketConnection >> isConnected [
	self subclassResponsibility
]

{ #category : #messaging }
OpenAICodexWebSocketConnection >> readMessage [
	self subclassResponsibility
]

{ #category : #messaging }
OpenAICodexWebSocketConnection >> sendMessage: aString [
	self subclassResponsibility
]
