#!/usr/bin/env python3
"""Sprawdzanie kartridza bez PICO-8:
 1) przyblizone liczenie tokenow (limit 8192) i znakow (limit 65535),
 2) symulacja gry w Lua (lupa) z zaslepkami API PICO-8 i losowym wejsciem.
Uzycie: python3 tools/check.py [liczba_gier]"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = open(os.path.join(ROOT, "src", "szczurolap.lua")).read()

TOK = re.compile(r"""--\[\[.*?\]\]|--[^\n]*|\[\[.*?\]\]|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|
    0x[0-9a-fA-F.]+|\d*\.?\d+|[A-Za-z_]\w*|\.\.\.|\.\.|==|~=|!=|<=|>=|\S""", re.S | re.X)
FREE = {",", ".", ":", ";", ")", "]", "}", "end", "local"}


def count_tokens(src):
    n, prev = 0, None
    for m in TOK.finditer(src):
        t = m.group(0)
        if t.startswith("--") or t in FREE:
            continue
        # minus przed liczba po operatorze/nawiasie liczy sie z liczba
        if re.match(r"\d|\.\d", t) and prev == "-u":
            prev = t
            continue
        if t == "-" and (prev is None or prev in "=(,{[" or prev in
                         ("return", "and", "or", "not", "then", "do", "<", ">", "+", "*", "/")):
            n += 1
            prev = "-u"
            continue
        n += 1
        prev = t
    return n


STUBS = r"""
local R=math.random
local mp={}
flags={}
function mget(x,y) x=math.floor(x) y=math.floor(y)
 if x<0 or y<0 or x>127 or y>63 then return 0 end
 return mp[x+y*128] or 0 end
function mset(x,y,v) mp[math.floor(x)+math.floor(y)*128]=v end
function fget(n,f) local v=flags[n] or 0 return (v>>f)&1==1 end
function flr(x) return math.floor(x) end
function sqrt(x) assert(x>=0,"sqrt<0") return math.sqrt(x) end
function abs(x) return math.abs(x) end
function min(a,b) return math.min(a,b) end
function max(a,b) return math.max(a,b) end
function mid(a,b,c) if a>b then a,b=b,a end if b>c then b=c end if a>b then b=a end return b end
function sgn(x) return x<0 and -1 or 1 end
function rnd(x) if type(x)=="table" then return x[R(#x)] end return R()*(x or 1) end
function cos(a) return math.cos(a*2*math.pi) end
function sin(a) return -math.sin(a*2*math.pi) end
function atan2(x,y) return (math.atan(-y,x)/(2*math.pi))%1 end
function add(t,v) t[#t+1]=v return v end
function del(t,v) for i=1,#t do if t[i]==v then table.remove(t,i) return v end end end
function all(t) local c={} for i=1,#t do c[i]=t[i] end local i=0
 return function() i=i+1 return c[i] end end
function sub(s,i,j) return string.sub(s,i,j) end
function tonum(s) return tonumber(s) end
function split(s,sep,conv) sep=sep or "," local r={}
 for p in (s..sep):gmatch("(.-)"..sep:gsub("%p","%%%0")) do
  local q=p if conv~=false and tonumber(p) then q=tonumber(p) end r[#r+1]=q end
 return r end
local dd={}
function cartdata() end function dget(i) return dd[i] or 0 end function dset(i,v) dd[i]=v end
function stat(n) if n==28 then return false end return 0 end function poke() end
function sfx() end function music() end function cls() end function camera() end
function pal(a,b) if type(a)=="table" then for c=0,15 do assert(a[c],"pal tbl "..c) end
 elseif a~=nil then assert(type(a)=="number" and type(b)=="number","pal args") end end
function spr(n,x,y) assert(type(n)=="number" and x==x and y==y,"spr") end
function sspr(...) for _,v in ipairs({...}) do if type(v)=="number" then assert(v==v,"sspr nan") end end end
function print(s,x,y,c) assert(type(s)=="string" or type(s)=="number","print") end
function pset() end function line() end function rect() end function rectfill() end function circfill() end
BTN={} BTNP={}
function btn(i,p) return BTN[(p or 0)*8+i] or false end
function btnp(i,p) return BTNP[(p or 0)*8+i] or false end
"""


def simulate(games):
    import lupa
    L = lupa.LuaRuntime(unpack_returned_tuples=True)
    L.execute(STUBS)
    flags = L.globals().flags
    for k, v in {4: 1, 5: 1, 9: 1, 10: 1, 11: 1, 6: 2}.items():
        flags[k] = v
    L.execute(SRC)
    g = L.globals()
    import random
    g._init()
    stats = {"levels": 0, "deaths": 0, "wins": 0, "frames": 0}
    for game in range(games):
        if game % 3 == 1:  # przelacz jezyk i trudnosc w menu
            for b in (3, 3, 3):
                g.BTNP[b] = True; g._update(); g._draw(); g.BTNP[b] = False
                g.BTNP[4] = True; g._update(); g._draw(); g.BTNP[4] = False
            for _ in range(20):
                g._update(); g._draw()
            assert g.st == "test", g.st
            g.BTN[4] = g.BTN[5] = True
            g._update(); g._draw()
            g.BTN[4] = g.BTN[5] = False
            for _ in range(20):
                g._update()
            g.mi = 1
        g.BTNP[4] = True
        g._update(); g._draw()
        g.BTNP[4] = False
        assert g.st == "intro", g.st
        held = {}
        for f in range(6000):
            # losowe wejscie gracz 1 i 2
            if f % 15 == 0:
                for i in range(4):
                    g.BTN[i] = random.random() < .3
                    g.BTN[8 + i] = random.random() < .05
                g.BTN[5] = random.random() < .25   # krotkie/dlugie X: tryb psa / wycie
                g.BTN[13] = random.random() < .05  # X gracza 2: wycie
            for i in (4, 5, 12, 13):
                g.BTNP[i] = random.random() < (.2 if i == 4 else .02)
            g.hp = max(g.hp, 2) if game % 2 == 0 else g.hp  # co druga gra niesmiertelny
            g._update(); g._draw()
            stats["frames"] += 1
            if g.st == "play" and f % 700 == 699:
                # wymus postep: zniszcz gniazda i wejdz na wlaz / zabij krola
                for e in list(g.ents.values()):
                    if e.k == 0 or e.k == 6:
                        g.hurt(e, 99, 0)
                if g.st == "play" and g.ox:
                    g.pl.x, g.pl.y = g.ox * 8 + 4, g.oy * 8 + 4
                    stats["levels"] += 1
            if g.st in ("dead", "win"):
                stats["deaths" if g.st == "dead" else "wins"] += 1
                for _ in range(80):
                    g._update()
                g.BTNP[4] = True
                g._update(); g._draw()
                g.BTNP[4] = False
                break
        g.st = "title"
        g.tm = -1
    stats["lang"], stats["easy"] = g.lang, g.ez
    return stats


if __name__ == "__main__":
    n = count_tokens(SRC)
    print("tokeny ~%d / 8192, znaki %d / 65535" % (n, len(SRC)))
    print(simulate(int(sys.argv[1]) if len(sys.argv) > 1 else 6))
