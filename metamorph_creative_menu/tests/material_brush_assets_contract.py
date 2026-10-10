from pathlib import Path
import struct
import sys
import zlib

root=Path(sys.argv[1]).resolve()
expected={0:(1,1,1),1:(3,3,5),2:(5,5,13),4:(9,9,49),6:(13,13,113)}
MARKER=(0x5A,0xC7,0x5A,0xFF)  # PNG RGBA for LoadPixelScene ARGB key ff5ac75a

def decode_rgba_png(data: bytes):
    assert data[:8]==b'\x89PNG\r\n\x1a\n'
    pos=8; width=height=None; compressed=[]
    while pos < len(data):
        length=struct.unpack('>I',data[pos:pos+4])[0]
        kind=data[pos+4:pos+8]
        payload=data[pos+8:pos+8+length]
        pos += 12 + length
        if kind==b'IHDR':
            width,height,depth,color_type,compression,filter_method,interlace=struct.unpack('>IIBBBBB',payload)
            assert depth==8 and color_type==6 and compression==0 and filter_method==0 and interlace==0
        elif kind==b'IDAT':
            compressed.append(payload)
        elif kind==b'IEND':
            break
    assert width and height and compressed
    raw=zlib.decompress(b''.join(compressed))
    stride=width*4
    rows=[]; offset=0; previous=bytearray(stride)
    for _ in range(height):
        filter_type=raw[offset]; offset+=1
        scan=bytearray(raw[offset:offset+stride]); offset+=stride
        recon=bytearray(stride)
        for i,value in enumerate(scan):
            left=recon[i-4] if i>=4 else 0
            up=previous[i]
            up_left=previous[i-4] if i>=4 else 0
            if filter_type==0:
                x=value
            elif filter_type==1:
                x=(value+left)&0xff
            elif filter_type==2:
                x=(value+up)&0xff
            elif filter_type==3:
                x=(value+((left+up)//2))&0xff
            elif filter_type==4:
                p=left+up-up_left
                pa=abs(p-left); pb=abs(p-up); pc=abs(p-up_left)
                predictor=left if pa<=pb and pa<=pc else (up if pb<=pc else up_left)
                x=(value+predictor)&0xff
            else:
                raise AssertionError(f'unsupported PNG filter {filter_type}')
            recon[i]=x
        rows.append(recon); previous=recon
    pixels=[]
    for row in rows:
        for i in range(0,len(row),4): pixels.append(tuple(row[i:i+4]))
    return width,height,pixels

for radius,(want_w,want_h,want_markers) in expected.items():
    path=root/'files'/'features'/'materials'/'brushes'/f'brush_r{radius}.png'
    width,height,pixels=decode_rgba_png(path.read_bytes())
    assert (width,height)==(want_w,want_h), f'{path.name}: expected {(want_w,want_h)}, got {(width,height)}'
    opaque=[pixel for pixel in pixels if pixel[3] != 0]
    assert len(opaque)==want_markers, f'{path.name}: expected {want_markers} brush cells, got {len(opaque)}'
    assert all(pixel==MARKER for pixel in opaque), f'{path.name}: mask color no longer matches ff5ac75a mapping'
    assert all(pixel==(0,0,0,0) for pixel in pixels if pixel[3]==0), f'{path.name}: nonempty transparent padding can overwrite world cells'
print(f'material_brush_assets_contract=PASS count={len(expected)} circles=5 marker=ff5ac75a transparent_padding=true')
backend=(root/'files/platform/noita/material_grid.lua').read_text(encoding='utf-8')
painter=(root/'files/features/materials/painter.lua').read_text(encoding='utf-8')
assert 'paint_solid_scene_prepared' in backend and 'LoadPixelScene' in backend
assert 'paint_cell_prepared' in backend and 'construct_cell' in backend
assert 'MATERIAL_MASK_COLOR = "ff5ac75a"' in painter
