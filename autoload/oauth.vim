" oauth
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc5849.txt

let s:save_cpo = &cpo
set cpo&vim

function! s:nr2byte(nr)
  if a:nr < 0x80
    return nr2char(a:nr)
  elseif a:nr < 0x800
    return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
  else
    return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  endif
endfunction

function! s:nr2enc_char(charcode)
  if &encoding == 'utf-8'
    return nr2char(a:charcode)
  endif
  let char = s:nr2byte(a:charcode)
  if strlen(char) > 1
    let char = strtrans(iconv(char, 'utf-8', &encoding))
  endif
  return char
endfunction

function! s:nr2hex(nr)
  let n = a:nr
  let r = ""
  while n
    let r = '0123456789ABCDEF'[n % 16] . r
    let n = n / 16
  endwhile
  return r
endfunction

function! s:urlencode_char(c)
  let utf = iconv(a:c, &encoding, "utf-8")
  if utf == ""
    let utf = a:c
  endif
  let s = ""
  for i in range(strlen(utf))
    let s .= printf("%%%02X", char2nr(utf[i]))
  endfor
  return s
endfunction

function! s:encodeURI(str)
    return substitute(a:str, '[^a-zA-Z0-9_.~-]', '\=s:urlencode_char(submatch(0))', 'g')
endfunction

function! s:encodeURIComponent(instr)
  let instr = iconv(a:instr, &enc, "utf-8")
  let len = strlen(instr)
  let i = 0
  let outstr = ''
  while i < len
    let ch = instr[i]
    if ch =~# '[0-9A-Za-z-._~!''()*]'
      let outstr .= ch
    elseif ch == ' '
      let outstr .= '+'
    else
      let outstr .= '%' . substitute('0' . s:nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
    endif
    let i = i + 1
  endwhile
  return outstr
endfunction

function! s:item2query(items, sep)
  let ret = ''
  if type(a:items) == 4
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= a:sep | endif
      let ret .= key . "=" . s:encodeURI(a:items[key])
    endfor
  elseif type(a:items) == 3
    for item in sort(a:items)
      if strlen(ret) | let ret .= a:sep | endif
      let ret .= item
    endfor
  else
    let ret = a:items
  endif
  return ret
endfunction

function! s:doHttp(url, getdata, postdata, headdata, returnheader)
  let url = a:url
  let getdata = s:item2query(a:getdata, '&')
  let postdata = s:item2query(a:postdata, '&')
  if strlen(getdata)
    let url .= "?" . getdata
  endif
  let command = "curl -L -s -k"
  if a:returnheader
    let command .= " -i"
  endif
  let quote = &shellxquote == '"' ?  "'" : '"'
  for key in keys(a:headdata)
    let command .= " -H " . quote . key . ": " . a:headdata[key] . quote
  endfor
  let command .= " \"" . url . "\""
  if strlen(postdata)
    let file = tempname()
	let g:hoge = postdata
    call writefile([postdata], file)
    let res = system(command . " -d @" . quote.file.quote)
    call delete(file)
  else
    let res = system(command)
  endif
  return res
endfunction

function! oauth#request_token(url, consumer_key, consumer_secret)
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_version"] = "1.0"
  let query_string = "POST&"
  let query_string .= s:encodeURI(a:url)
  let query_string .= "&"
  let query_string .= s:encodeURI(s:item2query(query, "&"))
  let hmacsha1 = hmac#sha1(a:consumer_secret . "&", query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let res = s:doHttp(a:url, {}, query, {}, 0)
  let request_token = substitute(filter(split(res, "&"), "v:val =~ '^oauth_token='")[0], '^[^=]*=', '', '')
  let request_token_secret = substitute(filter(split(res, "&"), "v:val =~ '^oauth_token_secret='")[0], '^[^=]*=', '', '')
  return [request_token, request_token_secret]
endfunction

function! oauth#access_token(url, consumer_key, consumer_secret, request_token, request_token_secret, params)
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:request_token
  let query["oauth_token_secret"] = a:request_token_secret
  for key in keys(a:params)
    let query[key] = a:params[key]
  endfor
  let query["oauth_version"] = "1.0"
  let query_string = "POST&"
  let query_string .= s:encodeURI(a:url)
  let query_string .= "&"
  let query_string .= s:encodeURI(s:item2query(query, "&"))
  let hmacsha1 = hmac#sha1(a:consumer_secret . "&", query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let res = s:doHttp(a:url, {}, query, {}, 0)
  let request_token = substitute(filter(split(res, "&"), "v:val =~ '^oauth_token='")[0], '^[^=]*=', '', '')
  let request_token_secret = substitute(filter(split(res, "&"), "v:val =~ '^oauth_token_secret='")[0], '^[^=]*=', '', '')
  return [request_token, request_token_secret]
endfunction

function! oauth#sendData(url, consumer_key, consumer_secret, access_token, access_token_secret, params)
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_access_token"] = a:access_token
  let query["oauth_version"] = "1.0"
  for key in keys(a:params)
    let query[key] = a:params[key]
  endfor
  let query_string = "POST&"
  let query_string .= s:encodeURI(a:url)
  let query_string .= "&"
  let query_string .= s:encodeURI(s:item2query(query, "&"))
  let hmacsha1 = hmac#sha1(a:consumer_secret . "&" . a:access_token_secret, query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let res = s:doHttp(a:url, {}, query, {}, 0)
  return res
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
