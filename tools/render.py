#!/usr/bin/env python3
"""Renderuje kilka klatek gry do PNG (bez PICO-8) - podglad grafiki i swiatla.
Tekst rysowany jest jako szare kreski (brak fontu). Uzycie: python3 tools/render.py OUTDIR"""
import os
import random
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build  # noqa: E402
import check  # noqa: E402

PAL = ["000000", "1d2b53", "7e2553", "008751", "ab5236", "5f574f", "c2c3c7", "fff1e8",
       "ff004d", "ffa300", "ffec27", "00e436", "29adff", "83769c", "ff77a8", "ffccaa"]

DRAW = r"""
FB={} CX,CY=0,0 DP={} TR={}
for i=0,15 do DP[i]=i TR[i]=false end TR[0]=true
local function ps(x,y,c) x=math.floor(x-CX) y=math.floor(y-CY)
 if x>=0 and y>=0 and x<128 and y<128 then FB[x+y*128]=DP[c] end end
function cls() for i=0,128*128-1 do FB[i]=0 end end
function camera(x,y) CX,CY=x or 0,y or 0 end
function pal(a,b) if a==nil then for i=0,15 do DP[i]=i end
 elseif type(a)=="table" then for i=0,15 do DP[i]=a[i] end else DP[a]=b end end
function sspr(sx,sy,sw,sh,dx,dy,dw,dh,fx)
 dw=dw or sw dh=dh or sh
 for y=0,dh-1 do for x=0,dw-1 do
  local u=math.floor(x*sw/dw) if fx then u=sw-1-u end
  local c=GFX[(sy+math.floor(y*sh/dh))*128+sx+u]
  if not TR[c] then ps(dx+x,dy+y,c) end end end end
function spr(n,x,y,w,h,fx) sspr(n%16*8,math.floor(n/16)*8,8,8,x,y,8,8,fx) end
function pset(x,y,c) ps(x,y,c) end
function rectfill(a,b,c,d,col) for y=math.min(b,d),math.max(b,d) do for x=math.min(a,c),math.max(a,c) do ps(x,y,col) end end end
function rect(a,b,c,d,col) for x=a,c do ps(x,b,col) ps(x,d,col) end for y=b,d do ps(a,y,col) ps(c,y,col) end end
function circfill(x,y,r,c) for j=-r,r do for i=-r,r do if i*i+j*j<=r*r+r then ps(x+i,y+j,c) end end end end
function line(a,b,c,d,col) local n=math.max(math.abs(c-a),math.abs(d-b),1)
 for i=0,n do ps(a+(c-a)*i/n,b+(d-b)*i/n,col) end end
function print(s,x,y,c) s=tostring(s) for i=1,#s do if s:sub(i,i)~=" " then rectfill(x+(i-1)*4,y+1,x+(i-1)*4+2,y+3,c) end end end
"""


def png(path, fb, scale=3):
    rows = []
    for y in range(128 * scale):
        r = b"\x00"
        for x in range(128):
            c = bytes.fromhex(PAL[fb[(y // scale) * 128 + x] or 0])
            r += c * scale
        rows.append(r)
    raw = b"".join(rows)

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    w = h = 128 * scale
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(data)


def main(out):
    import lupa
    os.makedirs(out, exist_ok=True)
    random.seed(3)
    L = lupa.LuaRuntime(unpack_returned_tuples=True)
    L.execute(check.STUBS)
    g = L.globals()
    for k, v in build.FLAGS.items():
        g.flags[k] = v
    gfx = build.gfx().replace("\n", "")
    t = L.table()
    for i, ch in enumerate(gfx):
        t[i] = int(ch, 16)
    g.GFX = t
    L.execute(DRAW)
    L.execute(check.SRC)
    g._init()
    for i in range(20):
        g._update()
    g._draw()

    def snap(name):
        fb = [g.FB[i] for i in range(128 * 128)]
        png(os.path.join(out, name + ".png"), fb)

    snap("title")
    g.math.randomseed(7)
    g.BTNP[4] = True
    g._update()
    g.BTNP[4] = False
    g._draw()
    snap("intro")
    for d in range(1, 6):
        g.dep = d
        g.nextlvl()
        g.tm = -1
        g._update()
        for f in range(150):
            g.BTN[1] = f % 60 < 40
            g.BTN[3] = f % 90 > 60
            g.hp = 5
            g._update()
            g._draw()
        snap("glebokosc%d" % d)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "shots")
