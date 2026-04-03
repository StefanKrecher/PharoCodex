Class {
	#name : 'OpenAICodexFakeWebSocketConnectionFactory',
	#superclass : 'OpenAICodexWebSocketConnectionFactory',
	#instVars : [
		'connection',
		'lastOpenedUrl'
	],
	#category : 'OpenAI-Codex-Tests',
	#package : 'OpenAI-Codex-Tests'
}

{ #category : 'accessing' }
OpenAICodexFakeWebSocketConnectionFactory >> connection [
	^ connection
]

{ #category : 'initialization' }
OpenAICodexFakeWebSocketConnectionFactory >> initialize [
	super initialize.
	connection := OpenAICodexFakeWebSocketConnection new
]

{ #category : 'accessing' }
OpenAICodexFakeWebSocketConnectionFactory >> lastOpenedUrl [
	^ lastOpenedUrl
]

{ #category : 'opening' }
OpenAICodexFakeWebSocketConnectionFactory >> openUrl: aString [
	lastOpenedUrl := aString.
	^ connection
]
