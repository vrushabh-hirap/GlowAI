import os
from PIL import Image, ImageDraw

def generate_placeholders():
    meds = [
        "med_glycolic.png", "med_clindamycin.png", "med_niacinamide.png",
        "med_hyaluronic.png", "med_azelaic.png", "med_ceramide.png"
    ]
    prods = [
        "foundation.png", "serum.png", "blush.png",
        "extensions.png", "cleanser.png", "lipstick.png"
    ]
    
    for m in meds:
        path = f"assets/images/medicines/{m}"
        img = Image.new("RGBA", (300, 300), (255, 228, 239, 255))
        d = ImageDraw.Draw(img)
        d.rounded_rectangle([20, 20, 280, 280], radius=40, outline=(255, 143, 184), width=8)
        d.rectangle([90, 80, 210, 220], fill=(255, 255, 255, 255), outline=(240, 96, 154), width=6)
        d.ellipse([120, 110, 180, 170], fill=(255, 143, 184))
        img.save(path)
        print(f"Created {path}")

    for p in prods:
        path = f"assets/images/products/{p}"
        img = Image.new("RGBA", (300, 300), (255, 240, 245, 255))
        d = ImageDraw.Draw(img)
        d.rounded_rectangle([20, 20, 280, 280], radius=40, outline=(255, 179, 209), width=8)
        d.ellipse([70, 70, 230, 230], fill=(255, 228, 239), outline=(255, 143, 184), width=6)
        img.save(path)
        print(f"Created {path}")

if __name__ == '__main__':
    generate_placeholders()
