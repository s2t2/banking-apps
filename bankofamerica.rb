require "pry"
require "capybara/poltergeist"

CREDS = {
  :username => ENV['BANK_OF_AMERICA_USERNAME'],
  :password => ENV['BANK_OF_AMERICA_PASSWORD'],
  :challenge_sibling => ENV["BANK_OF_AMERICA_CHALLENGE_SIBLING"],
  :challenge_pet => ENV["BANK_OF_AMERICA_CHALLENGE_PET"]
}

CREDS.each do |k,v|
  raise "MISSING CREDENTIAL -- #{k}" unless !v.nil?
end

SESSION_ID = "#{Time.new.strftime("%Y%m%d%H%M%S")}-#{rand(10**10)}"

def session_path
  File.join("sessions", SESSION_ID)
end

def print_page(session, name)
  pp "------------------------"
  pp session.current_path
  pp session.current_host
  pp session.current_url
  pp session.title
  pp session.status_code
  pp session.response_headers

  FileUtils.mkdir_p(session_path)
  session.save_screenshot("#{session_path}/#{name}.png")
  session.save_page("#{session_path}/#{name}.html")
  pp "------------------------"
end

#
# Visit the login page
#

session = Capybara::Session.new(:poltergeist)
session.visit("https://www.bankofamerica.com/")

#
# Login using your username and password
#

print_page(session, "1-login")

session.fill_in("onlineId1", with: CREDS[:username])
session.fill_in("passcode1", with: CREDS[:password])
session.click_on("hp-sign-in-btn")

#
# Answer the challenge question
#

print_page(session, "2-challenge")

if session.has_content?("What is your oldest sibling's middle name?")
  session.fill_in("tlpvt-challenge-answer", :with => CREDS[:challenge_sibling])
elsif session.has_content?("What was the name of your first pet?")
  session.fill_in("tlpvt-challenge-answer", :with => CREDS[:challenge_pet])
else
  puts "UNRECOGNIZED CHALLENGE QUESTION"
  binding.pry
ensure
  session.choose("no-recognize")
  session.click_link("verify-cq-submit")
end


#
# Get Accounts
#

print_page(session, "3-accounts")

# click on an Account link

# click "Download"
# ... then loop through each Transaction Period, starting with the first/earliest
# ... then choose "Microsoft Excel format"
# ... then click "Download Transactions"

# locate ~/Downloads/stmt.csv and mv ~/Downloads/stmt.csv ~/Desktop/banking-apps/bofa_transactions_20150206.csv
