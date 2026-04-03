Class {
	#name : 'OpenAICodexFakeWebSocketConnection',
	#superclass : 'OpenAICodexWebSocketConnection',
	#instVars : [
		'incomingMessages',
		'outgoingMessages',
		'connected'
	],
	#category : 'OpenAI-Codex-Tests',
	#package : 'OpenAI-Codex-Tests'
}

{ #category : 'lifecycle' }
OpenAICodexFakeWebSocketConnection >> close [
	connected := false
]

{ #category : 'initialization' }
OpenAICodexFakeWebSocketConnection >> initialize [
	super initialize.
	incomingMessages := OrderedCollection new.
	outgoingMessages := OrderedCollection new.
	connected := true
]

{ #category : 'testing' }
OpenAICodexFakeWebSocketConnection >> isConnected [
	^ connected
]

{ #category : 'messaging' }
OpenAICodexFakeWebSocketConnection >> nextIncomingMessagePut: aString [
	incomingMessages add: aString
]

{ #category : 'accessing' }
OpenAICodexFakeWebSocketConnection >> outgoingMessages [
	^ outgoingMessages copy
]

{ #category : 'messaging' }
OpenAICodexFakeWebSocketConnection >> readMessage [
	incomingMessages ifEmpty: [ ^ nil ].
	^ incomingMessages removeFirst
]

{ #category : 'messaging' }
OpenAICodexFakeWebSocketConnection >> sendMessage: aString [
	outgoingMessages add: aString
]
