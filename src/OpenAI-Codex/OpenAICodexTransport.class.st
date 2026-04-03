Class {
	#name : 'OpenAICodexTransport',
	#superclass : 'Object',
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'testing' }
OpenAICodexTransport >> isStarted [
	self subclassResponsibility
]

{ #category : 'messaging' }
OpenAICodexTransport >> nextMessage [
	self subclassResponsibility
]

{ #category : 'messaging' }
OpenAICodexTransport >> sendMessage: aDictionary [
	self subclassResponsibility
]

{ #category : 'lifecycle' }
OpenAICodexTransport >> start [
	self subclassResponsibility
]

{ #category : 'lifecycle' }
OpenAICodexTransport >> stop [
	self subclassResponsibility
]
