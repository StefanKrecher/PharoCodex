Class {
	#name : #OpenAICodexMessageSerializer,
	#superclass : #Object,
	#category : #'OpenAI-Codex-Core',
	#package : #'OpenAI-Codex'
}

{ #category : #serializing }
OpenAICodexMessageSerializer >> deserializeMessage: aString [
	| message |
	message := NeoJSONReader fromString: aString.
	(message isDictionary or: [ message isKindOf: NeoJSONObject ]) ifFalse: [
		OpenAICodexProtocolError signal: 'App-server message must decode to a dictionary-like object' ].
	^ message asDictionary
]

{ #category : #serializing }
OpenAICodexMessageSerializer >> serializeMessage: aDictionary [
	aDictionary isDictionary ifFalse: [
		OpenAICodexProtocolError signal: 'App-server messages must be serialized from dictionaries' ].
	^ String streamContents: [ :stream |
		(NeoJSONWriter on: stream)
			nextPut: aDictionary ]
]
