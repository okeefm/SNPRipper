require 'net/http'
require 'uri'
require 'mechanize'
require 'fileutils'

base_url = 'http://phenome.jax.org/db/q?'
gene = 'PRKCZ'
regex = /(http:\/\/phenome\.jax\.org\/tmp\/..+\.txt)/i
genes = Array.new
failures = Array.new

agent = Mechanize.new


File.foreach("line separated genes.txt") do |line|
		genes.push(line)
end

FileUtils.mkdir_p('data')
FileUtils.cd('data')

genes.each do |gene|
	url = URI.parse(base_url)
	req = Net::HTTP::Post.new(url.path)
	req.set_form_data({'rtn' => 'snps/retrieve', 'gregion' => 'gene', 'showmergelist' => 'yes', 'genesym' => gene, 'proj' => 'CGD1', 'marginamt' => '.010'}, '&')
	res = Net::HTTP.new(url.host, url.port).start { |http|
		http.request(req)
	}

	case res
		when Net::HTTPSuccess, Net::HTTPRedirection
			page = res.body
			link = regex.match(page)
			if link.nil?  
				 failures.push(gene)
			else
				text_response = agent.get(link)
				if !gene.nil?
					File.open("mpd " + gene.strip + ".txt", 'w') do |outfile|
						outfile << text_response.body
					end
					puts "Success with #{gene}"
				end
			end
		else
			res.error!
	end
end

File.open("gene_failures.txt", 'w') do |file|
	failures.each do |failure|
		file.syswrite(failure)
	end
end

	