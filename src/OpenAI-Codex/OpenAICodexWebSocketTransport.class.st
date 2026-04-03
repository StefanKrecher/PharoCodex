Class {
	#name : 'OpenAICodexWebSocketTransport',
	#superclass : 'OpenAICodexTransport',
	#instVars : [
		'url',
		'serializer',
		'connectionFactory',
		'connection',
		'incomingMessages',
		'queueLock',
		'readerProcess',
		'started',
		'lastReadError'
	],
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'instance creation' }
OpenAICodexWebSocketTransport class >> toUrl: aString [
	^ self new
		url: aString;
		yourself
]

{ #category : 'accessing' }
OpenAICodexWebSocketTransport >> connectionFactory: aFactory [
	connectionFactory := aFactory
]

{ #category : 'initialization' }
OpenAICodexWebSocketTransport >> initialize [
	super initialize.
	serializer := OpenAICodexMessageSerializer new.
	connectionFactory := OpenAICodexWebSocketConnectionFactory current.
	incomingMessages := OrderedCollection new.
	queueLock := Semaphore forMutualExclusion.
	started := false
]

{ #category : 'testing' }
OpenAICodexWebSocketTransport >> isStarted [
	^ started and: [ connection notNil and: [ connection isConnected ] ]
]

{ #category : 'accessing' }
OpenAICodexWebSocketTransport >> lastReadError [
	^ lastReadError
]

{ #category : 'messaging' }
OpenAICodexWebSocketTransport >> nextMessage [
	| message |
	message := nil.
	queueLock critical: [
		incomingMessages ifNotEmpty: [
			message := incomingMessages removeFirst ] ].
	^ message
]

{ #category : 'private' }
OpenAICodexWebSocketTransport >> queueIncomingMessage: aDictionary [
	queueLock critical: [
		incomingMessages add: aDictionary ]
]

{ #category : 'private' }
OpenAICodexWebSocketTransport >> readLoop [
	| messageText |
	[
		[started] whileTrue: [
			messageText := connection readMessage.
			messageText ifNil: [
				(Delay forMilliseconds: 10) wait
			] ifNotNil: [
				self queueIncomingMessage: (serializer deserializeMessage: messageText) ] ] ]
		on: Error
		do: [ :ex |
			lastReadError := ex.
			started := false ]
]

{ #category : 'messaging' }
OpenAICodexWebSocketTransport >> sendMessage: aDictionary [
	connection ifNil: [ OpenAICodexTransportError signal: 'Cannot send before transport start' ].
	connection sendMessage: (serializer serializeMessage: aDictionary)
]

{ #category : 'lifecycle' }
OpenAICodexWebSocketTransport >> start [
	connection ifNotNil: [ ^ self ].
	url ifNil: [ OpenAICodexTransportError signal: 'A WebSocket URL must be configured' ].
	connection := connectionFactory openUrl: url.
	started := true.
	readerProcess := [ self readLoop ] forkNamed: 'OpenAICodex WebSocket Reader'.
	^ self
]

{ #category : 'lifecycle' }
OpenAICodexWebSocketTransport >> stop [
	started := false.
	connection ifNotNil: [
		connection close.
		connection := nil ].
	readerProcess ifNotNil: [
		readerProcess terminate.
		readerProcess := nil ]
]

{ #category : 'accessing' }
OpenAICodexWebSocketTransport >> url [
	^ url
]

{ #category : 'accessing' }
OpenAICodexWebSocketTransport >> url: aString [
	url := aString
]
