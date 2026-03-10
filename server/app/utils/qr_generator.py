import io
import base64
from PIL import Image, ImageDraw, ImageFont
import qrcode
from datetime import datetime


def generate_runner_qr_image(
    runner_name: str,
    runner_guid: str,
    race_name: str,
    race_date: datetime,
    short_id: str,
    qr_data: dict
) -> bytes:
    """
    Generate a QR code image with race information formatted nicely.
    Returns the image as bytes.
    """
    # Create QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_data)
    qr.make(fit=True)
    
    qr_img = qr.make_image(fill_color="black", back_color="white")
    
    # Create final image with text
    # Calculate dimensions
    qr_width = qr_img.size[0]
    padding = 20
    text_height = 120
    
    width = qr_width + (padding * 2)
    height = qr_width + text_height + (padding * 2)
    
    final_img = Image.new('RGB', (width, height), 'white')
    
    # Paste QR code
    final_img.paste(qr_img, (padding, padding))
    
    # Draw text
    draw = ImageDraw.Draw(final_img)
    
    # Try to use a nice font, fall back to default
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
        text_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
        small_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 10)
    except:
        title_font = ImageFont.load_default()
        text_font = ImageFont.load_default()
        small_font = ImageFont.load_default()
    
    # Text positioning
    text_y = padding + qr_width + 15
    
    # Race name
    draw.text(
        (width // 2, text_y),
        race_name,
        font=title_font,
        fill='black',
        anchor='mm'
    )
    
    # Runner name
    draw.text(
        (width // 2, text_y + 25),
        runner_name,
        font=text_font,
        fill='black',
        anchor='mm'
    )
    
    # Short ID (last 6 digits of GUID)
    draw.text(
        (width // 2, text_y + 50),
        f"ID: {short_id}",
        font=small_font,
        fill='gray',
        anchor='mm'
    )
    
    # Race date
    date_str = race_date.strftime("%Y-%m-%d") if race_date else "TBD"
    draw.text(
        (width // 2, text_y + 70),
        f"Date: {date_str}",
        font=small_font,
        fill='gray',
        anchor='mm'
    )
    
    # Save to bytes
    img_bytes = io.BytesIO()
    final_img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    return img_bytes.getvalue()


def generate_server_join_qr(
    server_url: str,
    race_id: str,
    shared_secret: str,
    device_id: str
) -> bytes:
    """Generate QR code for joining a race server"""
    
    qr_data = {
        "type": "server_join",
        "server_url": server_url,
        "race_id": race_id,
        "shared_secret": shared_secret,
        "device_id": device_id
    }
    
    import json
    qr_json = json.dumps(qr_data)
    
    # Create QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_json)
    qr.make(fit=True)
    
    qr_img = qr.make_image(fill_color="black", back_color="white")
    
    # Add border and title
    padding = 20
    text_height = 40
    
    width = qr_img.size[0] + (padding * 2)
    height = qr_img.size[1] + padding + text_height
    
    final_img = Image.new('RGB', (width, height), 'white')
    final_img.paste(qr_img, (padding, text_height))
    
    # Draw title
    draw = ImageDraw.Draw(final_img)
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
    except:
        title_font = ImageFont.load_default()
    
    draw.text(
        (width // 2, 15),
        "Scan to Join Race Server",
        font=title_font,
        fill='black',
        anchor='mm'
    )
    
    # Save to bytes
    img_bytes = io.BytesIO()
    final_img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    return img_bytes.getvalue()


def generate_bib_number_image(
    bib_number: int,
    runner_name: str,
    race_name: str
) -> bytes:
    """Generate a bib number image for printing"""
    
    width = 400
    height = 500
    
    img = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(img)
    
    # Draw border
    draw.rectangle([10, 10, width-10, height-10], outline='black', width=3)
    
    # Try to use fonts
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        name_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 32)
        number_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 120)
    except:
        title_font = ImageFont.load_default()
        name_font = ImageFont.load_default()
        number_font = ImageFont.load_default()
    
    # Race name
    draw.text(
        (width // 2, 40),
        race_name,
        font=title_font,
        fill='black',
        anchor='mm'
    )
    
    # Runner name
    draw.text(
        (width // 2, 100),
        runner_name,
        font=name_font,
        fill='black',
        anchor='mm'
    )
    
    # Bib number
    draw.text(
        (width // 2, height // 2),
        str(bib_number),
        font=number_font,
        fill='black',
        anchor='mm'
    )
    
    # Save to bytes
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    return img_bytes.getvalue()
