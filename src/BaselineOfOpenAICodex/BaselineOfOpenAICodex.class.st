Class {
	#name : #BaselineOfOpenAICodex,
	#superclass : #BaselineOf,
	#category : #BaselineOfOpenAICodex,
	#package : #BaselineOfOpenAICodex
}

{ #category : #baselines }
BaselineOfOpenAICodex >> baseline: spec [
	<baseline>

	spec for: #common do: [
		spec package: 'OpenAI-Codex'.
		spec package: 'OpenAI-Codex-Tests' with: [ spec requires: #( 'OpenAI-Codex' ) ].
		spec group: 'default' with: #( 'OpenAI-Codex' ).
		spec group: 'tests' with: #( 'OpenAI-Codex' 'OpenAI-Codex-Tests' ) ]
]
