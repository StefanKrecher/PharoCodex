Class {
	#name : #OpenAICodexWebSocketConnectionFactory,
	#superclass : #Object,
	#classVars : [
		'Current'
	],
	#category : #'OpenAI-Codex-Transport-WebSocket',
	#package : #'OpenAI-Codex'
}

{ #category : #accessing }
OpenAICodexWebSocketConnectionFactory class >> current [
	^ Current ifNil: [ Current := OpenAICodexZnWebSocketConnectionFactory new ]
]

{ #category : #accessing }
OpenAICodexWebSocketConnectionFactory class >> current: aFactory [
	Current := aFactory
]

{ #category : #accessing }
OpenAICodexWebSocketConnectionFactory class >> resetCurrent [
	Current := nil
]

{ #category : #opening }
OpenAICodexWebSocketConnectionFactory >> openUrl: aString [
	self subclassResponsibility
]
