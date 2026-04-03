Class {
	#name : 'OpenAICodexZnWebSocketConnection',
	#superclass : 'OpenAICodexWebSocketConnection',
	#instVars : [
		'webSocket'
	],
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'instance creation' }
OpenAICodexZnWebSocketConnection class >> on: aZnWebSocket [
	^ self new
		webSocket: aZnWebSocket;
		yourself
]

{ #category : 'lifecycle' }
OpenAICodexZnWebSocketConnection >> close [
	webSocket ifNotNil: [ webSocket close ]
]

{ #category : 'testing' }
OpenAICodexZnWebSocketConnection >> isConnected [
	^ webSocket notNil
]

{ #category : 'messaging' }
OpenAICodexZnWebSocketConnection >> readMessage [
	^ webSocket readMessage
]

{ #category : 'messaging' }
OpenAICodexZnWebSocketConnection >> sendMessage: aString [
	webSocket sendMessage: aString
]

{ #category : 'accessing' }
OpenAICodexZnWebSocketConnection >> webSocket: aZnWebSocket [
	webSocket := aZnWebSocket
]
