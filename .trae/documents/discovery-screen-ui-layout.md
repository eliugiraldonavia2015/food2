## UI Layout Notes - Discovery Screen Redesign

### Estructura de Secciones por Estilo Visual

#### ESTILO 1 - Cards Horizontales (4 secciones)
**Secciones recomendadas:**
1. "Popular cerca de ti" - ya existe
2. "Nuevos en tu zona" 
3. "Los más rápidos"
4. "Mejor calificados"

**Layout específico:**
```
[Imagen 16:9] 
[Título - Bold 24px negro]
[Meta datos - 14px gris con íconos: ⏱ 53min • 💰 $1.10 • 📍 4.6km • ⭐ 4.9 (35)]
[Promo badge - Fondo amarillo #FFD700, texto negro bold: "$4 gratis en créditos"]
```

#### ESTILO 2 - Carrusel Promocional (1 sección)
**Sección recomendada:** "Promociones especiales"

**Layout específico:**
```
[Fondo beige claro #F5E6D3]
[Burgers con - 18px marrón #8B4513]
[40% OFF - 48px bold marrón #8B4513]
[30% FULL - 24px bold marrón #8B4513]
[Indicadores: ● ○ ○ ○]
```

#### ESTILO 3 - Cards con Descuentos (2 secciones)
**Secciones recomendadas:**
1. "Descuentazos"
2. "Ofertas de hoy"

**Layout específico:**
```
[Imagen producto con ícono + verde en top-right]
[$6.55 - 20px bold negro]
[-61% - Badge amarillo #FFD700]
[$17.00 - 14px gris tachado]
[15 Bocados Especiales.. - 14px gris]
[Kobe Sushi & Rolls • ⏱ 53min]
```

#### ESTILO 4 - Lista Minimalista (5+ secciones)
**Secciones recomendadas:**
1. "Pollo delicioso" 
2. "Antojo de hamburguesa"
3. "Pizza & Pasta"
4. "Comida asiática"
5. "Postres & Café"
6. "Comida mexicana"
7. "Ensaladas & Saludable"

**Layout específico:**
```
[KFC - Bold 18px negro]
[$4 gratis en créditos - Badge amarillo pequeño]
[⭐ 4.5 • ⏱ 48min • 💰 $0.90 • 📍 2.9km - 12px gris]
```

### Grid de Categorías con Emojis
```
🍔 Hamburguesas    🌮 Mexicana    🍕 Pizza    🥗 Saludable
🍜 Sopas           🍣 Japonesa    🍰 Postres  ☕ Café
```

### Orden Completo de Secciones
1. Barra búsqueda + filtros
2. Grid de categorías (emojis)
3. Sección estilo 1 - Popular cerca de ti
4. Sección estilo 1 - Nuevos en tu zona  
5. Carrusel estilo 2 - Promociones especiales
6. Sección estilo 1 - Los más rápidos
7. Sección estilo 3 - Descuentazos
8. Sección estilo 1 - Mejor calificados
9. Sección estilo 3 - Ofertas de hoy
10. Secciones estilo 4 - Pollo delicioso
11. Secciones estilo 4 - Antojo de hamburguesa
12. Secciones estilo 4 - Pizza & Pasta
13. Secciones estilo 4 - Comida asiática
14. Secciones estilo 4 - Postres & Café
15. Secciones estilo 4 - Comida mexicana
16. Secciones estilo 4 - Ensaladas & Saludable

### Especificaciones Técnicas
- **Padding horizontal:** 16px mobile, 24px tablet
- **Gap entre cards:** 12px móvil, 16px desktop
- **Border radius:** 12px para cards, 20px para badges
- **Sombras:** 0 2px 8px rgba(0,0,0,0.08)
- **Lazy loading:** Implementar para imágenes fuera de viewport
- **Touch targets:** Mínimo 44px para elementos interactivos