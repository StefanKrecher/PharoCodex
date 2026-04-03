Class {
	#name : 'OpenAICodexServerRequestAnnouncement',
	#superclass : 'OpenAICodexAnnouncement',
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'accessing' }
OpenAICodexServerRequestAnnouncement >> requestId [
	^ self message at: 'id' ifAbsent: [ nil ]
]
