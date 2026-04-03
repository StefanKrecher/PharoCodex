Class {
	#name : 'OpenAICodexResponseAnnouncement',
	#superclass : 'OpenAICodexAnnouncement',
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'accessing' }
OpenAICodexResponseAnnouncement >> requestId [
	^ self message at: 'id' ifAbsent: [ nil ]
]
