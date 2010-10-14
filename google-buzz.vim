set rtp+=.

let request_token_url = "https://www.google.com/accounts/OAuthGetRequestToken"
let access_token_url = "https://www.google.com/accounts/OAuthGetAccessToken"
let auth_url = "https://www.google.com/buzz/api/auth/OAuthAuthorizeToken"
let post_url = "https://www.googleapis.com/buzz/v1/activities/@me/@self"

let ctx = {"consumer_key": $CONSUMER_KEY, "consumer_secret": $CONSUMER_SECRET, "domain": $CONSUMER_DOMAIN, "callback": $CONSUMER_CALLBACK}
let ctx = oauth#request_token(request_token_url, ctx, {"scope": "https://www.googleapis.com/auth/buzz", "oauth_callback": ctx.callback})
if has("win32") || has("win64")
  exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".ctx.request_token."&domain=".ctx.domain."&scope=https://www.googleapis.com/auth/buzz"
else
  call system("xdg-open '".auth_url."?oauth_token=".ctx.request_token. "&domain=".ctx.domain."&scope=https://www.googleapis.com/auth/buzz'")
endif
let verifier = input("PIN:")
let ctx = oauth#access_token(access_token_url, ctx, {"oauth_verifier": verifier})
echo ctx.access_token
echo ctx.access_token_secret
let data = ''
\.'<entry xmlns:activity="http://activitystrea.ms/spec/1.0/"'
\.' xmlns:poco="http://portablecontacts.net/ns/1.0"'
\.' xmlns:georss="http://www.georss.org/georss"'
\.' xmlns:buzz="http://schemas.google.com/buzz/2010">'
\.'  <activity:object>'
\.'    <activity:object-type>http://activitystrea.ms/schema/1.0/note</activity:object-type>'
\.'    <content>ばず! ばず!</content>'
\.'  </activity:object>'
\.'</entry>'
let ret = oauth#post(post_url, ctx, {}, data, {"Content-Type": "application/atom+xml", "GData-Version": "2.0"})
echo ret
