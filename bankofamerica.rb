require "pry"
require "capybara/poltergeist"

CREDS = {
  :username => ENV['BANK_OF_AMERICA_USERNAME'],
  :password => ENV['BANK_OF_AMERICA_PASSWORD'],
  :challenge_sibling => ENV["BANK_OF_AMERICA_CHALLENGE_SIBLING"],
  :challenge_pet => ENV["BANK_OF_AMERICA_CHALLENGE_PET"],
  :challenge_employer => ENV["BANK_OF_AMERICA_CHALLENGE_EMPLOYER"]
}

CREDS.each do |k,v|
  raise "MISSING CREDENTIAL -- #{k}" unless !v.nil?
end

SESSION_ID = "#{Time.new.strftime("%Y%m%d%H%M%S")}-#{rand(10**10)}"

def session_path
  File.join("bankofamerica","sessions", SESSION_ID)
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
elsif session.has_content?("What is the name of your first employer?")
  session.fill_in("tlpvt-challenge-answer", :with => CREDS[:challenge_employer])
else
  puts "UNRECOGNIZED CHALLENGE QUESTION"
  binding.pry
end
session.choose("no-recognize") if session.has_content?("no-recognize")
session.click_link("verify-cq-submit")

#
# Get Accounts
#

print_page(session, "3-accounts")

account_links = session.find_all(".AccountName")
account_links.each do |account_link|
  name = account_link.text.split(" - ").first
  last_four = account_link.text.split(" - ").last

  #
  # Click on an Account
  #

  session.click_link(account_link.text)

  print_page(session, "4-account-#{name}-#{last_four}")

  #
  # click "Download"
  #
  # ... then loop through each Transaction Period, starting with the first/earliest
  # ... then choose "Microsoft Excel format"
  # ... then click "Download Transactions"
  # locate ~/Downloads/stmt.csv and mv ~/Downloads/stmt.csv ~/Desktop/banking-apps/bofa_transactions_20150206.csv

  expand_download_options_link = session.find(:css, ".export-trans-view.download-upper")
  expand_download_options_link.click

  print_page(session, "4-account-#{name}-#{last_four}-download-options")

  #transaction_period_selector = session.find("#select_txnperiod")
  #transaction_periods = transaction_period_selector.all("option")
  #transaction_periods.each do |transaction_period|
    #period_name = transaction_period.text
    #session.select(period_name, :from => 'Transaction period')

    session.select("Current transactions", :from => 'Transaction period')
    session.select("Microsoft Excel Format", :from => 'select_filetype')
    download_button = session.find(:css, ".btn-bofa.btn-bofa-blue.btn-bofa-small.submit-download.btn-bofa-noRight")
    download_button.click

    #raise "NO TRANSACTIONS FOR PERIOD" if session.has_content?("The time period you have requested to download has no posted transactions. Please select a new date range.")

  #end
end
