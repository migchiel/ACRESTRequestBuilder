Class {
	#name : 'ACRequestBuilder',
	#superclass : 'Object',
	#instVars : [
		'showProgress',
		'httpClient'
	],
	#category : 'ACRESTRequestBuilder',
	#package : 'ACRESTRequestBuilder'
}

{ #category : 'executing' }
ACRequestBuilder >> apiLimitDelay [
	"retry wait time for HTTP 429, api rate limit (in seconds)"

	^ 64
]

{ #category : 'executing' }
ACRequestBuilder >> execute [

	^ showProgress
		  ifTrue: [ self executeShowingProgress ]
		  ifFalse: [ self executeWithoutShowingProgress ]
]

{ #category : 'executing' }
ACRequestBuilder >> executeShowingProgress [

	UIManager default informUserDuring: [ :bar |
			bar label: 'Performing API call...'.
			[
				self executeWithoutShowingProgress]
				on: HTTPProgress
				do: [ :progress |
						bar label: progress printString.
						progress isEmpty ifFalse: [ bar current: progress percentage ].
						progress resume ] ]
]

{ #category : 'executing' }
ACRequestBuilder >> executeWithoutShowingProgress [

	httpClient ifFail: [ :exception |
		((exception isKindOf: ZnHttpUnsuccessful) and: [
			 #( 429 ) includes: exception response code ]) ifTrue: [
			self recoverFromApiLimit.
			exception signaler execute ] ].
	^ httpClient execute
]

{ #category : 'initialization' }
ACRequestBuilder >> initialize [

	httpClient := ZnClient new.
	showProgress := true.
	self setDefaults
]

{ #category : 'executing' }
ACRequestBuilder >> recoverFromApiLimit [

	1 to: self apiLimitDelay do: [ :seconds |
		HTTPProgress
			signal:
				'API Rate limit hit,delaying for ' , self apiLimitDelay asString
				, ' seconds...'
			amount: seconds
			total: self apiLimitDelay.
		(Delay forSeconds: 1) wait ]
]

{ #category : 'initialization' }
ACRequestBuilder >> setDefaults [
	self signalProgress: true.
	httpClient
		systemPolicy;
		https;
		forJsonREST;
		autoResetEntityMethods: #( #GET );
		logToTranscript;
		loggingOn
]

{ #category : 'signalling' }
ACRequestBuilder >> signalProgress: aBoolean [

	httpClient signalProgress: aBoolean.
	showProgress := aBoolean
]
