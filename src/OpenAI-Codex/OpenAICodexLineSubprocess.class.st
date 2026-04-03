Class {
	#name : 'OpenAICodexLineSubprocess',
	#superclass : 'Object',
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'testing' }
OpenAICodexLineSubprocess >> isRunning [
	self subclassResponsibility
]

{ #category : 'messaging' }
OpenAICodexLineSubprocess >> nextLine [
	self subclassResponsibility
]

{ #category : 'messaging' }
OpenAICodexLineSubprocess >> sendLine: aString [
	self subclassResponsibility
]

{ #category : 'lifecycle' }
OpenAICodexLineSubprocess >> stop [
	self subclassResponsibility
]
