## Pipeline de precompresión y HLS para Bunny (Free)

- Requisitos:
  - `ffmpeg` en PATH
  - Archivos de entrada `mp4/mov`
- Comandos:
  - `python tools/video/transcode_hls.py input.mp4 out_hls`
  - Genera:
    - `720p_hevc.m3u8` + segmentos fMP4 a ~1.5 Mbps
    - `360p_h264.m3u8` + segmentos fMP4 a ~700 kbps
    - `master.m3u8` con ambas variantes
- Parámetros:
  - Segmentos: `3s`
  - GOP/Keyframe: `3s` (alineado entre variantes)
  - Audio: `AAC-LC mono 96 kbps`

### Subida a Bunny Storage
- Conecta por FTP a `storage.bunnycdn.com`
  - Usuario: nombre del Storage Zone
  - Password: API key del Storage
- Sube la carpeta `out_hls` y apunta tu Pull Zone al Storage.
- URL final:
  - `https://<tu-pull-zone>.b-cdn.net/out_hls/master.m3u8`

### Verificación
- `curl -I "https://<tu-pull-zone>.b-cdn.net/out_hls/master.m3u8"`
- `curl -I -H "Range: bytes=0-1" "https://<tu-pull-zone>.b-cdn.net/out_hls/720p_hevc_000.m4s"`

### Tamaños esperados
- 17s 720p HEVC: ≈ 3.4–3.9 MB
- 17s 360p H.264: ≈ 1.6–1.8 MB
