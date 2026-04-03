Class {
	#name : 'OpenAICodexSessionTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'transport'
	],
	#category : 'OpenAI-Codex-Tests',
	#package : 'OpenAI-Codex-Tests'
}

{ #category : 'running' }
OpenAICodexSessionTest >> setUp [
	super setUp.
	transport := OpenAICodexMemoryTransport new.
	session := OpenAICodexSession onTransport: transport.
	session start
]

{ #category : 'running' }
OpenAICodexSessionTest >> tearDown [
	session stop.
	super tearDown
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testApprovalHandlerRepliesToServerRequest [
	transport queueIncomingMessage: (
		Dictionary new
			at: 'id' put: 99;
			at: 'method' put: 'item/commandExecution/requestApproval';
			at: 'params' put: (Dictionary new at: 'threadId' put: 'thr_1'; yourself);
			yourself).
	session onCommandApprovalDo: [ :request | OpenAICodexApprovalDecision accept ].
	session pumpIncomingMessages.
	self assert: transport outgoingMessages size equals: 1.
	self assert: ((transport outgoingMessages first) at: 'result') equals: 'accept'
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testInitializeSendsInitializedNotification [
	transport queueIncomingMessage: (
		Dictionary new
			at: 'id' put: 1;
			at: 'result' put: (Dictionary new at: 'sessionId' put: 'sess_1'; yourself);
			yourself).
	session initializeClientNamed: 'pharo_codex' title: 'Pharo Codex' version: '0.1.0'.
	self assert: transport outgoingMessages size equals: 2.
	self assert: ((transport outgoingMessages first) at: 'method') equals: 'initialize'.
	self assert: ((transport outgoingMessages second) at: 'method') equals: 'initialized'
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testMissingServerRequestHandlerRepliesWithMethodNotFoundError [
	transport queueIncomingMessage: (
		Dictionary new
			at: 'id' put: 99;
			at: 'method' put: 'item/permissions/requestApproval';
			at: 'params' put: Dictionary new;
			yourself).
	session pumpIncomingMessages.
	self assert: transport outgoingMessages size equals: 1.
	self assert: ((transport outgoingMessages first) at: 'id') equals: 99.
	self assert: ((((transport outgoingMessages first) at: 'error') at: 'code')) equals: -32601
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testNotificationIsAnnounced [
	| seen |
	seen := OrderedCollection new.
	session on: OpenAICodexNotificationAnnouncement do: [ :announcement | seen add: announcement method ].
	transport queueIncomingMessage: (
		Dictionary new
			at: 'method' put: 'turn/completed';
			at: 'params' put: Dictionary new;
			yourself).
	session pumpIncomingMessages.
	self assert: seen asArray equals: #( 'turn/completed' )
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testPermissionsApprovalHandlerCanReturnRequestedPermissions [
	transport queueIncomingMessage: (
		Dictionary new
			at: 'id' put: 99;
			at: 'method' put: 'item/permissions/requestApproval';
			at: 'params' put: (Dictionary new
				at: 'permissions' put: (Dictionary new at: 'network' put: Dictionary new; yourself);
				yourself);
			yourself).
	session onPermissionsApprovalDo: [ :request |
		Dictionary new
			at: 'permissions' put: ((request at: 'params') at: 'permissions');
			at: 'scope' put: 'turn';
			yourself ].
	session pumpIncomingMessages.
	self assert: transport outgoingMessages size equals: 1.
	self assert: ((((transport outgoingMessages first) at: 'result') at: 'scope')) equals: 'turn'
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testReadThreadWithTurnsUsesExpectedMethod [
	transport queueIncomingMessage: (
		Dictionary new
			at: 'id' put: 1;
			at: 'result' put: (Dictionary new at: 'thread' put: Dictionary new; yourself);
			yourself).
	session readThread: 'thr_123' includeTurns: true.
	self assert: ((transport outgoingMessages first) at: 'method') equals: 'thread/read'.
	self assert: (((transport outgoingMessages first) at: 'params') at: 'threadId') equals: 'thr_123'.
	self assert: (((transport outgoingMessages first) at: 'params') at: 'includeTurns') equals: true
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testStartTextTurnBuildsTextInputPayload [
	transport queueIncomingMessage: (
		Dictionary new
			at: 'id' put: 1;
			at: 'result' put: (Dictionary new at: 'turn' put: Dictionary new; yourself);
			yourself).
	session startTextTurnInThread: 'thr_123' text: 'hello'.
	self assert: ((transport outgoingMessages first) at: 'method') equals: 'turn/start'.
	self assert: (((transport outgoingMessages first) at: 'params') at: 'threadId') equals: 'thr_123'.
	self assert: ((((transport outgoingMessages first) at: 'params') at: 'input') first at: 'type') equals: 'text'.
	self assert: ((((transport outgoingMessages first) at: 'params') at: 'input') first at: 'text') equals: 'hello'
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testStartThreadReturnsResultPayload [
	transport queueIncomingMessage: (
		Dictionary new
			at: 'id' put: 1;
			at: 'result' put: (Dictionary new at: 'thread' put: (Dictionary new at: 'id' put: 'thr_123'; yourself); yourself);
			yourself).
	self assert: (((session startThread) at: 'thread') at: 'id') equals: 'thr_123'
]

{ #category : 'tests' }
OpenAICodexSessionTest >> testStatusListUsesExpectedMethod [
	transport queueIncomingMessage: (
		Dictionary new
			at: 'id' put: 1;
			at: 'result' put: Dictionary new;
			yourself).
	session listMcpServerStatus.
	self assert: ((transport outgoingMessages first) at: 'method') equals: 'mcpServerStatus/list'
]
