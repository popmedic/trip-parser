#require 'sqlite3'
require 'date'
require 'net/imap'

class TripParser
	def initialize
		@mail = Hash.new
		@begin_trips = Array.new
		@end_trips = Array.new
		@trips = Array.new
		@status = File.new 'status.txt', 'w'
		#@db = SQLite3::Database.new 'my_responses.db'
		@pri1_trips = Array.new
		@pri3_trips = Array.new
		@expired_trips = Array.new
	end
	
	def open_local filepath
		File.open filepath do |file|
			file.each_line do |line|
				if(/^From .*@.*/ =~ line)
					@mail = Hash.new
				else
					_parseMsgLine line
				end
			end
			_orginize_trips
			_prep_reports
			return true
		end
		return false
	end
	
	def open_remote email, pass
		user, server = _parseEmail email
		if user != nil
			if server == 'gmail.com'
				server = 'imap.gmail.com'
				port = 993
				use_ssl = true
			else
				puts "ERROR: Currently only working with gmail."
				return false
			end
			print "Connect to: %s:%d... " % [server, port]
			imap = Net::IMAP.new server, port, use_ssl
			puts "Connected."
			print "Loggining in as: %s... " % [user]
			if(imap.login(user, pass))
				puts "Logged in."
				print "Select: INBOX... "
				imap.select('Trip')
				puts "Selected"
				ids = imap.search(['ALL'])
				puts "Parsing %d messages..." % [ids.length]
				idx = 0
				ids.each do |id|
					idx += 1
					@mail = Hash.new
					msg = imap.fetch(id, 'RFC822')[0].attr['RFC822']
					print "Parsing message %d of %d:" % [idx, ids.length]
					msg.each_line do |line|
						print '.'
						_parseMsgLine line
					end
					puts "success"
				end
				imap.logout
				imap.disconnect
				_orginize_trips
				_prep_reports
				return true
			end
			puts "Unable to login."
			imap.disconnect
			return false
		end
		return false
	end
	
	def cl_report
		longest_out = 0
		@trips.each do |trip|
			out = "%16.16s    %6s    %2s    %2s    %5s    %5s    %5s    %5s    %5s    %24.24s    %8.8s    %s" % [
				trip[:date],
				trip[:trip],
				trip[:amb],
				trip[:pri],
				trip[:disp],
				trip[:scn],
				trip[:dept],
				trip[:hosp],
				trip[:miles],
				trip[:addr],
				trip[:apt],
				trip[:nature]
			]
			#out = trip.values.join "    "
			longest_out < out.length ? longest_out = out.length : nil
			puts out
		end
		puts "="*longest_out
		puts "Found %d trips." % @trips.length
		puts "Found %d priority 1 trips." % @pri1_trips.length
		puts "Found %d expired priority 1 trips." % @expired_trips.length
		puts "%0.3f%% of the time you make your response time for code 10." % 
			(((@pri1_trips.length.to_f - @expired_trips.length.to_f) / @pri1_trips.length.to_f) * 100.0)
	end
	
	def comma_report
		File.open 'report.csp', "w" do |file|
			@trips.each do |trip|
				file.puts trip.values.join ','
			end 
		end
	end
	
	def txt_report
		File.open 'report.txt', "w" do |file|
			@trips.each do |trip|
				file.puts trip.values.join "\t"
			end 
		end
	end
	
	def xml_report
		File.open 'report.xml', "w" do |file|
			file.write "<report>"
			@trips.each do |trip|
				file.write "<trip>"
				trip.keys.each do |key|
					file.write "<%s>%s</%s>" % [key, trip[key], key]
				end
				file.write "</trip>"
			end 
			file.write "</report>"
		end
	end
	
	def html_report	
		File.open 'report.html', 'w' do |file|
			file.write '<htmL><head></head><body><table border="1">'
			@trips.each do |trip|
				file.write "<tr>"
				trip.keys.each do |key|
					file.write "<td class=\".%s\">%s</td>" % [key, trip[key]]
				end
				file.write "</tr>"
			end 
			file.write '</table></body></html>'
		end
	end

	def getTripTimeStr trip, time
		dt = DateTime.parse(trip[:disp]).to_time.to_i
		tt = DateTime.parse(trip[time]).to_time.to_i
		if tt < dt
			return trip[:edate]+' '+trip[time]+':00 '
		end
		return trip[:date]+' '+trip[time]+':00 '
	end

private
	
	def _orginize_trips
		@begin_trips.each do |bt|
			@end_trips.each do |et|
				if(bt[:trip] == et[:trip])
					bt[:scn] = et[:scn]
					bt[:dept] = et[:dept]
					bt[:hosp] = et[:hosp]
					bt[:miles] = et[:miles]
					bt[:edate] = et[:date]
					bt[:timestamp] = DateTime.parse(bt[:date]+' '+bt[:disp]+':00').to_time.to_i
					# sql = "INSERT INTO trips(trip, trip_prefix, date, disp, scn, dept, hosp, miles, amb, pri, addr, apt, nature, timestamp) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)" 
	# 				@db.execute(sql,
	# 					bt[:trip], 
	# 					bt[:trip_prefix],
	# 					bt[:date],
	# 					bt[:disp],
	# 					bt[:scn],
	# 					bt[:dept],
	# 					bt[:hosp],
	# 					bt[:miles],
	# 					bt[:amb],
	# 					bt[:pri],
	# 					bt[:addr],
	# 					bt[:apt],
	# 					bt[:nature],
	#						bt[:timestamp])
					@trips << bt
					break
				end
			end
		end
		@trips.sort! {|x,y| x[:timestamp] <=> y[:timestamp] }
	end
	
	def _prep_reports
		@trips.each do |trip|			
			disp_str = self.getTripTimeStr trip, :disp
			scn_str  = self.getTripTimeStr trip, :scn
			td = (DateTime.parse(scn_str).to_time.to_i - DateTime.parse(disp_str).to_time.to_i) / 60  #time_dif(trip[:scn], trip[:disp])
			if(trip[:pri] == '1')
				@pri1_trips << trip
				if td > 8
					@expired_trips << trip
				end
			elsif trip[:pri] == '3'
				@pri3_trips << trip
				if td > 30
					@expired_trips << trip
				end
			end
		end
	end
	
	def _tripNumExistsIn num, src
		src.each do |trip|
			if trip[:trip] == num
				return true
			end
		end
		return false
	end
	def _parseMsgLine line
		if(/^Date: (?<date>.*)/ =~ line)
			@mail[:date] = date.strip.gsub(/ [0-9]+:[0-9]+:[0-9]+.*$/, '')
		elsif(/AMB:(?<amb>.*)PRI:(?<pri>.*)ADD:(?<addr>.*)APT:(?<apt>.*)NATURE:(?<nature>.*)TRIP:(?<trip_prefix>[0-9]+)\-(?<trip>[0-9]+) *TIME:(?<start_time>.*)/ =~ line)
			if(!_tripNumExistsIn(trip.strip, @begin_trips))
				@mail[:amb] = amb.strip
				@mail[:pri] = pri.strip
				@mail[:addr] = addr.strip
				@mail[:apt] = apt.strip
				@mail[:nature] = nature.strip
				@mail[:trip_prefix] = trip_prefix.strip
				@mail[:trip] = trip.strip
				@mail[:disp] = start_time.strip
				@begin_trips << @mail
			end
		elsif(/TRIP: *(?<trip_prefix>[0-9]+)\-(?<trip>[0-9]+) *AtScn: *(?<scn>.*)DepScn: *(?<dept>.*)AtHosp: *(?<hosp>.*)Miles: *(?<miles>.*)/ =~ line)
			if(!_tripNumExistsIn(trip.strip, @end_trips))
				@mail[:trip_prefix] = trip_prefix.strip
				@mail[:trip] = trip.strip
				@mail[:scn] = scn.strip
				@mail[:dept] = dept.strip
				@mail[:hosp] = hosp.strip
				@mail[:miles] = miles.strip
				@end_trips << @mail
			end
		end
	end
	def _parseEmail email
		if /^(?<user>.+)@(?<server>.+)$/ =~ email
			return user, server
		end
		puts "%s is not a valid email address" % email
		return nil, nil
	end
end

tp = TripParser.new
if tp.open_remote 'kscardina.dhpd@gmail.com', 'sk8board1'
#if tp.open_local 'Trip.mbox'
	tp.cl_report
end