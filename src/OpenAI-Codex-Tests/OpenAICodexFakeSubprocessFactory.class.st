Class {
	#name : #OpenAICodexFakeSubprocessFactory,
	#superclass : #OpenAICodexSubprocessFactory,
	#instVars : [
		'subprocess',
		'lastSpawnCommand',
		'lastSpawnArguments',
		'lastSpawnWorkingDirectory'
	],
	#category : #'OpenAI-Codex-Tests-Support',
	#package : #'OpenAI-Codex-Tests'
}

{ #category : #initialization }
OpenAICodexFakeSubprocessFactory >> initialize [
	super initialize.
	subprocess := OpenAICodexFakeLineSubprocess new
]

{ #category : #accessing }
OpenAICodexFakeSubprocessFactory >> lastSpawnArguments [
	^ lastSpawnArguments
]

{ #category : #accessing }
OpenAICodexFakeSubprocessFactory >> lastSpawnCommand [
	^ lastSpawnCommand
]

{ #category : #accessing }
OpenAICodexFakeSubprocessFactory >> lastSpawnWorkingDirectory [
	^ lastSpawnWorkingDirectory
]

{ #category : #spawning }
OpenAICodexFakeSubprocessFactory >> spawnCommand: aCommand arguments: arguments workingDirectory: aPathOrNil [
	lastSpawnCommand := aCommand.
	lastSpawnArguments := arguments.
	lastSpawnWorkingDirectory := aPathOrNil.
	^ subprocess
]

{ #category : #accessing }
OpenAICodexFakeSubprocessFactory >> subprocess [
	^ subprocess
]
