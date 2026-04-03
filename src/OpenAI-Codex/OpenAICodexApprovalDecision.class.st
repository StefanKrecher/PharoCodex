Class {
	#name : #OpenAICodexApprovalDecision,
	#superclass : #Object,
	#category : #'OpenAI-Codex-Core',
	#package : #'OpenAI-Codex'
}

{ #category : #'instance creation' }
OpenAICodexApprovalDecision class >> accept [
	^ 'accept'
]

{ #category : #'instance creation' }
OpenAICodexApprovalDecision class >> acceptForSession [
	^ 'acceptForSession'
]

{ #category : #'instance creation' }
OpenAICodexApprovalDecision class >> cancel [
	^ 'cancel'
]

{ #category : #'instance creation' }
OpenAICodexApprovalDecision class >> decline [
	^ 'decline'
]
