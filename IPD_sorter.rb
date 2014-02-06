#!/usr/bin/ruby

require 'open-uri' #links to IPD database webpage
require 'set' #set implements a collection of unordered values with no duplicates 
require 'rubygems' #taught script about gem
require 'bio' #specifies bio gem

# set default email address for E-Utils
Bio::NCBI.default_email = "youremail@uvm.edu"

# instantiate the ncbi_search & ncbi_fetch variable
ncbi_search = Bio::NCBI::REST::ESearch.new  
ncbi_fetch = Bio::NCBI::REST::EFetch.new

# introduce script
puts "Hello! Welcome to BoLA IPD!"

#Prompts user for serach terms 
puts "What column would you like to search in IPD?"
puts "Please select from the following: \n1) Allele Name \n2) Serological Specificity \n3) Breed type \n4) Retrieve all"

#\n makes a new line

# if get response from <STDIN>
search_type = gets.chomp
if search_type=='1' or search_type=='2' or search_type=='3'
	puts "What would you like to search for?" 
	search_query = gets.chomp
elsif search_type=='4' 
	search_query = "All"
else
	puts "An invalid value was entered.  Please enter 1-4."
	exit()
end

#m means new lines are included in dot. 
#i mean ignore case sensitive 
#need to parse the webpage
html = open("http://www.ebi.ac.uk/cgi-bin/ipd/mhc/view_nomenclature.cgi?bola.classi").read

#Scan-find text in table format
table_data = html.scan /<tr.+?tr>/mi  

output_fasta_file = File.open("#{search_query}.fasta", "w")	

count = 0 
# Created a loop with regular expressions to parse the webpage
table_data.each do |data|	
	if data =~ /<td.*?>(.*)<\/td>.*?<td.*?>(.*)<\/td>.*?<td.*?>(.*)<\/td>.*?<td.*?>(.*)<\/td>.*?<td.*?>(.*)<\/td>.*?<td.*?>(.*)<\/td>/mi
		allele_name = $1
		local_name = $2
		accession_number = $3
		serological_specificity = $4
		breed_type = $5
		reference = $6
		
		accession_numbers = accession_number.scan /<a href.*?>(.*?)<\/a>/ 

		#gsub returns a copy of string with all occurrences of pattern substituted for a second argument 
		breed_type = breed_type.gsub(/,/,"") #gets rid of br and replaces it with empty string
		breed_type = breed_type.gsub(/\s*<br.*?>/,",")

		breed_types = breed_type.scan /([^,]+)/ 

		if search_type == "1"

			if allele_name.upcase.include? search_query.upcase
				count+=1
				breed_types.zip(accession_numbers).each do |bt,an|
					fasta_sequence = ncbi_fetch.sequence(an,"fasta")
					dna_fasta = Bio::FastaFormat.new(fasta_sequence)
					output_fasta_file.puts"> #{allele_name} | #{an} | #{bt}"
					output_fasta_file.puts"#{dna_fasta.seq}"
				end 
			end
		elsif search_type == "2"
			if serological_specificity.upcase.include? search_query.upcase
				count+=1
				breed_types.zip(accession_numbers).each do |bt,an|
					fasta_sequence = ncbi_fetch.sequence(an,"fasta")
					dna_fasta = Bio::FastaFormat.new(fasta_sequence)
					output_fasta_file.puts"> #{allele_name} | #{an} | #{bt}"
					output_fasta_file.puts"#{dna_fasta.seq}"
				end 
			end
		elsif search_type == "3"
			breed_types.zip(accession_numbers).each do |bt,an|
				if "#{bt}".upcase.include? search_query.upcase
					count+=1 
					fasta_sequence = ncbi_fetch.sequence(an,"fasta")
					dna_fasta = Bio::FastaFormat.new(fasta_sequence)
					output_fasta_file.puts"> #{allele_name} | #{an} | #{bt}"
					output_fasta_file.puts"#{dna_fasta.seq}"
				end
			end

		elsif search_type == "4"
			breed_types.zip(accession_numbers).each do |bt,an|
				count+=1 
				fasta_sequence = ncbi_fetch.sequence(an,"fasta")
				dna_fasta = Bio::FastaFormat.new(fasta_sequence)
				output_fasta_file.puts"> #{allele_name} | #{an} | #{bt}"
				output_fasta_file.puts"#{dna_fasta.seq}"
			end		
		end
	end	
end

if search_type == "1" or search_type == "4"
	puts "There are #{count} alleles in your search!"
end

if search_type == "2"
	puts "There are #{count} serological specificities in your search!"
end

if search_type == "3"
	puts "There are #{count} accession numbers for your breed in this search!"
end



output_fasta_file.close 

