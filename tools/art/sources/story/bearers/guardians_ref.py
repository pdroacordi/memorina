import sys
from PIL import Image
root=sys.argv[1]; out=sys.argv[2]
fw={"bloom":128,"frost":192,"autumn":128,"summer":192}
tiles=[]
for n in ["bloom","frost","autumn","summer"]:
    im=Image.open(f"{root}/assets/sprites/characters/guardians/{n}_guardian/{n}_guardian_restored.png").convert("RGBA")
    f=im.crop((0,0,fw[n],im.height)); f=f.crop(f.getbbox())
    tiles.append(f.resize((f.width*6,f.height*6),Image.NEAREST))
W=sum(t.width for t in tiles)+60*5; H=max(t.height for t in tiles)+120
sheet=Image.new("RGBA",(W,H),(255,0,255,255)); x=60
for t in tiles:
    sheet.alpha_composite(t,(x,H-60-t.height)); x+=t.width+60
sheet.convert("RGB").save(out)
