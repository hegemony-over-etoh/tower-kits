-- github.com/boatbomber/HashLib
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local bit32_band = bit32.band -- 2 arguments
local bit32_bor = bit32.bor -- 2 arguments
local bit32_bxor = bit32.bxor -- 2..5 arguments
local bit32_rrotate = bit32.rrotate -- second argument is integer 0..31

local md5_K, md5_sha1_H = {}, { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0 }
local md5_next_shift =
	{ 0, 0, 0, 0, 0, 0, 0, 0, 28, 25, 26, 27, 0, 0, 10, 9, 11, 12, 0, 15, 16, 17, 18, 0, 20, 22, 23, 21 }
local common_W = {}
local TWO_POW_16 = 2 ^ 16

for idx = 1, 64 do
	local hi, lo = math.modf(math.abs(math.sin(idx)) * TWO_POW_16)
	md5_K[idx] = hi * 65536 + math.floor(lo * TWO_POW_16)
end

local function md5_feed_64(H, str, offs, size)
	-- offs >= 0, size >= 0, size is multiple of 64
	local W, K, md5_next_shift = common_W, md5_K, md5_next_shift
	local h1, h2, h3, h4 = H[1], H[2], H[3], H[4]
	for pos = offs, offs + size - 1, 64 do
		for j = 1, 16 do
			pos = pos + 4
			local a, b, c, d = string.byte(str, pos - 3, pos)
			W[j] = ((d * 256 + c) * 256 + b) * 256 + a
		end

		local a, b, c, d = h1, h2, h3, h4
		local s = 25
		for j = 1, 16 do
			local F = bit32_rrotate(bit32_band(b, c) + bit32_band(-1 - b, d) + a + K[j] + W[j], s) + b
			s = md5_next_shift[s]
			a = d
			d = c
			c = b
			b = F
		end

		s = 27
		for j = 17, 32 do
			local F = bit32_rrotate(bit32_band(d, b) + bit32_band(-1 - d, c) + a + K[j] + W[(5 * j - 4) % 16 + 1], s)
				+ b
			s = md5_next_shift[s]
			a = d
			d = c
			c = b
			b = F
		end

		s = 28
		for j = 33, 48 do
			local F = bit32_rrotate(bit32_bxor(bit32_bxor(b, c), d) + a + K[j] + W[(3 * j + 2) % 16 + 1], s) + b
			s = md5_next_shift[s]
			a = d
			d = c
			c = b
			b = F
		end

		s = 26
		for j = 49, 64 do
			local F = bit32_rrotate(bit32_bxor(c, bit32_bor(b, -1 - d)) + a + K[j] + W[(j * 7 - 7) % 16 + 1], s) + b
			s = md5_next_shift[s]
			a = d
			d = c
			c = b
			b = F
		end

		h1 = (a + h1) % 4294967296
		h2 = (b + h2) % 4294967296
		h3 = (c + h3) % 4294967296
		h4 = (d + h4) % 4294967296
	end

	H[1], H[2], H[3], H[4] = h1, h2, h3, h4
end

return function(message)
	-- Create an instance (private objects for current calculation)
	local H, length, tail = table.create(4), 0, ""
	H[1], H[2], H[3], H[4] = md5_sha1_H[1], md5_sha1_H[2], md5_sha1_H[3], md5_sha1_H[4]

	local function partial(message_part)
		if message_part then
			local partLength = #message_part
			if tail then
				length = length + partLength
				local offs = 0
				if tail ~= "" and #tail + partLength >= 64 then
					offs = 64 - #tail
					md5_feed_64(H, tail .. string.sub(message_part, 1, offs), 0, 64)
					tail = ""
				end

				local size = partLength - offs
				local size_tail = size % 64
				md5_feed_64(H, message_part, offs, size - size_tail)
				tail = tail .. string.sub(message_part, partLength + 1 - size_tail)
				return partial
			else
				error("Adding more chunks is not allowed after receiving the result", 2)
			end
		else
			if tail then
				local final_blocks = table.create(3) --{tail, "\128", string.rep("\0", (-9 - length) % 64)}
				final_blocks[1] = tail
				final_blocks[2] = "\128"
				final_blocks[3] = string.rep("\0", (-9 - length) % 64)
				tail = nil
				length = length * 8 -- convert "byte-counter" to "bit-counter"
				for j = 4, 11 do
					local low_byte = length % 256
					final_blocks[j] = string.char(low_byte)
					length = (length - low_byte) / 256
				end

				final_blocks = table.concat(final_blocks)
				md5_feed_64(H, final_blocks, 0, #final_blocks)
				for j = 1, 4 do
					H[j] = string.format("%08x", H[j] % 4294967296)
				end

				H = string.gsub(table.concat(H), "(..)(..)(..)(..)", "%4%3%2%1")
			end

			return H
		end
	end

	if message then
		-- Actually perform calculations and return the digest of a message
		return partial(message)()
	else
		-- Return function for chunk-by-chunk loading
		-- User should feed every chunk of input data as single argument to this function and finally get digest by invoking this function without an argument
		return partial
	end
end
