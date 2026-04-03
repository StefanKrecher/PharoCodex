Class {
	#name : #OpenAICodexFakeWebSocketConnectionFactory,
	#superclass : #OpenAICodexWebSocketConnectionFactory,
	#instVars : [
		'connection',
		'lastOpenedUrl'
	],
	#category : #'OpenAI-Codex-Tests-Support',
	#package : #'OpenAI-Codex-Tests'
}

{ #category : #initialization }
OpenAICodexFakeWebSocketConnectionFactory >> initialize [
	super initialize.
	connection := OpenAICodexFakeWebSocketConnection new
]

{ #category : #accessing }
OpenAICodexFakeWebSocketConnectionFactory >> connection [
	^ connection
]

{ #category : #accessing }
OpenAICodexFakeWebSocketConnectionFactory >> lastOpenedUrl [
	^ lastOpenedUrl
]

{ #category : #opening }
OpenAICodexFakeWebSocketConnectionFactory >> openUrl: aString [
	lastOpenedUrl := aString.
	^ connection
]
