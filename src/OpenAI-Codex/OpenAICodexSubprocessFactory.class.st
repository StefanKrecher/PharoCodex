Class {
	#name : 'OpenAICodexSubprocessFactory',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'accessing' }
OpenAICodexSubprocessFactory class >> current [
	^ Current ifNil: [ Current := OpenAICodexNullSubprocessFactory new ]
]

{ #category : 'accessing' }
OpenAICodexSubprocessFactory class >> current: aFactory [
	Current := aFactory
]

{ #category : 'accessing' }
OpenAICodexSubprocessFactory class >> resetCurrent [
	Current := nil
]

{ #category : 'spawning' }
OpenAICodexSubprocessFactory >> spawnCommand: aCommand arguments: arguments workingDirectory: aPathOrNil [
	self subclassResponsibility
]
