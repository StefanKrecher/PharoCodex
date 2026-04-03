Class {
	#name : 'OpenAICodexAnnouncement',
	#superclass : 'Announcement',
	#instVars : [
		'message'
	],
	#category : 'OpenAI-Codex',
	#package : 'OpenAI-Codex'
}

{ #category : 'instance creation' }
OpenAICodexAnnouncement class >> message: aDictionary [
	^ self new
		message: aDictionary;
		yourself
]

{ #category : 'accessing' }
OpenAICodexAnnouncement >> message [
	^ message
]

{ #category : 'accessing' }
OpenAICodexAnnouncement >> message: aDictionary [
	message := aDictionary
]

{ #category : 'accessing' }
OpenAICodexAnnouncement >> method [
	^ self message at: 'method' ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OpenAICodexAnnouncement >> params [
	^ self message at: 'params' ifAbsent: [ Dictionary new ]
]
