class Salt
	def Salt::encode str, cyph
		nstr = ''
		idx = 0
		str.each_char do |chr|
			nn = chr.ord + cyph[idx].ord
			nstr += "%0.3d" % nn
			idx += 1
			if cyph.length == idx
				idx = 0
			end
		end
		return nstr
	end
	def Salt::decode str, cyph
		nstr = ''
		tstr = ''
		idx = 0
		idx2 = 0
		str.each_char do |chr|
			if(idx == 3)
				nstr += (tstr.to_i - cyph[idx2].ord).chr
				tstr = chr
				idx2 += 1
				if cyph.length == idx2
					idx2 = 0
				end
				idx = 0
			else
				tstr += chr
			end
			idx += 1
		end
		nstr += (tstr.to_i - cyph[idx2].ord).chr
		return nstr
	end
end
