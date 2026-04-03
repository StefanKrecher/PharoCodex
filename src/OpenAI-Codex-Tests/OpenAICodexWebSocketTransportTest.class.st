Class {
	#name : 'OpenAICodexWebSocketTransportTest',
	#superclass : 'TestCase',
	#instVars : [
		'factory',
		'transport',
		'serializer'
	],
	#category : 'OpenAI-Codex-Tests',
	#package : 'OpenAI-Codex-Tests'
}

{ #category : 'running' }
OpenAICodexWebSocketTransportTest >> setUp [
	super setUp.
	factory := OpenAICodexFakeWebSocketConnectionFactory new.
	transport := OpenAICodexWebSocketTransport toUrl: 'ws://127.0.0.1:8787'.
	transport connectionFactory: factory.
	serializer := OpenAICodexMessageSerializer new
]

{ #category : 'running' }
OpenAICodexWebSocketTransportTest >> tearDown [
	transport stop.
	super tearDown
]

{ #category : 'tests' }
OpenAICodexWebSocketTransportTest >> testReadsIncomingMessageFromConnection [
	| decoded |
	factory connection nextIncomingMessagePut: '{"method":"thread/started","params":{"threadId":"thr_1"}}'.
	transport start.
	(Delay forMilliseconds: 30) wait.
	decoded := transport nextMessage.
	self assert: (decoded at: 'method') equals: 'thread/started'
]

{ #category : 'tests' }
OpenAICodexWebSocketTransportTest >> testSendsSerializedJsonToConnection [
	transport start.
	transport sendMessage: (
		Dictionary new
			at: 'id' put: 1;
			at: 'method' put: 'initialize';
			at: 'params' put: Dictionary new;
			yourself).
	self assert: factory connection outgoingMessages size equals: 1.
	self assert: ((serializer deserializeMessage: factory connection outgoingMessages first) at: 'method') equals: 'initialize'
]

{ #category : 'tests' }
OpenAICodexWebSocketTransportTest >> testStartUsesConfiguredUrl [
	transport start.
	self assert: factory lastOpenedUrl equals: 'ws://127.0.0.1:8787'
]
