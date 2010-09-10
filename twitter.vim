set rtp+=.

let request_token_url = "https://twitter.com/oauth/request_token"
let access_token_url = "https://api.twitter.com/oauth/access_token"
let auth_url =  "https://twitter.com/oauth/authorize"
let post_url = "https://api.twitter.com/1/statuses/update.xml"

let consumer_key = "CONSUMER_KEY"
let consumer_secret = "CONSUMER_SECRET"

let [request_token, request_token_secret] = oauth#requestToken(request_token_url, consumer_key, consumer_secret)
if has("win32") || has("win64")
  exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".request_token
else
  call system("xdg-open '".auth_url."?oauth_token=".request_token."'")
endif
let verifier = input("PIN:")
let [access_token, access_token_secret] = oauth#accessToken(access_token_url, consumer_key, consumer_secret, request_token, request_token_secret, {"oauth_verifier": verifier})
let status = "tweeeeeeeeeeeeeet"
let ret = oauth#sendData(post_url, consumer_key, consumer_secret, access_token, access_token_secret, {"status": status})
echo ret
