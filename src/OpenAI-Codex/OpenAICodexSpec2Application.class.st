Class {
	#name : #OpenAICodexSpec2Application,
	#superclass : #SpPresenter,
	#instVars : [
		'session',
		'currentThreadId',
		'currentTurnId',
		'pollingProcess',
		'outputLock',
		'pendingOutput',
		'flushScheduled',
		'urlInput',
		'workingDirectoryInput',
		'promptInput',
		'outputText',
		'connectionStatusLabel',
		'statusLabel',
		'connectButton',
		'runButton',
		'refreshButton',
		'stopButton'
	],
	#category : #'OpenAI-Codex-UI',
	#package : #'OpenAI-Codex'
}

{ #category : #'instance creation' }
OpenAICodexSpec2Application class >> open [
	^ self new open
]

{ #category : #private }
OpenAICodexSpec2Application >> answerForQuestion: aQuestion [
	| options labels selection answer |
	options := aQuestion at: 'options' ifAbsent: [ nil ].
	options ifNotNil: [
		labels := options collect: [ :each | each at: 'label' ifAbsent: [ each printString ] ].
		selection := UIManager default chooseFrom: labels title: (aQuestion at: 'question').
		selection = 0 ifTrue: [ ^ nil ].
		answer := labels at: selection.
		^ Dictionary new
			at: 'answers' put: { answer };
			yourself ].
	answer := UIManager default request: (aQuestion at: 'question').
	answer ifNil: [ ^ nil ].
	^ Dictionary new
		at: 'answers' put: { answer };
		yourself
]

{ #category : #private }
OpenAICodexSpec2Application >> appendOutput: aString [
	outputText text: (self outputTextContents , aString)
]

{ #category : #actions }
OpenAICodexSpec2Application >> connectSession [
	| mcpStatus |
	self stopSession.
	self uiDo: [
		self updateStatus: 'Connecting...'.
		self writeOutput: 'Connecting to Codex app-server...' ].
	[
		session := OpenAICodexSession onTransport: (OpenAICodexWebSocketTransport toUrl: self serverUrl).
		session start.
		self installDefaultServerRequestHandlers.
		self installNotificationHandlers.
		session initializeClientNamed: 'pharo_codex_spec2' title: 'OpenAI Codex Spec2' version: '0.1.0'.
		currentThreadId := nil.
		currentTurnId := nil.
		mcpStatus := session listMcpServerStatus.
		self uiDo: [
			self updateConnectionStatusConnected.
			self updateStatus: 'Connected'.
			runButton enabled: true.
			refreshButton enabled: false.
			stopButton enabled: false.
			self writeOutput: (self formatMcpStatus: mcpStatus) ] ]
		on: Error
		do: [ :ex |
			self stopSession.
			self uiDo: [
				runButton enabled: false.
				self updateConnectionStatusDisconnected.
				self updateStatus: 'Connection failed'.
				self writeOutput: ex messageText ] ]
]

{ #category : #layout }
OpenAICodexSpec2Application >> defaultLayout [
	<spec: #default>
	| connectionRow actionRow statusRow |
	connectionRow := SpBoxLayout newLeftToRight
		spacing: 5;
		add: (self newLabel label: 'URL:')
			withConstraints: [ :constraints | constraints expand: false ];
		add: #urlInput;
		add: (self newLabel label: 'CWD:')
			withConstraints: [ :constraints | constraints expand: false ];
		add: #workingDirectoryInput;
		yourself.

	actionRow := SpBoxLayout newLeftToRight
		spacing: 5;
		add: #connectButton withConstraints: [ :constraints | constraints width: 110 ];
		add: #runButton withConstraints: [ :constraints | constraints width: 110 ];
		add: #refreshButton withConstraints: [ :constraints | constraints width: 110 ];
		add: #stopButton withConstraints: [ :constraints | constraints width: 110 ];
		yourself.

	statusRow := SpBoxLayout newLeftToRight
		spacing: 12;
		add: (self newLabel label: 'Connection:')
			withConstraints: [ :constraints | constraints expand: false ];
		add: #connectionStatusLabel withConstraints: [ :constraints | constraints width: 120 ];
		add: (self newLabel label: 'Turn:')
			withConstraints: [ :constraints | constraints expand: false ];
		add: #statusLabel;
		yourself.

	^ SpBoxLayout newTopToBottom
		spacing: 5;
		add: connectionRow withConstraints: [ :constraints |
			constraints expand: false.
			constraints height: 28 ];
		add: #promptInput withConstraints: [ :constraints | constraints height: 120 ];
		add: actionRow withConstraints: [ :constraints |
			constraints expand: false.
			constraints height: 28 ];
		add: #outputText;
		add: statusRow withConstraints: [ :constraints |
			constraints expand: false.
			constraints height: 24 ];
		yourself
]

{ #category : #private }
OpenAICodexSpec2Application >> flushPendingOutput [
	| delta |
	outputLock critical: [
		delta := pendingOutput.
		pendingOutput := ''.
		flushScheduled := false ].
	delta ifEmpty: [ ^ self ].
	(self outputTextContents isEmpty or: [ self outputTextContents = 'Not connected.' ])
		ifTrue: [ self writeOutput: '' ].
	self appendOutput: delta
]

{ #category : #private }
OpenAICodexSpec2Application >> formatLines: aCollection [
	^ String streamContents: [ :stream |
		aCollection doWithIndex: [ :line :index |
			index > 1 ifTrue: [ stream crlf ].
			stream nextPutAll: line asString ] ]
]

{ #category : #private }
OpenAICodexSpec2Application >> formatMcpStatus: aDictionary [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Connected.';
			crlf;
			nextPutAll: 'MCP status: ';
			nextPutAll: aDictionary printString ]
]

{ #category : #private }
OpenAICodexSpec2Application >> formatThreadReadResult: aDictionary [
	| lastTurn items lines |
	lastTurn := self lastTurnFromThreadRead: aDictionary.
	lastTurn ifNil: [ ^ 'No turns returned.' ].
	lines := OrderedCollection new.
	lines add: ('Turn status: ', (lastTurn at: 'status' ifAbsent: [ 'unknown' ])).
	items := lastTurn at: 'items' ifAbsent: [ #() ].
	items do: [ :item | lines addAll: (self linesForThreadItem: item) ].
	^ self formatLines: lines
]

{ #category : #private }
OpenAICodexSpec2Application >> handleAgentMessageDelta: aParams [
	(self isCurrentThreadNotification: aParams) ifFalse: [ ^ self ].
	(self isCurrentTurnNotification: aParams) ifFalse: [ ^ self ].
	self queueOutput: (aParams at: 'delta' ifAbsent: [ '' ])
]

{ #category : #private }
OpenAICodexSpec2Application >> handleMcpToolCallProgress: aParams [
	| progressLine |
	(self isCurrentThreadNotification: aParams) ifFalse: [ ^ self ].
	(self isCurrentTurnNotification: aParams) ifFalse: [ ^ self ].
	progressLine := String streamContents: [ :stream |
		stream
			nextPutAll: String crlf;
			nextPutAll: 'MCP: ';
			nextPutAll: (aParams at: 'message' ifAbsent: [ '' ]) ].
	self queueOutput: progressLine
]

{ #category : #private }
OpenAICodexSpec2Application >> handleNotificationAnnouncement: anAnnouncement [
	| method params |
	method := anAnnouncement method.
	params := anAnnouncement params.
	method = 'item/agentMessage/delta' ifTrue: [ ^ self handleAgentMessageDelta: params ].
	method = 'item/mcpToolCall/progress' ifTrue: [ ^ self handleMcpToolCallProgress: params ].
	method = 'turn/started' ifTrue: [ ^ self handleTurnStartedNotification: params ].
	method = 'turn/completed' ifTrue: [ ^ self handleTurnCompletedNotification: params ].
	method = 'error' ifTrue: [ ^ self handleTurnErrorNotification: params ]
]

{ #category : #private }
OpenAICodexSpec2Application >> handleTurnCompletedNotification: aParams [
	| turn status |
	(self isCurrentThreadNotification: aParams) ifFalse: [ ^ self ].
	turn := aParams at: 'turn' ifAbsent: [ ^ self ].
	currentTurnId ifNotNil: [
		((turn at: 'id' ifAbsent: [ nil ]) = currentTurnId) ifFalse: [ ^ self ] ].
	status := turn at: 'status' ifAbsent: [ 'completed' ].
	self uiDo: [ self updateStatus: ('Turn ', status) ].
	self stopPolling
]

{ #category : #private }
OpenAICodexSpec2Application >> handleTurnErrorNotification: aParams [
	self uiDo: [
		self updateStatus: 'Turn error'.
		self queueOutput: (String streamContents: [ :stream |
			stream
				nextPutAll: String crlf;
				nextPutAll: 'Error: ';
				nextPutAll: aParams printString ]) ]
]

{ #category : #private }
OpenAICodexSpec2Application >> handleTurnStartedNotification: aParams [
	| turn |
	(self isCurrentThreadNotification: aParams) ifFalse: [ ^ self ].
	turn := aParams at: 'turn' ifAbsent: [ ^ self ].
	currentTurnId := turn at: 'id' ifAbsent: [ currentTurnId ].
	self uiDo: [ self updateStatus: 'Running...' ]
]

{ #category : #private }
OpenAICodexSpec2Application >> interactiveElicitationResponseFor: aRequest [
	| params mode action content |
	params := aRequest at: 'params'.
	mode := params at: 'mode'.
	mode = 'url' ifTrue: [
		action := self uiCall: [
			(UIManager default confirm: ((params at: 'message'), String crlf, (params at: 'url')))
				ifTrue: [ 'accept' ]
				ifFalse: [ 'cancel' ] ].
		^ Dictionary new
			at: 'action' put: action;
			yourself ].
	content := self uiCall: [ self interactiveFormContentFor: params ].
	content ifNil: [
		^ Dictionary new
			at: 'action' put: 'cancel';
			yourself ].
	^ Dictionary new
		at: 'action' put: 'accept';
		at: 'content' put: content;
		yourself
]

{ #category : #private }
OpenAICodexSpec2Application >> interactiveFormContentFor: aParams [
	| schema properties result |
	schema := aParams at: 'requestedSchema' ifAbsent: [ ^ nil ].
	properties := schema at: 'properties' ifAbsent: [ ^ Dictionary new ].
	result := Dictionary new.
	properties keysAndValuesDo: [ :key :propertySchema |
		| title value |
		title := propertySchema at: 'title' ifAbsent: [ key ].
		value := self interactiveValueForSchema: propertySchema title: title.
		value ifNil: [ ^ nil ].
		result at: key put: value ].
	^ result
]

{ #category : #private }
OpenAICodexSpec2Application >> interactiveToolUserInputResponseFor: aRequest [
	| params answers |
	params := aRequest at: 'params'.
	answers := self uiCall: [
		| result |
		result := Dictionary new.
		(params at: 'questions') do: [ :question |
			| answer |
			answer := self answerForQuestion: question.
			answer ifNil: [ ^ nil ].
			result at: (question at: 'id') put: answer ].
		result ].
	answers ifNil: [ ^ Dictionary new at: 'answers' put: Dictionary new; yourself ].
	^ Dictionary new
		at: 'answers' put: answers;
		yourself
]

{ #category : #private }
OpenAICodexSpec2Application >> interactiveValueForSchema: aSchema title: aTitle [
	| type options labels selection answer |
	type := aSchema at: 'type' ifAbsent: [ 'string' ].
	(type = 'boolean') ifTrue: [ ^ UIManager default confirm: aTitle ].
	((aSchema includesKey: 'enum') and: [ type = 'string' ]) ifTrue: [
		options := aSchema at: 'enum'.
		labels := aSchema at: 'enumNames' ifAbsent: [ options ].
		selection := UIManager default chooseFrom: labels title: aTitle.
		selection = 0 ifTrue: [ ^ nil ].
		^ options at: selection ].
	((aSchema includesKey: 'oneOf') and: [ type = 'string' ]) ifTrue: [
		options := aSchema at: 'oneOf'.
		labels := options collect: [ :each | each at: 'title' ifAbsent: [ each at: 'const' ] ].
		selection := UIManager default chooseFrom: labels title: aTitle.
		selection = 0 ifTrue: [ ^ nil ].
		^ (options at: selection) at: 'const' ].
	answer := UIManager default request: aTitle.
	answer ifNil: [ ^ nil ].
	((type = 'integer') or: [ type = 'number' ]) ifTrue: [ ^ Number readFrom: answer readStream ].
	(type = 'array') ifTrue: [ ^ (answer substrings: ',') collect: [ :each | each withBlanksTrimmed ] ].
	^ answer
]

{ #category : #initialization }
OpenAICodexSpec2Application >> initialize [
	super initialize.
	currentThreadId := nil.
	currentTurnId := nil.
	outputLock := Semaphore forMutualExclusion.
	pendingOutput := ''.
	flushScheduled := false
]

{ #category : #initialization }
OpenAICodexSpec2Application >> initializePresenters [
	urlInput := self newTextInput.
	urlInput
		text: 'ws://127.0.0.1:8787';
		placeholder: 'ws://127.0.0.1:8787'.

	workingDirectoryInput := self newTextInput.
	workingDirectoryInput text: FileSystem disk workingDirectory pathString.

	promptInput := self newText.
	promptInput
		beWrapWord;
		editable: true;
		placeholder: 'Enter a Codex prompt';
		text: 'Use pharo_eval to evaluate 23 + 42 and return only the result.'.

	outputText := self newText.
	outputText
		beWrapWord;
		beNotEditable;
		enabled: false;
		text: 'Not connected.'.

	connectionStatusLabel := self newLabel label: 'Disconnected'.
	connectionStatusLabel color: Color red.

	statusLabel := self newLabel label: 'Disconnected'.
	statusLabel color: Color red.

	connectButton := self newButton
		label: 'Connect';
		action: [ self connectSession ];
		yourself.

	runButton := self newButton
		label: 'Run Prompt';
		action: [ self runPrompt ];
		enabled: false;
		yourself.

	refreshButton := self newButton
		label: 'Refresh';
		action: [ self refreshCurrentThread ];
		enabled: false;
		yourself.

	stopButton := self newButton
		label: 'Stop';
		action: [ self stopPolling ];
		enabled: false;
		yourself.

	self focusOrder
		add: urlInput;
		add: workingDirectoryInput;
		add: promptInput;
		add: connectButton;
		add: runButton;
		add: refreshButton;
		add: stopButton
]

{ #category : #private }
OpenAICodexSpec2Application >> installDefaultServerRequestHandlers [
	session onCommandApprovalDo: [ :request |
		Dictionary new
			at: 'decision' put: 'accept';
			yourself ].
	session onFileChangeApprovalDo: [ :request |
		Dictionary new
			at: 'decision' put: 'accept';
			yourself ].
	session onPermissionsApprovalDo: [ :request |
		Dictionary new
			at: 'permissions' put: ((request at: 'params') at: 'permissions');
			at: 'scope' put: 'turn';
			yourself ].
	session onMcpElicitationRequestDo: [ :request |
		self interactiveElicitationResponseFor: request ].
	session onToolUserInputRequestDo: [ :request |
		self interactiveToolUserInputResponseFor: request ]
]

{ #category : #private }
OpenAICodexSpec2Application >> installNotificationHandlers [
	session on: OpenAICodexNotificationAnnouncement do: [ :announcement |
		self handleNotificationAnnouncement: announcement ]
]

{ #category : #private }
OpenAICodexSpec2Application >> isCurrentThreadNotification: aParams [
	| threadId |
	threadId := aParams at: 'threadId' ifAbsent: [ ^ true ].
	currentThreadId ifNil: [ ^ true ].
	^ threadId = currentThreadId
]

{ #category : #private }
OpenAICodexSpec2Application >> isCurrentTurnNotification: aParams [
	| turnId |
	turnId := aParams at: 'turnId' ifAbsent: [ ^ true ].
	currentTurnId ifNil: [ ^ true ].
	^ turnId = currentTurnId
]

{ #category : #private }
OpenAICodexSpec2Application >> isTurnActive [
	^ currentThreadId notNil and: [ currentTurnId notNil and: [ pollingProcess notNil ] ]
]

{ #category : #private }
OpenAICodexSpec2Application >> lastTurnFromThreadRead: aDictionary [
	| turns |
	turns := ((aDictionary at: 'thread') at: 'turns' ifAbsent: [ #() ]).
	^ turns ifEmpty: [ nil ] ifNotEmpty: [ turns last ]
]

{ #category : #private }
OpenAICodexSpec2Application >> linesForThreadItem: anItem [
	| type result lines |
	type := anItem at: 'type' ifAbsent: [ 'unknown' ].
	lines := OrderedCollection new.
	type = 'agentMessage' ifTrue: [
		lines add: (anItem at: 'text' ifAbsent: [ '' ]).
		^ lines ].
	type = 'mcpToolCall' ifTrue: [
		lines add: ('MCP ', (anItem at: 'server' ifAbsent: [ '?' ]), ' >> ', (anItem at: 'tool' ifAbsent: [ '?' ]), ' [', (anItem at: 'status' ifAbsent: [ '?' ]), ']').
		result := anItem at: 'result' ifAbsent: [ nil ].
		result ifNotNil: [ lines add: result printString ].
		^ lines ].
	type = 'commandExecution' ifTrue: [
		lines add: ('Command [', (anItem at: 'status' ifAbsent: [ '?' ]), ']: ', (anItem at: 'command' ifAbsent: [ '' ])).
		(anItem at: 'aggregatedOutput' ifAbsent: [ nil ]) ifNotNil: [ :output | lines add: output ].
		^ lines ].
	type = 'reasoning' ifTrue: [ ^ lines ].
	lines add: anItem printString.
	^ lines
]

{ #category : #accessing }
OpenAICodexSpec2Application >> outputTextContents [
	^ outputText text asString
]

{ #category : #private }
OpenAICodexSpec2Application >> pollThreadLoop [
	[ session notNil and: [ currentThreadId notNil ] ] whileTrue: [
		[ self refreshCurrentThread ]
			on: Error
			do: [ :ex |
				self uiDo: [
					self updateStatus: 'Polling failed'.
					self writeOutput: ex messageText ].
				self stopPolling ].
		(Delay forSeconds: 2) wait ]
]

{ #category : #private }
OpenAICodexSpec2Application >> pollTurnStatusFrom: aThreadRead [
	| lastTurn finished |
	lastTurn := self lastTurnFromThreadRead: aThreadRead.
	lastTurn ifNil: [ ^ self uiDo: [ self updateStatus: 'Waiting for first output...' ] ].
	currentTurnId := lastTurn at: 'id' ifAbsent: [ currentTurnId ].
	finished := self turnIsFinished: lastTurn.
	self uiDo: [
		self writeOutput: (self formatThreadReadResult: aThreadRead).
		finished
			ifTrue: [ self updateStatus: ('Turn ', (lastTurn at: 'status' ifAbsent: [ 'completed' ])) ]
			ifFalse: [ self updateStatus: 'Running...' ] ].
	finished ifTrue: [ self stopPolling ]
]

{ #category : #private }
OpenAICodexSpec2Application >> promptText [
	^ promptInput text asString
]

{ #category : #private }
OpenAICodexSpec2Application >> queueOutput: aString [
	outputLock critical: [
		pendingOutput := pendingOutput , aString.
		flushScheduled ifFalse: [
			flushScheduled := true.
			self uiDo: [ self flushPendingOutput ] ] ]
]

{ #category : #actions }
OpenAICodexSpec2Application >> refreshCurrentThread [
	| threadRead |
	currentThreadId ifNil: [ ^ self uiDo: [ self writeOutput: 'No active thread.' ] ].
	threadRead := self waitForCompletedTurnReadAttempt.
	threadRead ifNil: [ ^ self uiDo: [ self updateStatus: 'Waiting for first output...' ] ].
	self uiDo: [ refreshButton enabled: true ].
	self pollTurnStatusFrom: threadRead
]

{ #category : #actions }
OpenAICodexSpec2Application >> runPrompt [
	| prompt |
	prompt := self promptText trimBoth.
	prompt ifEmpty: [
		^ self uiDo: [
			self updateStatus: 'Missing prompt'.
			self writeOutput: 'Enter a prompt first.' ] ].
	session ifNil: [ self connectSession ].
	session ifNil: [ ^ self ].
	self uiDo: [
		self updateStatus: 'Starting turn...'.
		self writeOutput: '' ].
	^ self runPrompt: prompt allowingRetry: true
]

{ #category : #actions }
OpenAICodexSpec2Application >> runPrompt: aPrompt allowingRetry: aBoolean [
	| threadResponse turnResponse |
	[
		(self isTurnActive) ifTrue: [
			turnResponse := session
				steerTextTurnInThread: currentThreadId
				turnId: currentTurnId
				text: aPrompt.
			currentTurnId := ((turnResponse at: 'turn') at: 'id' ifAbsent: [ currentTurnId ]).
			self uiDo: [
				self queueOutput: (String crlf, 'Steer: ', aPrompt, String crlf).
				self updateStatus: 'Running...' ].
			^ self ].

		currentThreadId ifNil: [
			threadResponse := session
				startThreadInWorkingDirectory: self workingDirectory
				approvalPolicy: 'on-request'.
			currentThreadId := ((threadResponse at: 'thread') at: 'id') ].
		turnResponse := session
			startTextTurnInThread: currentThreadId
			text: aPrompt
			approvalPolicy: 'on-request'.
		currentTurnId := ((turnResponse at: 'turn') at: 'id' ifAbsent: [ nil ]).
		self uiDo: [
			self writeOutput: ('Turn started in thread ', currentThreadId, '.', String crlf).
			self updateStatus: 'Running...' ].
		self startPolling ]
		on: OpenAICodexProtocolError
		do: [ :ex |
			(self shouldRetryAfterProtocolError: ex)
				ifTrue: [
					aBoolean ifFalse: [ ex pass ].
					currentThreadId := nil.
					self uiDo: [ self updateStatus: 'Retrying...' ].
					^ self runPrompt: aPrompt allowingRetry: false ].
			ex pass ]
]

{ #category : #accessing }
OpenAICodexSpec2Application >> serverUrl [
	^ urlInput text asString
]

{ #category : #private }
OpenAICodexSpec2Application >> shouldRetryAfterProtocolError: anError [
	^ anError messageText includesSubstring: 'rollout'
		and: [ anError messageText includesSubstring: 'is empty' ]
]

{ #category : #private }
OpenAICodexSpec2Application >> startPolling [
	self stopPolling.
	self uiDo: [
		stopButton enabled: true.
		refreshButton enabled: true ].
	pollingProcess := [ self pollThreadLoop ] forkNamed: 'OpenAICodex Spec2 Poller'
]

{ #category : #accessing }
OpenAICodexSpec2Application >> statusLabel [
	^ statusLabel
]

{ #category : #actions }
OpenAICodexSpec2Application >> stopPolling [
	pollingProcess ifNotNil: [
		pollingProcess terminate.
		pollingProcess := nil ].
	self uiDo: [
		stopButton ifNotNil: [ stopButton enabled: false ].
		refreshButton ifNotNil: [ refreshButton enabled: currentThreadId notNil ].
		(statusLabel notNil and: [ statusLabel label = 'Running...' ])
			ifTrue: [ self updateStatus: 'Monitoring stopped' ] ]
]

{ #category : #actions }
OpenAICodexSpec2Application >> stopSession [
	self stopPolling.
	session ifNotNil: [
		session stop.
		session := nil ].
	currentThreadId := nil.
	currentTurnId := nil.
	self uiDo: [ self updateConnectionStatusDisconnected ]
]

{ #category : #private }
OpenAICodexSpec2Application >> turnIsFinished: aTurnDictionary [
	| status |
	aTurnDictionary ifNil: [ ^ false ].
	status := aTurnDictionary at: 'status' ifAbsent: [ ^ false ].
	^ #( 'completed' 'failed' 'interrupted' ) includes: status
]

{ #category : #private }
OpenAICodexSpec2Application >> uiCall: aBlock [
	| semaphore result error |
	semaphore := Semaphore new.
	self uiDo: [
		[ result := aBlock value ]
			on: Error
			do: [ :ex | error := ex ].
		semaphore signal ].
	semaphore wait.
	error ifNotNil: [ error pass ].
	^ result
]

{ #category : #private }
OpenAICodexSpec2Application >> uiDo: aBlock [
	UIManager default defer: aBlock
]

{ #category : #private }
OpenAICodexSpec2Application >> updateConnectionStatusConnected [
	connectionStatusLabel label: 'Connected'.
	connectionStatusLabel color: Color green darker
]

{ #category : #private }
OpenAICodexSpec2Application >> updateConnectionStatusDisconnected [
	connectionStatusLabel label: 'Disconnected'.
	connectionStatusLabel color: Color red
]

{ #category : #private }
OpenAICodexSpec2Application >> updateStatus: aString [
	statusLabel label: aString.
	(aString includesSubstring: 'Connected') ifTrue: [ statusLabel color: Color green darker ].
	(aString includesSubstring: 'Running') ifTrue: [ statusLabel color: Color blue muchDarker ].
	(aString includesSubstring: 'Waiting') ifTrue: [ statusLabel color: Color orange darker ].
	((aString includesSubstring: 'failed')
		or: [ (aString includesSubstring: 'error')
		or: [ (aString includesSubstring: 'Disconnected')
		or: [ aString includesSubstring: 'Missing' ] ] ])
			ifTrue: [ statusLabel color: Color red ].
	(aString includesSubstring: 'Monitoring stopped') ifTrue: [ statusLabel color: Color gray darker ]
]

{ #category : #private }
OpenAICodexSpec2Application >> waitForCompletedTurnReadAttempt [
	^ [ session readThread: currentThreadId includeTurns: true ]
		on: OpenAICodexProtocolError
		do: [ :ex |
			(ex messageText includesSubstring: 'is not materialized yet')
				ifTrue: [ nil ]
				ifFalse: [ ex pass ] ]
]

{ #category : #accessing }
OpenAICodexSpec2Application >> workingDirectory [
	^ workingDirectoryInput text asString
]

{ #category : #private }
OpenAICodexSpec2Application >> writeOutput: aString [
	outputText text: aString
]
