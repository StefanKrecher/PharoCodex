Class {
	#name : #OpenAICodexMemoryTransport,
	#superclass : #OpenAICodexTransport,
	#instVars : [
		'incomingMessages',
		'outgoingMessages',
		'started'
	],
	#category : #'OpenAI-Codex-Transport',
	#package : #'OpenAI-Codex'
}

{ #category : #initialization }
OpenAICodexMemoryTransport >> initialize [
	super initialize.
	incomingMessages := OrderedCollection new.
	outgoingMessages := OrderedCollection new.
	started := false
]

{ #category : #testing }
OpenAICodexMemoryTransport >> isStarted [
	^ started
]

{ #category : #messaging }
OpenAICodexMemoryTransport >> nextMessage [
	incomingMessages ifEmpty: [ ^ nil ].
	^ incomingMessages removeFirst
]

{ #category : #accessing }
OpenAICodexMemoryTransport >> outgoingMessages [
	^ outgoingMessages copy
]

{ #category : #messaging }
OpenAICodexMemoryTransport >> queueIncomingMessage: aDictionary [
	incomingMessages add: aDictionary
]

{ #category : #messaging }
OpenAICodexMemoryTransport >> queueIncomingMessages: aCollection [
	aCollection do: [ :each | self queueIncomingMessage: each ]
]

{ #category : #messaging }
OpenAICodexMemoryTransport >> sendMessage: aDictionary [
	outgoingMessages add: aDictionary
]

{ #category : #lifecycle }
OpenAICodexMemoryTransport >> start [
	started := true
]

{ #category : #lifecycle }
OpenAICodexMemoryTransport >> stop [
	started := false
]
