Class {
	#name : 'OpenAICodexSession',
	#superclass : 'Object',
	#instVars : [
		'transport',
		'announcer',
		'pendingResponses',
		'serverRequestHandlers',
		'nextRequestId',
		'defaultTimeoutMs',
		'initializationResult'
	],
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'instance creation' }
OpenAICodexSession class >> onTransport: aTransport [
	^ self new
		transport: aTransport;
		yourself
]

{ #category : 'announcements' }
OpenAICodexSession >> announcer [
	^ announcer
]

{ #category : 'accessing' }
OpenAICodexSession >> defaultTimeoutMs [
	^ defaultTimeoutMs
]

{ #category : 'accessing' }
OpenAICodexSession >> defaultTimeoutMs: anInteger [
	defaultTimeoutMs := anInteger
]

{ #category : 'private' }
OpenAICodexSession >> dispatchServerRequest: aDictionary [
	| handler result |
	handler := serverRequestHandlers at: (aDictionary at: 'method') ifAbsent: [ nil ].
	self announcer announce: (OpenAICodexServerRequestAnnouncement message: aDictionary).
	handler ifNil: [
		^ self
			replyToServerRequestId: (aDictionary at: 'id')
			withErrorCode: -32601
			message: ('Unsupported server request method: ', (aDictionary at: 'method'))
			data: nil ].
	result := handler value: aDictionary.
	self replyToServerRequestId: (aDictionary at: 'id') withResult: result
]

{ #category : 'messaging' }
OpenAICodexSession >> executeCommandWithParameters: aDictionary [
	^ self performMethod: 'command/exec' parameters: aDictionary
]

{ #category : 'private' }
OpenAICodexSession >> handleIncomingMessage: aDictionary [
	(aDictionary includesKey: 'method')
		ifTrue: [
			(aDictionary includesKey: 'id')
				ifTrue: [ ^ self dispatchServerRequest: aDictionary ].
			self announcer announce: (OpenAICodexNotificationAnnouncement message: aDictionary).
			^ self ].

	(aDictionary includesKey: 'id') ifFalse: [
		OpenAICodexProtocolError signal: 'Incoming message is neither request, notification, nor response' ].
	pendingResponses at: (aDictionary at: 'id') put: aDictionary.
	self announcer announce: (OpenAICodexResponseAnnouncement message: aDictionary)
]

{ #category : 'accessing' }
OpenAICodexSession >> initializationResult [
	^ initializationResult
]

{ #category : 'initialization' }
OpenAICodexSession >> initialize [
	super initialize.
	announcer := Announcer new.
	pendingResponses := Dictionary new.
	serverRequestHandlers := Dictionary new.
	nextRequestId := 1.
	defaultTimeoutMs := 5000
]

{ #category : 'initialization' }
OpenAICodexSession >> initializeClientNamed: aName title: aTitle version: aVersion [
	^ self initializeClientNamed: aName title: aTitle version: aVersion experimentalApi: false
]

{ #category : 'initialization' }
OpenAICodexSession >> initializeClientNamed: aName title: aTitle version: aVersion experimentalApi: aBoolean [
	| capabilities params |
	capabilities := Dictionary new.
	aBoolean ifTrue: [ capabilities at: 'experimentalApi' put: true ].
	params := Dictionary new
		at: 'clientInfo' put: (
			Dictionary new
				at: 'name' put: aName;
				at: 'title' put: aTitle;
				at: 'version' put: aVersion;
				yourself);
		yourself.
	capabilities isEmpty ifFalse: [ params at: 'capabilities' put: capabilities ].
	initializationResult := self performMethod: 'initialize' parameters: params.
	self sendNotificationMethod: 'initialized' parameters: Dictionary new.
	^ initializationResult
]

{ #category : 'messaging' }
OpenAICodexSession >> interruptTurnWithParameters: aDictionary [
	^ self performMethod: 'turn/interrupt' parameters: aDictionary
]

{ #category : 'testing' }
OpenAICodexSession >> isStarted [
	^ transport notNil and: [ transport isStarted ]
]

{ #category : 'accessing' }
OpenAICodexSession >> listMcpServerStatus [
	^ self performMethod: 'mcpServerStatus/list' parameters: Dictionary new
]

{ #category : 'private' }
OpenAICodexSession >> nextRequestId [
	| requestId |
	requestId := nextRequestId.
	nextRequestId := nextRequestId + 1.
	^ requestId
]

{ #category : 'announcements' }
OpenAICodexSession >> on: anAnnouncementClass do: aBlock [
	^ self announcer
		when: anAnnouncementClass
		do: aBlock
		for: aBlock
]

{ #category : 'approvals' }
OpenAICodexSession >> onCommandApprovalDo: aBlock [
	self whenServerRequest: 'item/commandExecution/requestApproval' do: aBlock
]

{ #category : 'approvals' }
OpenAICodexSession >> onFileChangeApprovalDo: aBlock [
	self whenServerRequest: 'item/fileChange/requestApproval' do: aBlock
]

{ #category : 'approvals' }
OpenAICodexSession >> onMcpElicitationRequestDo: aBlock [
	self whenServerRequest: 'mcpServer/elicitation/request' do: aBlock
]

{ #category : 'approvals' }
OpenAICodexSession >> onPermissionsApprovalDo: aBlock [
	self whenServerRequest: 'item/permissions/requestApproval' do: aBlock
]

{ #category : 'approvals' }
OpenAICodexSession >> onToolUserInputRequestDo: aBlock [
	self whenServerRequest: 'item/tool/requestUserInput' do: aBlock
]

{ #category : 'private' }
OpenAICodexSession >> performMethod: aMethod parameters: aDictionary [
	^ self performMethod: aMethod parameters: aDictionary timeoutMs: self defaultTimeoutMs
]

{ #category : 'private' }
OpenAICodexSession >> performMethod: aMethod parameters: aDictionary timeoutMs: timeoutMs [
	| requestId request response |
	requestId := self nextRequestId.
	request := Dictionary new
		at: 'id' put: requestId;
		at: 'method' put: aMethod;
		at: 'params' put: aDictionary;
		yourself.
	transport sendMessage: request.
	response := self waitForResponseTo: requestId timeoutMs: timeoutMs.
	(response includesKey: 'error') ifTrue: [
		OpenAICodexProtocolError signal: ((response at: 'error') at: 'message' ifAbsent: [ 'App-server request failed' ]) ].
	^ response at: 'result' ifAbsent: [ Dictionary new ]
]

{ #category : 'private' }
OpenAICodexSession >> pumpIncomingMessages [
	| message |
	[
		message := transport nextMessage.
		message notNil ] whileTrue: [
			self handleIncomingMessage: message ]
]

{ #category : 'accessing' }
OpenAICodexSession >> readAccount [
	^ self performMethod: 'account/read' parameters: Dictionary new
]

{ #category : 'accessing' }
OpenAICodexSession >> readThread: aThreadId includeTurns: aBoolean [
	^ self readThreadWithParameters: (
		Dictionary new
			at: 'threadId' put: aThreadId;
			at: 'includeTurns' put: aBoolean;
			yourself)
]

{ #category : 'accessing' }
OpenAICodexSession >> readThreadWithParameters: aDictionary [
	^ self performMethod: 'thread/read' parameters: aDictionary
]

{ #category : 'messaging' }
OpenAICodexSession >> replyToServerRequestId: anId withErrorCode: anInteger message: aString data: aDictionaryOrNil [
	| errorPayload response |
	errorPayload := Dictionary new
		at: 'code' put: anInteger;
		at: 'message' put: aString;
		yourself.
	aDictionaryOrNil ifNotNil: [ errorPayload at: 'data' put: aDictionaryOrNil ].
	response := Dictionary new
		at: 'id' put: anId;
		at: 'error' put: errorPayload;
		yourself.
	transport sendMessage: response
]

{ #category : 'messaging' }
OpenAICodexSession >> replyToServerRequestId: anId withResult: aValue [
	| response |
	response := Dictionary new
		at: 'id' put: anId;
		at: 'result' put: aValue;
		yourself.
	transport sendMessage: response
]

{ #category : 'messaging' }
OpenAICodexSession >> resumeThreadWithParameters: aDictionary [
	^ self performMethod: 'thread/resume' parameters: aDictionary
]

{ #category : 'messaging' }
OpenAICodexSession >> sendNotificationMethod: aMethod parameters: aDictionary [
	transport sendMessage: (
		Dictionary new
			at: 'method' put: aMethod;
			at: 'params' put: aDictionary;
			yourself)
]

{ #category : 'messaging' }
OpenAICodexSession >> start [
	transport ifNil: [ OpenAICodexTransportError signal: 'A transport must be configured before session start' ].
	transport start.
	^ self
]

{ #category : 'messaging' }
OpenAICodexSession >> startTextTurnInThread: aThreadId text: aString [
	^ self startTextTurnInThread: aThreadId text: aString approvalPolicy: nil
]

{ #category : 'messaging' }
OpenAICodexSession >> startTextTurnInThread: aThreadId text: aString approvalPolicy: anApprovalPolicy [
	| params |
	params := Dictionary new
		at: 'threadId' put: aThreadId;
		at: 'input' put: {
			Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: aString;
				yourself };
		yourself.
	anApprovalPolicy ifNotNil: [ params at: 'approvalPolicy' put: anApprovalPolicy ].
	^ self startTurnWithParameters: params
]

{ #category : 'messaging' }
OpenAICodexSession >> startThread [
	^ self startThreadWithParameters: Dictionary new
]

{ #category : 'messaging' }
OpenAICodexSession >> startThreadInWorkingDirectory: aPathString approvalPolicy: anApprovalPolicy [
	| params |
	params := Dictionary new
		at: 'cwd' put: aPathString;
		yourself.
	anApprovalPolicy ifNotNil: [ params at: 'approvalPolicy' put: anApprovalPolicy ].
	^ self startThreadWithParameters: params
]

{ #category : 'messaging' }
OpenAICodexSession >> startThreadWithParameters: aDictionary [
	^ self performMethod: 'thread/start' parameters: aDictionary
]

{ #category : 'messaging' }
OpenAICodexSession >> startTurnWithParameters: aDictionary [
	^ self performMethod: 'turn/start' parameters: aDictionary
]

{ #category : 'messaging' }
OpenAICodexSession >> steerTextTurnInThread: aThreadId turnId: aTurnId text: aString [
	^ self performMethod: 'turn/steer' parameters: (
		Dictionary new
			at: 'threadId' put: aThreadId;
			at: 'expectedTurnId' put: aTurnId;
			at: 'input' put: {
				Dictionary new
					at: 'type' put: 'text';
					at: 'text' put: aString;
					yourself };
			yourself)
]

{ #category : 'messaging' }
OpenAICodexSession >> stop [
	transport ifNotNil: [ transport stop ]
]

{ #category : 'accessing' }
OpenAICodexSession >> transport [
	^ transport
]

{ #category : 'accessing' }
OpenAICodexSession >> transport: aTransport [
	transport := aTransport
]

{ #category : 'private' }
OpenAICodexSession >> waitForResponseTo: requestId timeoutMs: timeoutMs [
	| deadline response |
	deadline := Time millisecondClockValue + timeoutMs.
	[
		response := pendingResponses removeKey: requestId ifAbsent: [ nil ].
		response ifNotNil: [ ^ response ].
		self pumpIncomingMessages.
		(Time millisecondClockValue <= deadline) ] whileTrue: [
			(Delay forMilliseconds: 10) wait ].
	OpenAICodexTimeoutError signal: 'Timed out waiting for app-server response'
]

{ #category : 'messaging' }
OpenAICodexSession >> whenServerRequest: aMethod do: aBlock [
	serverRequestHandlers at: aMethod put: aBlock
]
