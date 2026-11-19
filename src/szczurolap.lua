-- szczurolap
-- podziemia wielkiego miasta

function ht(s)
 local t={}
 for i=0,15 do t[i]=tonum("0x"..sub(s,i+1,i+1)) end
 return t
end

function _init()
 cartdata("szczurolap_1")
 lt={}
 local s=split("0000001101100101,0000101512410112,0011215624931524,0123456789abcdef",",",false)
 for i=1,4 do lt[i-1]=ht(s[i]) end
 th=split("0123456789abcdef,0123356789abcdef,012324f789abcdef,0123428789abcdef,012312d789abcdef",",",false)
 dn=split("piwnice,kanaly,jaskinie przemytnikow,tunele szczuroludzi,czelusci")
 hints=split("zniszcz gniazda i otworz wlaz|woda spowalnia, szczury zarazone|ciemne groty: oszczedzaj olej|szczuroludzie rzucaja strzalki|pokonaj szczurzego krola!","|",false)
 -- pokoje,rozmiar,erozja,woda,gniazda,zakamarki,kaganki,szczury
 prm={split"9,6,0,0,2,3,.6,1",split"9,6,0,1,2,4,.45,1",split"8,7,250,0,3,4,.35,2",split"12,4,60,0,3,6,.25,2",split"8,7,400,0,3,5,.2,2"}
 -- hp,predkosc,kolor,skala
 ek={split"1,.7,4,1",split"1,.9,3,1",split"3,.55,2,1.5",split"2,1.1,5,1",split"4,.6,4,1",split"30,.45,2,2"}
 pools={split"1",split"1,1,2",split"1,2,3",split"2,3,5",split"2,3,5,5"}
 nb=split"1,-1,64,-64"
 st,fr,msgt,tm="title",0,0,0
 music(0,0,3)
end

-- narzedzia

function dst(a,b)
 local dx,dy=(a.x-b.x)/8,(a.y-b.y)/8
 return sqrt(dx*dx+dy*dy)
end

function norm(x,y)
 local a=atan2(x,y)
 return cos(a),sin(a)
end

function sol(x,y)
 return fget(mget(x,y),0)
end

function wet(e)
 return fget(mget(e.x/8,e.y/8),1)
end

function hit(x,y,r)
 return sol((x-r)/8,(y-r)/8) or sol((x+r)/8,(y-r)/8) or sol((x-r)/8,(y+r)/8) or sol((x+r)/8,(y+r)/8)
end

function mv(e,dx,dy)
 if not hit(e.x+dx,e.y,3) then e.x=e.x+dx end
 if not hit(e.x,e.y+dy,3) then e.y=e.y+dy end
end

function lat(e)
 return lc[flr(e.x/8)+flr(e.y/8)*64] or 0
end

function say(s)
 msg,msgt=s,75
end

function burst(x,y,c,n)
 for i=1,n do
  add(fx,{x=x,y=y,dx=rnd(2)-1,dy=rnd(2)-1,t=8+rnd(8),c=c})
 end
end

function inp(p)
 local x,y=0,0
 if btn(0,p) then x=-1 end
 if btn(1,p) then x=1 end
 if btn(2,p) then y=-1 end
 if btn(3,p) then y=1 end
 if x~=0 and y~=0 then x,y=x*.71,y*.71 end
 return x,y
end

-- mapa przeplywu (bfs) do gracza
function bfs(sx,sy,m)
 local s=sx+sy*64
 local d,q,h={[s]=0},{s},1
 while q[h] do
  local i=q[h]
  h=h+1
  local v=d[i]
  if v<m then
   for k=1,4 do
    local j=i+nb[k]
    if not d[j] and not sol(j%64,flr(j/64)) then
     d[j]=v+1
     add(q,j)
    end
   end
  end
 end
 return d
end

function dirto(e,tg)
 local i=flr(e.x/8)+flr(e.y/8)*64
 local v=fd[i]
 if tg==pl and v and v>1 then
  for k=1,4 do
   local j=i+nb[k]
   if (fd[j] or 99)<v then return norm(j%64*8+4-e.x,flr(j/64)*8+4-e.y) end
  end
 end
 return norm(tg.x-e.x,tg.y-e.y)
end

-- swiatlo

function addl(tx,ty)
 for x=tx-5,tx+5 do
  for y=ty-4,ty+6 do
   local i,dx,dy=x+y*64,x-tx,y-ty-1
   sl[i]=max(sl[i] or -9,4.5-sqrt(dx*dx+dy*dy))
  end
 end
end

function lv(tx,ty)
 local dx,dy=tx+.5-pl.x/8,ty+.5-pl.y/8
 local v=max(sl[tx+ty*64] or -9,lr-sqrt(dx*dx+dy*dy))
 return v>1.5 and 3 or v>.5 and 2 or v>-.6 and 1 or 0
end

-- generator poziomu

function fl()
 local v=rnd()
 return v<.75 and 1 or v<.93 and 2 or 3
end

function cf(x,y)
 if sol(x,y) then mset(x,y,fl()) end
end

function link(a,b)
 local x,y=a.cx,a.cy
 while x~=b.cx do
  x=x+sgn(b.cx-x)
  cf(x,y)
 end
 while y~=b.cy do
  y=y+sgn(b.cy-y)
  cf(x,y)
 end
end

function rp(r)
 return (r.x+flr(rnd(r.w)))*8+4,(r.y+flr(rnd(r.h)))*8+4
end

function spawn(k,x,y)
 local d=ek[k]
 return add(ents,{k=k,x=x,y=y,hp=d[1],sp=d[2],c=d[3],sz=d[4],f=0,fl=0,cd=30+rnd(60),st=0,wa=rnd(),hid=k==4})
end

function gen()
 local p=prm[dep]
 ents,shots,fx,decs,its,ex,sl,lc,rooms={},{},{},{},{},{},{},{},{}
 ox,nests,shk,lr=nil,0,0,3
 local thm=ht(th[dep])
 tt={}
 for l=0,3 do
  tt[l]={}
  for c=0,15 do tt[l][c]=lt[l][thm[c]] end
 end
 for x=0,63 do
  for y=0,31 do mset(x,y,4) end
 end
 -- pokoje
 for i=1,300 do
  local w,h=3+flr(rnd(p[2])),3+flr(rnd(p[2]*.7))
  local r={x=1+flr(rnd(46-w)),y=2+flr(rnd(29-h)),w=w,h=h}
  local ok=#rooms<p[1]
  for o in all(rooms) do
   if r.x<o.x+o.w+2 and o.x<r.x+w+2 and r.y<o.y+o.h+2 and o.y<r.y+h+2 then ok=false end
  end
  if ok then
   r.cx,r.cy=r.x+flr(w/2),r.y+flr(h/2)
   for x=r.x,r.x+w-1 do
    for y=r.y,r.y+h-1 do mset(x,y,fl()) end
   end
   if #rooms>0 then link(rooms[#rooms],r) end
   add(rooms,r)
   if p[4]>0 and rnd()<.6 then
    for x=r.x,r.x+w-1 do mset(x,r.cy,6) end
   end
  end
 end
 link(rooms[1],rooms[#rooms])
 link(rnd(rooms),rnd(rooms))
 -- erozja (jaskinie)
 for i=1,p[3] do
  local x,y=2+flr(rnd(44)),2+flr(rnd(28))
  if mget(x,y)==4 and (mget(x+1,y)~=4 or mget(x-1,y)~=4 or mget(x,y+1)~=4 or mget(x,y-1)~=4) then mset(x,y,fl()) end
 end
 -- zakamarki
 local al={}
 for i=1,60 do
  local r=rnd(rooms)
  local d=rnd()<.5 and -1 or 1
  local x,y=r.x+flr(rnd(r.w)),d<0 and r.y-1 or r.y+r.h
  local ok=#al<p[6] and y+d*2>0 and y+d*2<31
  for a=-1,1 do
   for b=0,1 do
    if mget(x+a,y+b*d)~=4 then ok=false end
   end
  end
  if ok then
   mset(x,y,fl())
   mset(x,y+d,fl())
   add(al,{x,y+d})
  end
 end
 -- lica scian
 for x=0,47 do
  for y=0,30 do
   if mget(x,y)==4 and not sol(x,y+1) then mset(x,y,5) end
  end
 end
 -- kaganki
 for r in all(rooms) do
  local x=r.x+flr(rnd(r.w))
  if mget(x,r.y-1)==5 then
   if rnd()<p[7] then
    mset(x,r.y-1,10)
    addl(x,r.y-1)
   else
    mset(x,r.y-1,9)
   end
  end
 end
 -- gracz i pies
 local r1=rooms[1]
 pl.x,pl.y=r1.cx*8+4,r1.cy*8+4
 dg.x,dg.y,dg.dn,dg.hp=pl.x+8,pl.y,false,max(dg.hp,2)
 cx,cy=pl.x-64,pl.y-64
 -- wyjscie w najdalszym pokoju
 fd=bfs(r1.cx,r1.cy,999)
 local er,bd=r1,0
 for r in all(rooms) do
  local v=fd[r.cx+r.cy*64] or 0
  if v>bd then er,bd=r,v end
 end
 if dep<5 then
  ox,oy=er.cx,er.cy
  mset(ox,oy,7)
 else
  spawn(6,er.cx*8+4,er.cy*8+4)
 end
 -- szczury
 for r in all(rooms) do
  if r~=r1 then
   for i=1,flr(rnd(p[8]+1)) do spawn(rnd(pools[dep]),rp(r)) end
  end
 end
 for a in all(al) do spawn(4,a[1]*8+4,a[2]*8+4) end
 -- gniazda
 for i=1,p[5] do
  local e=spawn(1,rp(rooms[2+flr(rnd(#rooms-1))]))
  e.k,e.hp,e.cd=0,5+dep,0
  nests=nests+1
 end
 -- przedmioty
 for i=1,5 do
  local x,y=rp(rnd(rooms))
  add(its,{x=x,y=y,t=i<4 and 13 or 14})
 end
end

-- stan gry

function newgame()
 dep,hp,oil,kills,dm,dual=1,5,100,0,false,false
 pl={x=0,y=0,fa=0,iv=0,cd=0,w=0,sw=0}
 dg={hp=4,iv=0,cd=0,bc=0,ex=0,rv=0,w=0}
 nextlvl()
end

function nextlvl()
 gen()
 st,tm="intro",75
 sfx(9)
end

function hitpl()
 if pl.iv<=0 then
  hp=hp-1
  pl.iv,shk=45,6
  sfx(3)
  burst(pl.x,pl.y,8,6)
 end
end

function hurt(e,n,a)
 e.hp=e.hp-n
 e.fl,e.hid,e.ag=4,false,true
 if e.k>0 and e.k<6 then mv(e,cos(a)*4,sin(a)*4) end
 burst(e.x,e.y,e.k==0 and 4 or 8,4)
 sfx(1)
 if e.hp<=0 then
  del(ents,e)
  if e.k==0 then
   nests=nests-1
   shk=8
   sfx(7)
   if nests<=0 and ox then
    mset(ox,oy,8)
    say("wlaz w dol otwarty!")
   else
    say("gniazdo zniszczone!")
   end
  else
   kills=kills+1
   sfx(2)
   add(decs,{x=e.x,y=e.y})
   if rnd()<.08 then add(its,{x=e.x,y=e.y,t=13+flr(rnd(2))}) end
   if e.k==6 then
    st,tm="win",60
    sfx(13)
    best()
   end
  end
 end
end

function best()
 if kills>dget(0) then dset(0,kills) end
end

function _update()
 fr=fr+1
 msgt=msgt-1
 tm=tm-1
 if st=="play" then
  upplay()
 elseif st=="intro" then
  if tm<0 then st="play" end
 elseif tm<0 and (btnp(4) or btnp(5)) then
  if st=="title" then newgame() else st,tm="title",15 end
 end
end

function upplay()
 if btn(0,1) or btn(1,1) or btn(2,1) or btn(3,1) then dual=true end
 if btnp(5) and not dg.dn then
  dm=not dm
  say(dm and "sterujesz psem" or "sterujesz szczurolapem")
 end
 local dx,dy=inp(0)
 local gx,gy=0,0
 if dm then
  if dual then
   gx,gy=inp(1)
  else
   gx,gy,dx,dy=dx,dy,0,0
  end
 end
 -- gracz
 pl.iv=pl.iv-1
 pl.cd=pl.cd-1
 pl.sw=pl.sw-1
 if dx~=0 or dy~=0 then
  pl.fa=atan2(dx,dy)
  if dx~=0 then pl.fl=dx<0 end
  local s=wet(pl) and .6 or 1
  mv(pl,dx*s,dy*s)
  pl.w=pl.w+.25
 end
 if not dm and btnp(4) and pl.cd<=0 then
  pl.cd,pl.sw=10,5
  sfx(0)
  local ax,ay=pl.x+cos(pl.fa)*7,pl.y+sin(pl.fa)*7
  for e in all(ents) do
   if not e.hid and abs(e.x-ax)<5+e.sz*3 and abs(e.y-ay)<5+e.sz*3 then hurt(e,1,pl.fa) end
  end
 end
 -- zapalanie kagankow
 local tx,ty=flr(pl.x/8),flr(pl.y/8)
 for i=-1,1 do
  for j=-1,1 do
   if mget(tx+i,ty+j)==9 and oil>=5 then
    mset(tx+i,ty+j,10)
    addl(tx+i,ty+j)
    oil=oil-5
    sfx(8)
    say("kaganek zapalony")
   end
  end
 end
 -- wlaz
 local m=mget(tx,ty)
 if m==8 then
  dep=dep+1
  nextlvl()
  return
 end
 if m==7 and msgt<0 then say("zniszcz gniazda szczurow: "..nests) end
 -- olej
 if fr%40==0 and oil>0 then oil=oil-1 end
 lr=1.4+oil/30+rnd(.25)
 if fr%8==0 then fd=bfs(tx,ty,18) end
 updog(gx,gy)
 for e in all(ents) do upe(e) end
 for s in all(shots) do
  s.x=s.x+s.dx
  s.y=s.y+s.dy
  s.t=s.t-1
  if s.t<0 or sol(s.x/8,s.y/8) then
   del(shots,s)
  elseif dst(s,pl)<.6 then
   hitpl()
   del(shots,s)
  end
 end
 for it in all(its) do
  if dst(it,pl)<.8 then
   if it.t==13 then
    oil=min(100,oil+40)
    say("olej do latarni")
   else
    hp=min(5,hp+2)
    dg.hp=min(4,dg.hp+2)
    say("mieso! zdrowie wraca")
   end
   sfx(4)
   del(its,it)
  end
 end
 for p in all(fx) do
  p.x=p.x+p.dx
  p.y=p.y+p.dy
  p.t=p.t-1
  if p.t<0 then del(fx,p) end
 end
 shk=max(shk-1,0)
 if hp<=0 then
  st,tm="dead",45
  sfx(12)
  best()
 end
end

function updog(gx,gy)
 dg.iv=dg.iv-1
 dg.cd=dg.cd-1
 dg.bc=dg.bc-1
 dg.ex=dg.ex-1
 if dg.dn then
  if dst(dg,pl)<1.3 then
   dg.rv=dg.rv+1
   if dg.rv>60 then
    dg.dn,dg.hp,dg.rv=false,2,0
    sfx(4)
    say("piesek wstaje!")
   end
  else
   dg.rv=0
  end
  return
 end
 local mx,my,s=0,0,1.3
 if dm then
  mx,my=gx,gy
 else
  local b,bd=nil,5
  for e in all(ents) do
   if e.k>0 and not e.hid then
    local d=dst(e,dg)
    if d<bd and dst(e,pl)<6 then b,bd=e,d end
   end
  end
  if b then
   mx,my=norm(b.x-dg.x,b.y-dg.y)
  elseif dst(dg,pl)>1.6 then
   mx,my=dirto(dg,pl)
   if dst(dg,pl)>4 then s=1.8 end
  end
  if dst(dg,pl)>12 then dg.x,dg.y=pl.x,pl.y end
 end
 if mx~=0 or my~=0 then
  local qx,qy,w=dg.x,dg.y,wet(dg) and .6 or 1
  mv(dg,mx*s*w,my*s*w)
  if dst(dg,pl)>7 then dg.x,dg.y=qx,qy end
  dg.w=dg.w+.3
  if mx~=0 then dg.fl=mx<0 end
 end
 -- ugryzienie
 if dg.cd<=0 then
  for e in all(ents) do
   if not e.hid and dst(e,dg)<.5+e.sz*.4 then
    hurt(e,1,atan2(e.x-dg.x,e.y-dg.y))
    dg.cd=18
    sfx(11)
    break
   end
  end
 end
 -- wech
 for e in all(ents) do
  if e.hid and dst(e,dg)<3.5 then
   e.hid,dg.ex=false,30
   sfx(5)
   say("piesek cos wyczul!")
  end
 end
 -- szczekniecie
 if dg.bc<=0 and (btnp(4,1) or btnp(5,1) or dm and btnp(4)) then
  dg.bc,dg.ex=45,20
  sfx(5)
  for e in all(ents) do
   local d=dst(e,dg)
   if e.k>0 and d<6 then
    e.hid=false
    if d<3 and e.k<6 then e.st=50 end
   end
  end
 end
end

function upe(e)
 e.fl=e.fl-1
 e.cd=e.cd-1
 local d=dst(e,pl)
 -- gniazdo: fale
 if e.k==0 then
  if e.cd<=0 and d<7 then
   e.cd=300-dep*30
   for i=1,2+dep do
    local x,y=e.x+rnd(10)-5,e.y+rnd(10)-5
    if hit(x,y,3) then x,y=e.x,e.y end
    spawn(rnd(pools[dep]),x,y).ag=true
   end
   sfx(6)
   say("fala szczurow!")
  end
  return
 end
 local tx,ty=flr(e.x/8),flr(e.y/8)
 local l=lat(e)
 if e.hid then
  if d<1.6 or l>2 then
   e.hid,e.ag=false,true
   sfx(2)
  end
  return
 end
 if e.st>0 then
  e.st=e.st-1
  return
 end
 local tg=pl
 if not dg.dn and dst(e,dg)<d then tg=dg end
 if dst(e,tg)<(l>1 and 8 or 4) then e.ag=true end
 -- szczury boja sie kagankow
 local s=e.sp*((sl[tx+ty*64] or 0)>1 and e.k<6 and .5 or 1)
 local mx,my
 if e.ag then
  mx,my=dirto(e,tg)
 else
  if rnd()<.03 then e.wa=rnd() end
  mx,my=cos(e.wa)*.4,sin(e.wa)*.4
 end
 mv(e,mx*s,my*s)
 e.f=e.f+s*.2
 if mx~=0 then e.fx=mx<0 end
 -- szczuroczlek rzuca strzalki
 if e.k==5 and e.cd<=0 and d<6 and l>0 then
  local a=atan2(pl.x-e.x,pl.y-e.y)
  add(shots,{x=e.x,y=e.y,dx=cos(a)*2,dy=sin(a)*2,t=60})
  e.cd=80
  sfx(10)
 end
 -- krol przyzywa
 if e.k==6 and e.cd<=0 then
  e.cd=150
  for i=1,3 do spawn(rnd(pools[2]),e.x,e.y).ag=true end
  sfx(6)
 end
 -- kontakt
 local r=.45+e.sz*.3
 if d<r then
  hitpl()
  mv(e,-mx*4,-my*4)
 end
 if not dg.dn and dst(e,dg)<r and dg.iv<=0 then
  dg.hp=dg.hp-1
  dg.iv=45
  sfx(3)
  if dg.hp<=0 then
   dg.dn,dm=true,false
   say("piesek ranny! stan przy nim")
  end
 end
end

-- rysowanie

function _draw()
 if st=="play" then
  drplay()
 elseif st=="title" then
  drtitle()
 elseif st=="intro" then
  drintro()
 else
  drend()
 end
end

function ctr(s,y,c)
 print(s,64-#s*2,y,c)
end

function drtitle()
 cls()
 print("\6w\6tszczurolap",24,14,9)
 ctr("podziemia wielkiego miasta",30,5)
 local x,a=fr*1.5%200-40,flr(fr/4)%2
 spr(16+a,x,46)
 spr(18+a,x-12,46)
 for i=1,3 do spr(21+a,x-14-i*10,46) end
 print("ruch: analog / krzyzak",8,62,6)
 print("o: cios palka   x: tryb psa",8,70,6)
 print("tryb psa: o = szczekniecie",8,78,6)
 print("2. analog (gracz 2): pies",8,86,6)
 ctr("rekord: "..dget(0).." szczurow",98,13)
 if fr%30<20 then ctr("nacisnij o aby zaczac",112,7) end
end

function drintro()
 cls()
 ctr("glebokosc "..dep.."/5",44,5)
 ctr(dn[dep],56,9)
 ctr(hints[dep],72,6)
end

function drend()
 cls()
 local w=st=="win"
 ctr(w and "szczurzy krol pokonany!" or "szczurolap zginal...",40,w and 10 or 8)
 ctr(dn[dep],56,6)
 ctr("ubite szczury: "..kills,66,6)
 ctr("rekord: "..dget(0),76,13)
 if tm<0 and fr%30<20 then ctr("nacisnij o",100,7) end
end

function drplay()
 cls()
 local qx,qy=pl.x,pl.y
 if dm then
  if dual then
   qx,qy=(pl.x+dg.x)/2,(pl.y+dg.y)/2
  else
   qx,qy=dg.x,dg.y
  end
 end
 cx=mid(0,cx+(qx-64-cx)*.25,256)
 cy=mid(-8,cy+(qy-68-cy)*.25,128)
 camera(flr(cx+rnd(shk)-shk/2),flr(cy+rnd(shk)-shk/2))
 -- mapa ze swiatlem
 lc={}
 local x0,y0=flr(cx/8),flr(cy/8)
 for ty=y0,y0+16 do
  for tx=x0,x0+16 do
   local i,l=tx+ty*64,lv(tx,ty)
   lc[i]=l
   if l>0 then ex[i]=true end
   if ex[i] then
    local m=mget(tx,ty)
    if m==10 and fr%10<5 then m=11 end
    pal(tt[l])
    spr(m,tx*8,ty*8,1,1,m==6 and fr%20<10)
   end
  end
 end
 for d in all(decs) do
  local l=lat(d)
  if l>0 then
   pal(lt[l])
   circfill(d.x,d.y,1,8)
  end
 end
 for it in all(its) do
  local l=lat(it)
  if l>0 then
   pal(lt[l])
   spr(it.t,it.x-4,it.y-5+sin(fr/30))
  end
 end
 -- wrogowie
 for e in all(ents) do
  local l=lat(e)
  pal(lt[l])
  if e.hid then
   if fr%60<3 then
    pal()
    pset(e.x-1,e.y,8)
    pset(e.x+1,e.y,8)
   end
  elseif l>0 then
   if e.k==0 then
    spr(12,e.x-4,e.y-4)
   else
    pal(4,e.fl>0 and 7 or lt[l][e.c])
    local s,z=(e.k==5 and 23 or 21)+flr(e.f)%2,8*e.sz
    sspr(s%16*8,flr(s/16)*8,8,8,e.x-z/2,e.y-z/2,z,z,e.fx)
    if e.k==6 then
     pal(lt[l])
     spr(25,e.x-4,e.y-z/2-5)
    end
   end
  elseif e.k>0 then
   pal()
   pset(e.x+(e.fx and -2 or 2),e.y-1,8)
  end
 end
 -- pies
 pal(lt[max(lat(dg),1)])
 spr(dg.dn and 20 or 18+flr(dg.w)%2,dg.x-4,dg.y-5,1,1,dg.fl)
 pal()
 if dg.ex>0 then print("!",dg.x-1,dg.y-13,10) end
 if dm and fr%30<20 then print("v",dg.x-1,dg.y-13,11) end
 if dg.dn and dg.rv>0 then rectfill(dg.x-4,dg.y-9,dg.x-4+dg.rv/7.5,dg.y-8,11) end
 -- gracz
 if pl.iv<=0 or fr%4<2 then spr(16+flr(pl.w)%2,pl.x-4,pl.y-6,1,1,pl.fl) end
 if pl.sw>0 then
  for a=-.12,.12,.04 do pset(pl.x+cos(pl.fa+a)*8,pl.y-1+sin(pl.fa+a)*8,7) end
 end
 for s in all(shots) do line(s.x,s.y,s.x-s.dx*2,s.y-s.dy*2,6) end
 for p in all(fx) do pset(p.x,p.y,p.c) end
 -- strzalka do wlazu
 if ox and nests<=0 and fr%20<14 then
  local a=atan2(ox*8+4-pl.x,oy*8+4-pl.y)
  circfill(pl.x+cos(a)*14,pl.y-2+sin(a)*14,1,10)
 end
 -- hud
 camera()
 rectfill(0,0,127,7,0)
 for i=1,5 do
  if i>hp then pal(8,1) end
  spr(15,i*7-7,0)
 end
 pal()
 spr(18,37,0)
 print(dg.dn and "x" or dg.hp,46,2,dm and 11 or 9)
 spr(13,52,0)
 rect(60,2,91,5,5)
 if oil>0 then rectfill(61,3,61+oil*.29,4,oil<20 and 8 or 9) end
 spr(12,95,0)
 print(nests,104,2,7)
 print(dep.."/5",113,2,6)
 if msgt>0 then
  rectfill(0,120,127,127,0)
  ctr(msg,121,7)
 end
end
