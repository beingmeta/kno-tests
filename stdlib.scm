(check-modules
 '{opts gpath/hashfs kno/rulesets kno/meltcache curlcache saveopt crypto/signature cachequeue 
   net/checkurl codewalker text/ellipsize net/email fakezip fillin 
   findcycles getcontent hashstats histogram hostinfo i18n ice 
   net/mimeout net/oauth bugjar text/readcsv samplefns 
   text/speling trackrefs os/updatefile kno/whocalls
   apis/gravatar apis/twilio apis/couchdb apis/dropbox  apis/tinygis
   batch})

(check-modules '{apis/aws apis/aws/s3 apis/aws/ses apis/aws/simpledb apis/aws/sqs apis/aws/v4
		 apis/aws/associates apis/aws/dynamodb})

(check-modules '{domutils domutils/index domutils/localize
		 domutils/styles domutils/css domutils/cleanup
		 domutils/adjust domutils/analyze
		 ;; domutils/hyphenate
		 })

(check-modules '{apis/facebook apis/facebook/fbcall apis/facebook/fbml})

(check-modules '{booktools/gutdb booktools/hathitrust booktools/isbn booktools/librarything booktools/openlibrary})

(check-modules '{apis/google apis/google/drive})

(check-modules '{knodules knodules/drules
		 knodules/html knodules/plaintext})

(check-modules '{misc/oidshift})

(check-modules '{apis/paypal apis/paypal/checkout apis/paypal/express apis/paypal/adaptive})

;;(check-modules '{textindex textindex/domtext})

(check-modules '{apis/twitter})

(check-modules '{morph morph/en morph/es})
