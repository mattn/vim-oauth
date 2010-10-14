set rtp+=webapi-vim

let ctx = {}
let configfile = expand('~/.cybozulive')
if filereadable(configfile)
  let ctx = eval(join(readfile(configfile), ""))
else
  let ctx.consumer_key = input("consumer_key:")
  let ctx.consumer_secret = input("consumer_secret:")
  
  let request_token_url = "https://api.cybozulive.com/oauth/initiate"
  let auth_url = "https://api.cybozulive.com/oauth/authorize"
  let access_token_url = "https://api.cybozulive.com/oauth/token"
  
  let ctx = oauth#request_token(request_token_url, ctx)
  if has("win32") || has("win64")
    exe "!start rundll32 url.dll,FileProtocolHandler ".auth_url."?oauth_token=".request_token
  else
    call system("xdg-open '".auth_url."?oauth_token=".request_token."'")
  endif
  let verifier = input("PIN:")
  let ctx = oauth#access_token(access_token_url, ctx, {"oauth_verifier": verifier})
  call writefile([string(ctx)], configfile)
endif

let notification_url = "https://api.cybozulive.com/api/notification/V2"
let ret = oauth#get(notification_url, ctx)
let dom = xml#parse(ret.content)
for elem in dom.findAll("entry")
  echo elem.find("updated").value() . " " .  elem.find("title").value()
  echo "  " . elem.find("author").find("name").value()
  let summary = elem.find("summary")
  if !empty(summary)
    echo "  " . substitute(summary.value(), "\n", "\n  ", "g")
  endif
  echo "\n"
endfor
