import math
import os
import struct
import wave

os.makedirs("assets/sounds", exist_ok=True)


def write_tone(path: str, freq: float, duration: float = 0.35, vol: float = 0.4) -> None:
    sr = 44100
    n = int(sr * duration)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        frames = bytearray()
        for i in range(n):
            t = i / sr
            env = 1.0
            if t > duration * 0.7:
                env = max(0.0, 1.0 - (t - duration * 0.7) / (duration * 0.3))
            val = int(vol * 32767 * env * math.sin(2 * math.pi * freq * t))
            frames.extend(struct.pack("<h", val))
        w.writeframes(frames)


write_tone("assets/sounds/chime1.wav", 880)
write_tone("assets/sounds/chime2.wav", 1320, duration=0.45)

path = "assets/sounds/buzz.wav"
sr = 44100
duration = 0.5
n = int(sr * duration)
with wave.open(path, "w") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sr)
    frames = bytearray()
    for i in range(n):
        t = i / sr
        pulse = 1.0 if (t * 8) % 2 < 1 else 0.2
        val = int(0.35 * 32767 * pulse * math.sin(2 * math.pi * 220 * t))
        frames.extend(struct.pack("<h", val))
    w.writeframes(frames)

print("generated:", os.listdir("assets/sounds"))
