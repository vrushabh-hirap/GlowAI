import os
from PIL import Image, ImageDraw, ImageFilter

def create_app_icon():
    os.makedirs('assets/icon', exist_ok=True)
    os.makedirs('assets/images/medicines', exist_ok=True)
    os.makedirs('assets/images/products', exist_ok=True)
    os.makedirs('assets/images/doctors', exist_ok=True)

    size = (1024, 1024)
    
    # 1. Full Icon (icon.png)
    icon = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    
    # Rounded square background with vertical gradient #FFB3D1 to #FF8FB8
    top_color = (255, 179, 209)
    bottom_color = (255, 143, 184)
    
    for y in range(1024):
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * (y / 1024.0))
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * (y / 1024.0))
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * (y / 1024.0))
        draw.line([(0, y), (1024, y)], fill=(r, g, b, 255))
        
    # Create mask for rounded corners (radius 220)
    mask = Image.new('L', size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, 1024, 1024], radius=220, fill=255)
    
    icon_rounded = Image.new('RGBA', size, (0, 0, 0, 0))
    icon_rounded.paste(icon, (0, 0), mask)
    
    # Draw Sparkle + Face / Leaf emblem on icon_rounded
    draw_emblem = ImageDraw.Draw(icon_rounded)
    
    # Glow effect layer
    glow = Image.new('RGBA', size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    
    center_x, center_y = 512, 512
    # Outer glowing face oval outline
    glow_draw.ellipse([312, 230, 712, 730], outline=(255, 255, 255, 200), width=36)
    # Sparkle 4-point star in top-right
    glow_draw.ellipse([640, 260, 760, 380], fill=(255, 255, 255, 240))
    # Smooth blur
    glow = glow.filter(ImageFilter.GaussianBlur(radius=15))
    
    icon_rounded = Image.alpha_composite(icon_rounded, glow)
    draw_emblem = ImageDraw.Draw(icon_rounded)
    
    # Crisp white lines
    # Face outline (oval with elegant curve)
    draw_emblem.ellipse([320, 240, 700, 720], outline=(255, 255, 255, 255), width=28)
    
    # Sparkle / Leaf motif (drawn with diamond/curves)
    # Center star 1
    star_x, star_y = 680, 310
    star_pts = [
        (star_x, star_y - 65),
        (star_x + 18, star_y - 18),
        (star_x + 65, star_y),
        (star_x + 18, star_y + 18),
        (star_x, star_y + 65),
        (star_x - 18, star_y + 18),
        (star_x - 65, star_y),
        (star_x - 18, star_y - 18)
    ]
    draw_emblem.polygon(star_pts, fill=(255, 255, 255, 255))
    
    # Smaller sparkle 2
    s2_x, s2_y = 350, 680
    s2_pts = [
        (s2_x, s2_y - 40),
        (s2_x + 10, s2_y - 10),
        (s2_x + 40, s2_y),
        (s2_x + 10, s2_y + 10),
        (s2_x, s2_y + 40),
        (s2_x - 10, s2_y + 10),
        (s2_x - 40, s2_y),
        (s2_x - 10, s2_y - 10)
    ]
    draw_emblem.polygon(s2_pts, fill=(255, 255, 255, 245))
    
    # Inner gentle smile / leaf arc
    draw_emblem.arc([420, 480, 600, 620], start=20, end=160, fill=(255, 255, 255, 255), width=22)

    icon_rounded.save('assets/icon/icon.png', 'PNG')
    print("Created assets/icon/icon.png")

    # 2. Foreground transparent icon (icon_foreground.png)
    fg = Image.new('RGBA', size, (0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(fg)
    
    fg_draw.ellipse([340, 260, 680, 700], outline=(255, 255, 255, 255), width=28)
    fg_draw.polygon(star_pts, fill=(255, 255, 255, 255))
    fg_draw.polygon(s2_pts, fill=(255, 255, 255, 245))
    fg_draw.arc([430, 490, 590, 610], start=20, end=160, fill=(255, 255, 255, 255), width=22)
    
    fg.save('assets/icon/icon_foreground.png', 'PNG')
    print("Created assets/icon/icon_foreground.png")

if __name__ == '__main__':
    create_app_icon()
