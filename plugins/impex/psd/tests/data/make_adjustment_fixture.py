"""Build a PSD carrying all four supported Photoshop adjustment layers.

The fork ships no fixture with an adjustment layer, which is why the new
import path had nothing to test against. psd-tools writes the bytes here,
which makes this a genuine cross-check: a different implementation lays
out the blocks than the C++ that reads them, so field order, widths and
endianness are exercised rather than assumed.
"""
import copy, struct, sys
from psd_tools.psd import PSD
from psd_tools.psd.tagged_blocks import TaggedBlock, TaggedBlocks
from psd_tools.constants import Tag

SRC = r"E:\CODE PROJECTS\imagic-studio\plugins\impex\psd\tests\data\group_layers.psd"
OUT = sys.argv[1]

LEVELS = dict(input_floor=20, input_ceiling=200, output_floor=10,
              output_ceiling=240, gamma=150)   # gamma 1.50
POSTERIZE_STEPS = 7
THRESHOLD_LEVEL = 90


def levels_block() -> bytes:
    out = struct.pack(">H", 2)
    out += struct.pack(">5H", LEVELS["input_floor"], LEVELS["input_ceiling"],
                       LEVELS["output_floor"], LEVELS["output_ceiling"],
                       LEVELS["gamma"])
    out += struct.pack(">5H", 0, 255, 0, 255, 100) * 28   # identity per-channel
    return out


psd = PSD.read(open(SRC, "rb"))
li = psd.layer_and_mask_information.layer_info

# Only two plain paint layers exist in the source; clone one to get four.
template_idx = 2
while len(li.layer_records) < 7:
    li.layer_records.append(copy.deepcopy(li.layer_records[template_idx]))
    li.channel_image_data.append(copy.deepcopy(li.channel_image_data[template_idx]))
li.layer_count = -len(li.layer_records)


def put(idx, name, key, data):
    rec = li.layer_records[idx]
    if rec.tagged_blocks is None:
        rec.tagged_blocks = TaggedBlocks()
    if Tag.UNICODE_LAYER_NAME in rec.tagged_blocks:
        del rec.tagged_blocks[Tag.UNICODE_LAYER_NAME]
    rec.tagged_blocks[key] = TaggedBlock(signature=b"8BIM", key=key, data=data)
    rec.name = name


put(2, "PS Levels",    Tag.LEVELS,    levels_block())
put(3, "PS Invert",    Tag.INVERT,    b"")
put(5, "PS Posterize", Tag.POSTERIZE, struct.pack(">H2x", POSTERIZE_STEPS))
put(6, "PS Threshold", Tag.THRESHOLD, struct.pack(">H2x", THRESHOLD_LEVEL))

with open(OUT, "wb") as fp:
    psd.write(fp)
print("wrote", OUT, "with", len(li.layer_records), "layers")
