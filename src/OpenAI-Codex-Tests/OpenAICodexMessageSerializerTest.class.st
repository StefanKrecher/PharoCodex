Class {
	#name : 'OpenAICodexMessageSerializerTest',
	#superclass : 'TestCase',
	#instVars : [
		'serializer'
	],
	#category : 'OpenAI-Codex-Tests',
	#package : 'OpenAI-Codex-Tests'
}

{ #category : 'running' }
OpenAICodexMessageSerializerTest >> setUp [
	super setUp.
	serializer := OpenAICodexMessageSerializer new
]

{ #category : 'tests' }
OpenAICodexMessageSerializerTest >> testRoundTripDictionaryMessage [
	| message decoded |
	message := Dictionary new
		at: 'id' put: 7;
		at: 'method' put: 'thread/start';
		at: 'params' put: (Dictionary new at: 'cwd' put: 'C:/tmp'; yourself);
		yourself.
	decoded := serializer deserializeMessage: (serializer serializeMessage: message).
	self assert: (decoded at: 'id') equals: 7.
	self assert: (decoded at: 'method') equals: 'thread/start'
]
