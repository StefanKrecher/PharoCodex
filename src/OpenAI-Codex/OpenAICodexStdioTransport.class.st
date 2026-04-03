Class {
	#name : #OpenAICodexStdioTransport,
	#superclass : #OpenAICodexTransport,
	#instVars : [
		'command',
		'arguments',
		'workingDirectory',
		'subprocessFactory',
		'subprocess',
		'serializer'
	],
	#category : #'OpenAI-Codex-Transport',
	#package : #'OpenAI-Codex'
}

{ #category : #'instance creation' }
OpenAICodexStdioTransport class >> command: aString arguments: aCollection [
	^ self new
		command: aString;
		arguments: aCollection;
		yourself
]

{ #category : #accessing }
OpenAICodexStdioTransport >> arguments [
	^ arguments ifNil: [ #() ]
]

{ #category : #accessing }
OpenAICodexStdioTransport >> arguments: aCollection [
	arguments := aCollection asArray
]

{ #category : #accessing }
OpenAICodexStdioTransport >> command [
	^ command ifNil: [ 'codex' ]
]

{ #category : #accessing }
OpenAICodexStdioTransport >> command: aString [
	command := aString
]

{ #category : #initialization }
OpenAICodexStdioTransport >> initialize [
	super initialize.
	serializer := OpenAICodexMessageSerializer new.
	subprocessFactory := OpenAICodexSubprocessFactory current.
	arguments := #( 'app-server' )
]

{ #category : #testing }
OpenAICodexStdioTransport >> isStarted [
	^ subprocess notNil and: [ subprocess isRunning ]
]

{ #category : #messaging }
OpenAICodexStdioTransport >> nextMessage [
	| line |
	subprocess ifNil: [ ^ nil ].
	line := subprocess nextLine.
	line ifNil: [ ^ nil ].
	^ serializer deserializeMessage: line
]

{ #category : #messaging }
OpenAICodexStdioTransport >> sendMessage: aDictionary [
	subprocess ifNil: [ OpenAICodexTransportError signal: 'Cannot send before transport start' ].
	subprocess sendLine: (serializer serializeMessage: aDictionary)
]

{ #category : #lifecycle }
OpenAICodexStdioTransport >> start [
	subprocess ifNotNil: [ ^ self ].
	subprocess := subprocessFactory
		spawnCommand: self command
		arguments: self arguments
		workingDirectory: workingDirectory
]

{ #category : #lifecycle }
OpenAICodexStdioTransport >> stop [
	subprocess ifNil: [ ^ self ].
	subprocess stop.
	subprocess := nil
]

{ #category : #accessing }
OpenAICodexStdioTransport >> subprocessFactory: aFactory [
	subprocessFactory := aFactory
]

{ #category : #accessing }
OpenAICodexStdioTransport >> workingDirectory: aStringOrNil [
	workingDirectory := aStringOrNil
]
