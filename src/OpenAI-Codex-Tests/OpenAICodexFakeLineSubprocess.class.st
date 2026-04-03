Class {
	#name : #OpenAICodexFakeLineSubprocess,
	#superclass : #OpenAICodexLineSubprocess,
	#instVars : [
		'incomingLines',
		'outgoingLines',
		'running'
	],
	#category : #'OpenAI-Codex-Tests-Support',
	#package : #'OpenAI-Codex-Tests'
}

{ #category : #initialization }
OpenAICodexFakeLineSubprocess >> initialize [
	super initialize.
	incomingLines := OrderedCollection new.
	outgoingLines := OrderedCollection new.
	running := true
]

{ #category : #testing }
OpenAICodexFakeLineSubprocess >> isRunning [
	^ running
]

{ #category : #messaging }
OpenAICodexFakeLineSubprocess >> nextLine [
	incomingLines ifEmpty: [ ^ nil ].
	^ incomingLines removeFirst
]

{ #category : #accessing }
OpenAICodexFakeLineSubprocess >> outgoingLines [
	^ outgoingLines copy
]

{ #category : #messaging }
OpenAICodexFakeLineSubprocess >> queueIncomingLine: aString [
	incomingLines add: aString
]

{ #category : #messaging }
OpenAICodexFakeLineSubprocess >> sendLine: aString [
	outgoingLines add: aString
]

{ #category : #lifecycle }
OpenAICodexFakeLineSubprocess >> stop [
	running := false
]
