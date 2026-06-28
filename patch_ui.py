import re

files_to_process = {
    'scripts/minigames/timing_bar.gd': [
        ('const SCREEN_W := 1080.0\nconst SCREEN_H := 1920.0', 'const SCREEN_W := 1920.0\nconst SCREEN_H := 1080.0'),
        ('Vector2((1080 - BAR_WIDTH)/2, 1300)', 'Vector2((SCREEN_W - BAR_WIDTH)/2, 800)'),
        ('Vector2((1080 - 400)/2, 800)', 'Vector2((SCREEN_W - 400)/2, 600)'),
        ('Vector2((1080 - 200)/2, 1420)', 'Vector2((SCREEN_W - 200)/2, 920)'),
        ('Vector2((1080 - 400)/2, 1100)', 'Vector2((SCREEN_W - 400)/2, 680)'),
        ('tap_btn.size = Vector2(1080, 1920)', 'tap_btn.size = Vector2(SCREEN_W, SCREEN_H)'),
        ('root.offset_right  = 1080.0\n\troot.offset_bottom = 1920.0', 'root.offset_right  = SCREEN_W\n\troot.offset_bottom = SCREEN_H')
    ],
    'scripts/minigames/swipe_qte.gd': [
        ('const SCREEN_W := 1080.0\nconst SCREEN_H := 1920.0', 'const SCREEN_W := 1920.0\nconst SCREEN_H := 1080.0'),
        ('dim.size = Vector2(1080, 1920)', 'dim.size = Vector2(SCREEN_W, SCREEN_H)'),
        ('Vector2((1080 - 400)/2, 750)', 'Vector2((SCREEN_W - 400)/2, 400)'),
        ('Vector2((1080 - 200)/2, 980)', 'Vector2((SCREEN_W - 200)/2, 620)'),
        ('Vector2((1080 - 600)/2, 600)', 'Vector2((SCREEN_W - 600)/2, 280)'),
        ('Vector2((1080 - 300)/2, 1050)', 'Vector2((SCREEN_W - 300)/2, 700)'),
        ('root.offset_right  = 1080.0\n\troot.offset_bottom = 1920.0', 'root.offset_right  = SCREEN_W\n\troot.offset_bottom = SCREEN_H')
    ],
    'scripts/menus/main_menu.gd': [
        ('const SCREEN_W := 1080.0\nconst SCREEN_H := 1920.0', 'const SCREEN_W := 1920.0\nconst SCREEN_H := 1080.0'),
        ('bg_deep.size     = Vector2(SCREEN_W, SCREEN_H * 0.5)\n\tbg_deep.position = Vector2(0, SCREEN_H * 0.5)', 'bg_deep.size     = Vector2(SCREEN_W, SCREEN_H * 0.4)\n\tbg_deep.position = Vector2(0, SCREEN_H * 0.6)'),
        ('Vector2(0, 680)', 'Vector2(0, 600)'), # waterline
        ('title.size     = Vector2(SCREEN_W, 150)\n\ttitle.position = Vector2(0, 178)', 'title.size     = Vector2(SCREEN_W, 150)\n\ttitle.position = Vector2(0, 120)'),
        ('title_glow.size     = Vector2(SCREEN_W + 20, 150)\n\ttitle_glow.position = Vector2(-10, 174)', 'title_glow.size     = Vector2(SCREEN_W + 20, 150)\n\ttitle_glow.position = Vector2(-10, 116)'),
        ('subtitle.size     = Vector2(SCREEN_W, 70)\n\tsubtitle.position = Vector2(0, 340)', 'subtitle.size     = Vector2(SCREEN_W, 70)\n\tsubtitle.position = Vector2(0, 260)'),
        ('divider.size     = Vector2(560, 3)\n\tdivider.position = Vector2(260, 422)', 'divider.size     = Vector2(560, 3)\n\tdivider.position = Vector2((SCREEN_W-560)/2, 360)'),
        ('stats.size     = Vector2(SCREEN_W, 60)\n\tstats.position = Vector2(0, 440)', 'stats.size     = Vector2(SCREEN_W, 60)\n\tstats.position = Vector2(0, 390)'),
        ('fish_count.size     = Vector2(SCREEN_W, 50)\n\tfish_count.position = Vector2(0, 490)', 'fish_count.size     = Vector2(SCREEN_W, 50)\n\tfish_count.position = Vector2(0, 450)'),
        ('Vector2(180, 860)', 'Vector2((SCREEN_W-720)/2, 600)'), # play btn pos
        ('Vector2(130, 1062)', 'Vector2((SCREEN_W-820)/2, 820)'), # row pos
        ('Vector2(-250.0, 350.0 + i * 220.0', 'Vector2(-250.0, 300.0 + i * 150.0'),
        ('d.position.y = 340.0 + i * 210.0', 'd.position.y = 300.0 + i * 150.0')
    ]
}

for filepath, replacements in files_to_process.items():
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements:
        content = content.replace(old, new)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
