"""Generate wholly original procedural cave texture and underwater SFX.
Run on a development computer: pip install numpy scipy pillow; ffmpeg must be on PATH.
The generated .png/.ogg files are INCLUDED in the project; running this is optional.
"""
from pathlib import Path
import subprocess, wave
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter
from scipy.signal import butter, sosfilt

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / 'assets'
AUDIO = ASSET / 'audio'
AUDIO.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(20261109)
FS = 22050

def smooth(x: np.ndarray, hz: float) -> np.ndarray:
    return sosfilt(butter(3, hz, fs=FS, output='sos'), x)

def normalize(x: np.ndarray, peak: float=0.79) -> np.ndarray:
    m = max(1e-6, np.max(np.abs(x)))
    return (x / m * peak).astype(np.float32)

def render(name: str, signal: np.ndarray, *, loop: bool=False) -> None:
    signal = np.asarray(signal, dtype=np.float64)
    # Small fades keep looping streams and one shots free of abrupt clicks.
    n = min(800, len(signal)//8)
    signal[:n] *= np.linspace(0, 1, n)
    signal[-n:] *= np.linspace(1, 0, n)
    temp = AUDIO / (name + '.wav')
    with wave.open(str(temp), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
        w.writeframes((normalize(signal) * 32767).astype('<i2').tobytes())
    target = AUDIO / (name + '.ogg')
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(temp),
                    '-c:a','libvorbis','-qscale:a','3',str(target)],check=True)
    temp.unlink()
    print(name, target.stat().st_size, 'bytes', '(loop)' if loop else '')

# Tileable, wet limestone texture: large dissolution patches, small grain, strata, micro-fissures.
size = 512
g = np.random.default_rng(9177)
base = g.standard_normal((size,size))
large = gaussian_filter(base, 37, mode='wrap')
medium = gaussian_filter(base, 12, mode='wrap')
fine = gaussian_filter(base, 2.3, mode='wrap')
grain = gaussian_filter(base, 0.7, mode='wrap')
def scale(x):
    return (x - x.mean()) / (x.std() + 1e-9)
Y, X = np.mgrid[0:size, 0:size]
strata = np.sin((Y + 16 * scale(large)) / 11.0) * 0.052
marble = 0.47 + 0.09*scale(large) + 0.07*scale(medium) + 0.045*scale(fine) + 0.018*scale(grain) + strata
# Fine hairline mineral seams, muted to avoid stylized bright cracks.
vein = np.sin((X*0.035 + Y*0.075 + medium * 110))
marble += (vein > 0.94) * -0.045
marble = np.clip(marble, 0.18, 0.77)
rock = np.dstack([marble*0.90, marble*0.98, marble*0.96])
Image.fromarray((np.clip(rock,0,1)*255).astype('uint8'),'RGB').save(ASSET/'rock_limestone.png',optimize=True)
# Tangent space normal (RG gradient, blue up), using wrapped texture height.
h = gaussian_filter(marble, 1.0, mode='wrap')
dy, dx = np.gradient(h)
nx = -dx * 5.2; ny=-dy * 5.2; nz=np.ones_like(nx)
norm=np.sqrt(nx*nx+ny*ny+nz*nz)
normal = np.dstack([(nx/norm+1)*0.5, (ny/norm+1)*0.5, (nz/norm+1)*0.5])
Image.fromarray((np.clip(normal,0,1)*255).astype('uint8'),'RGB').save(ASSET/'rock_normal.png',optimize=True)

# Underwater low-frequency flow, pressure hum and faint distant rock creaks.
t=np.arange(FS*12)/FS
noise=RNG.standard_normal(len(t))
under = smooth(noise, 85) * (0.7 + 0.2*np.sin(t*1.35))
under += smooth(RNG.standard_normal(len(t)), 370) * .10
under += .16*np.sin(2*np.pi*53*t + 0.45*np.sin(2*np.pi*.10*t))
under *= (0.93 + 0.07*np.sin(2*np.pi*t/12))
render('underwater_ambience', under, loop=True)

# One 6-second regulator breath: filtered inhalation, brief valve rasp, long exhalation.
t=np.arange(FS*6)/FS
raw=RNG.standard_normal(len(t))
air = smooth(raw, 1700) - smooth(raw, 95)
low = smooth(RNG.standard_normal(len(t)), 500)
def breath_env(t, st, pk, en):
    return np.where((t>st)&(t<pk),np.minimum(1,(t-st)/(pk-st)),np.where((t>=pk)&(t<en),np.maximum(0,1-(t-pk)/(en-pk)),0))
inhale=breath_env(t,.45,1.38,2.55)
exhale=breath_env(t,3.05,3.75,5.50)
breath=air*(0.65*inhale + 0.86*exhale)+low*(0.14*inhale+0.18*exhale)
# Brief regulator valve click before inhale; intentionally subtle.
breath += np.sin(2*np.pi*1250*t)*np.exp(-np.maximum(0,t-.4)*58) * ((t>=.4)&(t<.48)) * 0.08
render('regulator_breath', breath, loop=True)

# Fizzy carbon dioxide bubbles: multiple soft resonant glugs; no harsh sonar effect.
t=np.arange(int(FS*1.55))/FS
bubbles=np.zeros_like(t)
for _ in range(31):
    start=RNG.uniform(.06,1.42)
    duration=RNG.uniform(.035,.16)
    freq=RNG.uniform(175,820)
    offset=int(start*FS); length=min(int(duration*FS),len(t)-offset)
    tt=np.arange(length)/FS
    env=np.sin(np.pi*np.minimum(1,tt/duration))**2 * np.exp(-tt*12)
    chirp=np.sin(2*np.pi*(freq*tt+25*tt*tt))
    bubbles[offset:offset+length] += chirp*env*RNG.uniform(.16,.52)
bubbles += smooth(RNG.standard_normal(len(t)),950)*.04*np.sin(np.pi*t/1.55)**2
render('bubbles_release', bubbles)

# Gentle fin kick through water.
t=np.arange(int(FS*1.2))/FS
swish=(smooth(RNG.standard_normal(len(t)),1850)-smooth(RNG.standard_normal(len(t)),190))
env=np.clip(t/.18,0,1)*np.clip((1.2-t)/.84,0,1)
swish=swish*env*(0.4+0.3*np.sin(2*np.pi*t*1.2))
render('fin_swoosh', swish)

# Quiet survey beacon found ping.
t=np.arange(FS*1)/FS
beacon=(np.sin(2*np.pi*610*t)+.26*np.sin(2*np.pi*1220*t))*np.exp(-t*4.4)
render('survey_ping', beacon)
print('Texture sizes:',*(f'{n}: {(ASSET/n).stat().st_size}B' for n in ('rock_limestone.png','rock_normal.png')))
