require 'date'
require 'time'
require 'net/imap'
require './salting.rb'

class DateTime
	def to_time
		Time.parse(self.to_s)
	end
end

class TripParser
	def initialize
		@mail = Hash.new
		@begin_trips = Array.new
		@end_trips = Array.new
		@trips = Array.new
		@status_filename = 'cache/status.%d.txt' % DateTime.now.to_time.to_i
# 		@status = File.new(status_filename, "w")
		@pri1_trips = Array.new
		@pri3_trips = Array.new
		@days = Array.new
		@expired_trips = Array.new
		@expired_trips3 = Array.new
		@resp_times1 = Array.new
		@resp_times3 = Array.new
		@scn_times = Array.new
		@to_hosp_times = Array.new
		@total_times = Array.new
		@report_file_prefix = 'cache/report.%s.%d' % [ARGV[0].gsub(/\//, '-'), DateTime.now.to_time.to_i]
	end
	
	def open_local filepath
		File.open filepath do |file|
			idx = 0
			puts "Opened file: %s" % [filepath]
			lines = file.readlines
			puts "Parsing %d lines:" % [lines.length]
			lines.each do |line|
				idx += 1
				if(idx % 100 == 0) 
					print "\t%d" % [idx]
				end
				if(/^From .*@.*/ =~ line)
					@mail = Hash.new
				else
					_parseMsgLine line
				end
			end
			puts "\tCOMPLETE"
			_orginize_trips
			_prep_reports
			return true
		end
		return false
	end
	
	def open_remote email, pass
		@user, server, box = _parseEmail email
		if @user != nil
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
			$stdout.flush
			print "Loggining in as: %s... " % [@user]
			begin
				if(imap.login(@user, pass))
					puts "Logged in."
					$stdout.flush
					if box != nil
						print "Select: %s... " % [box.gsub(/^\//, '')]
						imap.select(box.gsub(/^\//, ''))
					else
						print "Select: INBOX... "
						imap.select('INBOX')
					end
					puts "Selected"
					$stdout.flush
					ids = imap.search(['ALL'])
					puts "Parsing %d messages..." % [ids.length]
					$stdout.flush
					idx = 0
					ids.each do |id|
						idx += 1
						@mail = Hash.new
						msg = imap.fetch(id, 'RFC822')[0].attr['RFC822']
						print "Parsing message %d of %d:" % [idx, ids.length]
						idx2 = 0
						msg.each_line do |line|
							idx2 += 1
							if(idx2 % 4 == 0)
								print '.'
							end
							_parseMsgLine line
						end
						puts "success"
						$stdout.flush
					end
					imap.logout
					imap.disconnect
					_orginize_trips
					_prep_reports
					return true
				end
			rescue Exception=>e
				puts "\nERROR: " + e.message
				$stderr.puts "**"+e.backtrace.join("\n**")
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
			/ ([0-9]{2}:[0-9]{2})/ =~ trip[:disp]
			disp = $1
			/ ([0-9]{2}:[0-9]{2})/ =~ trip[:scn]
			scn = $1
			/ ([0-9]{2}:[0-9]{2})/ =~ trip[:dept]
			dept = $1
			/ ([0-9]{2}:[0-9]{2})/ =~ trip[:hosp]
			hosp = $1
			out = "%16.16s    %6s    %2s    %2s    %5.5s    %5.5s    %5.5s    %5.5s    %5s    %24.24s    %8.8s    %s" % [
				trip[:date],
				trip[:trip],
				trip[:amb],
				trip[:pri],
				disp,
				scn,
				dept,
				hosp,
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
		puts "Found %d trips in %d days." % [@trips.length, @days.length]
		puts "Found %d priority 1 trips." % @pri1_trips.length
		puts "Found %d expired priority 1 trips." % @expired_trips.length
		puts "%0.3f%% of the time you make your response time for code 10." % 
			(((@pri1_trips.length.to_f - @expired_trips.length.to_f) / @pri1_trips.length.to_f) * 100.0)
	end
	
	def comma_report
		File.open @report_file_prefix+'.csp', "w" do |file|
			@trips.each do |trip|
				file.puts trip.values.join ','
			end 
		end
	end
	
	def txt_report
		File.open @report_file_prefix+'.txt', "w" do |file|
			longest_out = 0
			@trips.each do |trip|
				out = "%16.16s    %6s    %2s    %2s    %26s    %26s    %26s    %26s    %5s    %24.24s    %8.8s    %s" % [
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
				file.puts out
			end
			file.puts "="*longest_out
			file.puts "Found %d trips in %d days." % [@trips.length, @days.length]
			file.puts "Found %d priority 1 trips." % @pri1_trips.length
			file.puts "Found %d expired priority 1 trips." % @expired_trips.length
			file.puts "%0.3f%% of the time you make your response time for code 10." % 
				(((@pri1_trips.length.to_f - @expired_trips.length.to_f) / @pri1_trips.length.to_f) * 100.0)
		end
	end
	
	def xml_report
		File.open @report_file_prefix+'.xml', "w" do |file|
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
		File.open @report_file_prefix+'.html', 'w' do |file|
			file.write '<htmL><head><title>'+@user+'</title><link href="../report.css" rel= "stylesheet" type="text/css" /></head>'
			file.write '<body>'
			bdt = ''
			edt = ''
			if @trips.length > 0
				bdt = DateTime.parse(@trips[0][:date]).strftime('%Y/%m/%d')
				edt = DateTime.parse(@trips[@trips.length-1][:date]).strftime('%Y/%m/%d')
			end
			file.write '<div id="header">'+@user+' trips for '+bdt+' - '+edt+'</div>'
			file.write '<table>'
			file.write "<tr><th>Date</th><th>Trip#</th><th>Amb</th><th>Pri</th><th>Disp</th><th>Scn</th><th>Dprt</th><th>Hosp</th><th>Mls</th><th>Addr</th><th>Apt</th><th>Nature</th></tr>"
			@trips.each do |trip|
				file.write "<tr>"
				file.write "<td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>" % [
					DateTime.parse(trip[:date]).strftime('%Y/%m/%d'),
					trip[:trip],
					trip[:amb],
					trip[:pri],
					removeTripTimeStr(trip, :disp),
					removeTripTimeStr(trip, :scn),
					removeTripTimeStr(trip, :dept),
					removeTripTimeStr(trip, :hosp),
					trip[:miles],
					trip[:addr],
					trip[:apt],
					trip[:nature]
				]
				file.write "</tr>"
			end 
			file.write '</table>'		
			file.write '<div id="results-box">'
			if(@trips.length > 0)
				file.write '<h1>Found %d trips in %d days.</h1><blockquote>' %  [@trips.length, @days.length]
				file.write '<h2>Average %0.3f calls a shift.</h2>' % [@trips.length.to_f / @days.length.to_f]
				file.write '</blockquote>'
			end
			if(@pri1_trips.length > 0)
				file.write '<h1>Response Times:</h1><blockquote>'
				file.write "<h2>Found %d priority 1 trips.(%0.2f%%)</h2>" % [@pri1_trips.length, (@pri1_trips.length.to_f/@trips.length.to_f)*100.0]
			end
			if(@expired_trips.length > 0)
				file.write "<h2>Found %d expired priority 1 trips.</h2>" % @expired_trips.length
			end
			rtt = 0
			@resp_times1.each do |resp_time|
				rtt += resp_time
			end
			if(rtt > 0)
				file.write "<h2>Average priority 1 response time: %d minutes</h2>" % (rtt/ @resp_times1.length)
			end
			if((@pri1_trips.length.to_f - @expired_trips.length.to_f) > 0)
				file.write "<h2>%0.3f%% priority 1 response times.</h2>" % 
					(((@pri1_trips.length.to_f - @expired_trips.length.to_f) / @pri1_trips.length.to_f) * 100.0)
			end
			if(@pri3_trips.length > 0)
				file.write "<h2>Found %d priority 3 trips(%0.2f%%)</h2>" % [@pri3_trips.length, (@pri3_trips.length.to_f/@trips.length.to_f)*100.0]
			end
			file.write "<h2>Found %d expired priority 3 trips.</h2>" % @expired_trips3.length
			rtt = 0
			@resp_times3.each do |resp_time|
				rtt += resp_time
			end
			if (rtt > 0)
				file.write "<h2>Average priority 3 response time: %d minutes</h2>" % (rtt/ @resp_times1.length)
			end
			if((@pri3_trips.length.to_f - @expired_trips3.length.to_f) > 0)
				file.write "<h2>%0.3f%% pri 3 response times.</h2>" % 
					(((@pri3_trips.length.to_f - @expired_trips3.length.to_f) / @pri3_trips.length.to_f) * 100.0)
			end
			file.write '</blockquote>'
			file.write '<h1>Other Times:</h1><blockquote>'
			scntt = 0
			@scn_times.each do |scn_time|
				scntt += scn_time
			end
			if(scntt > 0)
				file.write '<h2>Average scene time: %d minutes</h2>' % (scntt / @scn_times.length)
			end
			thosptt = 0
			@to_hosp_times.each do |hosp_time|
				thosptt += hosp_time
			end
			if thosptt > 0
				file.write '<h2>Average time to hospital: %d minutes</h2>' % (thosptt / @to_hosp_times.length)
			end
			tctt = 0
			@total_times.each do |total_time|
				tctt += total_time
			end
			if(tctt > 0)
				file.write '<h2>Average total call time: %d minutes</h2>' % (tctt / @total_times.length)
			end
			file.write "</blockquote>"
			file.write '</div>'
			file.write '</body></html>'
		end
	end

	def getTripTimeStr trip, time
		dt = DateTime.parse(trip[:date]+' '+trip[:disp]).to_time.to_i
		tt = DateTime.parse(trip[:date]+' '+trip[time]).to_time.to_i
		if tt < dt
			return trip[:edate]+' '+trip[time]+':00 '
		end
		return trip[:date]+' '+trip[time]+':00 '
	end
	
	def removeTripTimeStr trip, time
		if(/^.* ([0-9]{2}:[0-9]{2}):00 .*/ =~ trip[time])
			return $1
		end
		return trip[time]
	end
	
	def set_status_filename fn
		@status_filename = fn
	end
	def status_filename
		return @status_filename
	end
	def report_file_prefix 
		return @report_file_prefix 
	end
private
	
	def _orginize_trips
		@begin_trips.each do |bt|
			@end_trips.each do |et|
				if(bt[:trip] == et[:trip])
					bt[:edate] = et[:date]
					bt[:scn] = et[:scn]
					bt[:dept] = et[:dept]
					bt[:hosp] = et[:hosp]
					bt[:scn] = getTripTimeStr bt, :scn
					bt[:dept] = getTripTimeStr bt, :dept
					bt[:hosp] = getTripTimeStr bt, :hosp
					bt[:miles] = et[:miles]
					bt[:timestamp] = DateTime.parse(bt[:date]+' '+bt[:disp]+':00').to_time.to_i
					@trips << bt
					break
				end
			end
		end
		@trips.sort! {|x,y| x[:timestamp] <=> y[:timestamp] }
	end
	
	def _prep_reports
		last_day = ''
		last_day_count = 0
		@trips.each do |trip|			
			disp_str = self.getTripTimeStr trip, :disp
			scn_str  = self.getTripTimeStr trip, :scn
			dept_str = self.getTripTimeStr trip, :dept
			hosp_str = self.getTripTimeStr trip, :hosp
			td = (DateTime.parse(scn_str).to_time.to_i - DateTime.parse(disp_str).to_time.to_i) / 60  #time_dif(trip[:scn], trip[:disp])
			if(trip[:pri] == '1' || trip[:pri] == '2')
				@pri1_trips << trip
				@resp_times1 << td
				if td > 8
					@expired_trips << trip
				end
			elsif trip[:pri] == '3'
				@pri3_trips << trip
				@resp_times3 << td
				if td > 30
					@expired_trips3 << trip
				end
			end
			if(last_day != trip[:date])
				if(last_day != '')
					@days << last_day_count
				end
				last_day = trip[:date]
				last_day_count = 1
			else
				last_day_count += 1
			end
			scn_time = (DateTime.parse(dept_str).to_time.to_i - DateTime.parse(scn_str).to_time.to_i) / 60
			to_hosp_time = (DateTime.parse(hosp_str).to_time.to_i - DateTime.parse(dept_str).to_time.to_i) / 60
			total_time = (DateTime.parse(hosp_str).to_time.to_i - DateTime.parse(disp_str).to_time.to_i) / 60
			@scn_times << scn_time
			@to_hosp_times << to_hosp_time
			@total_times << total_time
		end
		if(last_day != '')
			@days << last_day_count
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
		if(/^Date: (.*)/ =~ line)
			@mail[:date] = $1.strip.gsub(/ [0-9]+:[0-9]+:[0-9]+.*$/, '')
		elsif(/AMB:(.*)PRI:(.*)ADD:(.*)APT:(.*)NATURE:(.*)TRIP:([0-9]+)\-([0-9]+) *TIME:(.*)/ =~ line)
			if(!_tripNumExistsIn($7.strip, @begin_trips))
				@mail[:amb] = $1.strip
				@mail[:pri] = $2.strip
				@mail[:addr] = $3.strip
				@mail[:apt] = $4.strip
				@mail[:nature] = $5.strip
				@mail[:trip_prefix] = $6.strip
				@mail[:trip] = $7.strip
				disp = $8.strip
				@mail[:disp] = @mail[:date]+' '+ disp +':00 '
				@mail[:addr] = @mail[:addr].gsub(/[a-zA-Z0-9\`\~\!\@\#\$\%\^\&\*\(\)\_\-\+\=\[\{\]\}\\\|\'\"\;\:\/\?\.\>\,\<]/, '*')
				@begin_trips << @mail
			end
		elsif(/TRIP: *([0-9]+)\-([0-9]+) *AtScn: *(.*)DepScn: *(.*)AtHosp: *(.*)Miles: *(.*)/ =~ line)
			if(!_tripNumExistsIn($2.strip, @end_trips))
				@mail[:trip_prefix] = $1.strip
				@mail[:trip] = $2.strip
				@mail[:scn] = $3.strip
				@mail[:dept] = $4.strip
				@mail[:hosp] = $5.strip
				@mail[:miles] = $6.strip
				@end_trips << @mail
			end
		end
	end
	def _parseEmail email
		if /^(.+)@(.+)$/ =~ email
			user = $1
			host = $2
			if /^(.+)\/(.+)$/ =~ host
				return user, $1, $2
			end
			return user, host, nil
		end
		puts "%s is not a valid email address" % email
		return nil, nil
	end
end

argc = ARGV.length
if(argc > 0 && argc < 5)
	tp = TripParser.new
	opened = false
	salt = false
	if(argc > 1)
		ARGV.each do |v|
			if /^\-no_stdout:(.*)/ =~ v
				tp.set_status_filename $1
				$stdout = File.open $1, "w"
				argc -= 1
			elsif /^\-salt/ =~ v
				salt = true
				argc -= 1
			end
		end
	end
	puts "**START"
	puts "status filename: "+tp.status_filename
	puts "report file prefix: "+tp.report_file_prefix
	if(argc == 2)
		if(salt)
			pss = Salt::decode(ARGV[1], ARGV[0])
		else
			pss = ARGV[1]
		end
		opened = tp.open_remote(ARGV[0], pss)
	elsif(argc== 1) 
		opened = tp.open_local ARGV[0]
	end
	if opened
		tp.cl_report
		tp.txt_report
		tp.xml_report
		tp.html_report
		tp.comma_report
	end
	puts "END**"
else
	puts "USAGE: ruby trip-parser.rb email password\n\tOR\nUSAGE: ruby trip-parser.rb local_filepath"
end