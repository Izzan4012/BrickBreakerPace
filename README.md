# Brick Breaker

Game Brick Breaker bergaya neon yang dibuat dengan **Godot 4.7**.
Hancurkan semua brick dengan bola, dan jaga agar bola tidak jatuh melewati paddle.

## Cara main

| Aksi | Kontrol |
|---|---|
| Mulai dari splash | Tap / klik / tombol apa saja |
| Gerakkan paddle | Mouse, geser jari, A-D, atau panah kiri-kanan |
| Luncurkan bola | Klik / tap / Spasi |
| Jeda | P / Esc, atau tombol PAUSE |

## Fitur

- Splash screen video dengan "Tap to Start"
- 5 level (1-1 sampai 1-5); setelah itu level berulang dengan bola lebih cepat
- Brick biasa, brick keras (retak), brick baja, brick hazard (tak bisa hancur), dan brick bintang (pasti menjatuhkan power-up)
- 12 power-up: Multi Ball, Laser, Shield, Paddle Up, Slow Time, Magnet, Extra Life, Bomb, Speed Up, Random, Fireball, Freeze
- 3 nyawa, skor, best score tersimpan, menu jeda, layar Game Over dan Victory, efek suara dan tombol mute

## Menjalankan

1. Buka Godot 4.7 (atau lebih baru), pilih **Import**, lalu arahkan ke `project.godot`.
2. Tekan **F5**.

## Struktur

```
assets/   sprite, video splash (.ogv), efek suara (.wav)
scenes/   splash.tscn (scene utama), game.tscn
scripts/  game.gd (logika utama), hud.gd, ball.gd, paddle.gd, brick.gd,
          powerup.gd, laser.gd, background.gd, levels.gd, global.gd (autoload)
```

Layout level bisa diubah di `scripts/levels.gd`.
