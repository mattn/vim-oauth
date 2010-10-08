set rtp+=webapi-vim

let request_token_url = "https://www.google.com/accounts/OAuthGetRequestToken"
let access_token_url = "https://www.google.com/accounts/OAuthGetAccessToken"
let auth_url = "https://www.google.com/buzz/api/auth/OAuthAuthorizeToken"
let post_url = "https://www.googleapis.com/buzz/v1/activities/@me/@self"

let consumer_key = $CONSUMER_KEY
let consumer_secret = $CONSUMER_SECRET
let domain = $CONSUMER_DOMAIN
let callback = $CONSUMER_CALLBACK

let [request_token, request_token_secret] = oauth#requestToken(request_token_url, consumer_key, consumer_secret, {"scope": "https://www.googleapis.com/auth/buzz", "oauth_callback": callback})
if has("win32") || has("win64")
  exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".request_token."&domain=".domain."&scope=https://www.googleapis.com/auth/buzz"
else
  call system("xdg-open '".auth_url."?oauth_token=".request_token."'")
endif
let verifier = input("PIN:")
let [access_token, access_token_secret] = oauth#accessToken(access_token_url, consumer_key, consumer_secret, request_token, request_token_secret, {"oauth_verifier": verifier})
echo access_token
echo access_token_secret
let data = ''
\.'<entry xmlns:activity="http://activitystrea.ms/spec/1.0/"'
\.' xmlns:poco="http://portablecontacts.net/ns/1.0"'
\.' xmlns:georss="http://www.georss.org/georss"'
\.' xmlns:buzz="http://schemas.google.com/buzz/2010">'
\.'  <activity:object>'
\.'    <activity:object-type>http://activitystrea.ms/schema/1.0/note</activity:object-type>'
\.'    <content>Bzz! Bzz!</content>'
\.'  </activity:object>'
\.'</entry>'
let ret = oauth#post(post_url, consumer_key, consumer_secret, access_token, access_token_secret, {}, data, {"Content-Type": "application/atom+xml", "GData-Version": "2.0"})
echo ret
