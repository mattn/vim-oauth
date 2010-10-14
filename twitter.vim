set rtp+=webapi-vim

let request_token_url = "https://twitter.com/oauth/request_token"
let access_token_url = "https://api.twitter.com/oauth/access_token"
let auth_url =  "https://twitter.com/oauth/authorize"
let post_url = "https://api.twitter.com/1/statuses/update.xml"

let ctx = {"consumer_key": $CONSUMER_KEY, "consumer_secret": $CONSUMER_SECRET}
let ctx = oauth#request_token(request_token_url, ctx)
if has("win32") || has("win64")
  exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".ctx.request_token
else
  call system("xdg-open '".auth_url."?oauth_token=".ctx.request_token."'")
endif
let verifier = input("PIN:")
let ctx = oauth#access_token(access_token_url, ctx, {"oauth_verifier": verifier})
let status = "tweeeeeeeeeeeeeet"
let ret = oauth#post(post_url, ctx, {}, {"status": status})
echo ret
