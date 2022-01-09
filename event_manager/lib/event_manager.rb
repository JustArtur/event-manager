require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

Dir.mkdir("output") unless File.exist?("output")

def clean_zip(zip)
  zip.to_s.rjust(5, "0")[0, 5]
end

def representative_info_by_zip(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  filename = "output/letter_#{id}.html"
  File.open(filename, 'w').puts form_letter
end

def clean_reg_date(reg_date)
  DateTime.strptime(reg_date, '%m/%d/%Y %H:%M')
end

def output_peak_hours(hash)
  puts "Three most peak hours:"
  hash.sort_by(&:last).last(3).each { |obj| puts "#{obj[0]} hour - #{obj[1]} time registrations " }
end

def output_peak_days_of_week(hash)
  puts "Three most peak wday:"
  hash.sort_by(&:last).last(3).each { |obj| puts "#{obj[0]} day of week - #{obj[1]} time registrations" }
end

content = CSV.open('../event_attendees_full.csv',
                   headers: true,
                   header_converters: :symbol)

template_letter = File.read("../form_letter.erb")
erb_template = ERB.new(template_letter)
hours = Hash.new(0)
days_of_week = Hash.new(0)

content.each do |line|
  id = line[0]
  reg_date = clean_reg_date(line[:regdate])
  legislators = representative_info_by_zip(clean_zip(line[:zipcode]))
  name = line[:first_name]
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
  hours[reg_date.hour] += 1
  days_of_week[reg_date.wday] += 1
end

output_peak_hours(hours)
output_peak_days_of_week(days_of_week)
print hours
puts
print days_of_week