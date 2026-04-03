Class {
	#name : #OpenAICodexTransport,
	#superclass : #Object,
	#category : #'OpenAI-Codex-Transport',
	#package : #'OpenAI-Codex'
}

{ #category : #lifecycle }
OpenAICodexTransport >> start [
	self subclassResponsibility
]

{ #category : #lifecycle }
OpenAICodexTransport >> stop [
	self subclassResponsibility
]

{ #category : #testing }
OpenAICodexTransport >> isStarted [
	self subclassResponsibility
]

{ #category : #messaging }
OpenAICodexTransport >> nextMessage [
	self subclassResponsibility
]

{ #category : #messaging }
OpenAICodexTransport >> sendMessage: aDictionary [
	self subclassResponsibility
]
