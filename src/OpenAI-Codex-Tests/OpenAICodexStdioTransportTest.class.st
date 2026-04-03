Class {
	#name : 'OpenAICodexStdioTransportTest',
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
OpenAICodexStdioTransportTest >> setUp [
	super setUp.
	factory := OpenAICodexFakeSubprocessFactory new.
	transport := OpenAICodexStdioTransport command: 'codex' arguments: #( 'app-server' ).
	transport subprocessFactory: factory.
	serializer := OpenAICodexMessageSerializer new
]

{ #category : 'tests' }
OpenAICodexStdioTransportTest >> testReadsMessagesFromSubprocessLineProtocol [
	| decoded |
	factory subprocess queueIncomingLine: '{"method":"thread/started","params":{"threadId":"thr_1"}}'.
	transport start.
	decoded := transport nextMessage.
	self assert: (decoded at: 'method') equals: 'thread/started'
]

{ #category : 'tests' }
OpenAICodexStdioTransportTest >> testStartUsesConfiguredFactory [
	transport workingDirectory: 'C:/workspace'.
	transport start.
	self assert: factory lastSpawnCommand equals: 'codex'.
	self assert: factory lastSpawnArguments equals: #( 'app-server' ).
	self assert: factory lastSpawnWorkingDirectory equals: 'C:/workspace'
]

{ #category : 'tests' }
OpenAICodexStdioTransportTest >> testWriteSerializesToOneJsonLine [
	transport start.
	transport sendMessage: (
		Dictionary new
			at: 'id' put: 1;
			at: 'method' put: 'initialize';
			at: 'params' put: Dictionary new;
			yourself).
	self assert: factory subprocess outgoingLines size equals: 1.
	self assert: ((serializer deserializeMessage: factory subprocess outgoingLines first) at: 'method') equals: 'initialize'
]
