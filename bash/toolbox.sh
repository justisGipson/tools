#!/bin/bash

# This script performs various advanced network tasks using CLI tools available on OSX.
# Trying to replicate as much of what mxtoolbox can do in one script.
# Here's how to use the script:
#
#  1. Open a terminal window.
#  2. Navigate to the directory where you saved the script.
#  3. Type `chmod +x toolbox.sh` to make the script executable.
#  4. Type `./toolbox.sh <command> <argument>` to run the script,
#  where `<command>` is the task you want to perform and
#  `<argument>` is the domain name or IP address you want to look up.
#
#  For example, to perform an MX lookup for example.com, you would type:
#  ./toolbox.sh mxlookup example.com

# Define the functions for each task

mxlookup() {
  dig mx "$1" +noall +answer
}

blacklist() {
  host -t a "$1".spamhaus.org
}

dnslookup() {
  dig "$1" +noall +answer
}

testemail() {
  telnet "$1" 25
  # Type the following commands in the telnet session:
  # HELO example.com
  # MAIL FROM: test@example.com
  # RCPT TO: test@example.com
  # DATA
  # Subject: Test email
  # This is a test email.
  # .
  # QUIT
}

reverselookup() {
  dig -x "$1" +noall +answer
}

spf() {
  dig txt "$1" +noall +answer | grep "v=spf1"
}

dkim() {
  dig txt _domainkey."$1" +noall +answer
}

dmarc() {
  dig txt _dmarc."$1" +noall +answer
}

aaaa() {
  dig aaaa "$1" +noall +answer
}

srv() {
  dig srv "$1" +noall +answer
}

dnskey() {
  dig dnskey "$1" +noall +answer
}

cert() {
  openssl s_client -connect "$1":443 -servername "$1" -showcerts </dev/null | openssl x509 -noout -text
}

loc() {
  dig loc "$1" +noall +answer
}

ipsec() {
  dig ipseckey "$1" +noall +answer
}

domainhealth() {
  curl -s https://mxtoolbox.com/domain/"$1" | grep "class=\"resultTitle\""
}

asn() {
  whois -h whois.cymru.com " -v $1"
}

rrsig() {
  dig +dnssec +noall +answer "$1" RRSIG | grep RRSIG
}

nsec() {
  dig +dnssec +noall +answer "$1" NSEC | grep NSEC
}

ds() {
  dig +dnssec +noall +answer "$1" DS | grep DS
}

nsec3param() {
  dig +dnssec +noall +answer "$1" NSEC3PARAM | grep NSEC3PARAM
}

bimi() {
  curl -s https://bimivalidator.org/lookup/?domain="$1" | grep -A 1 "BIMI record found for"
}

mtasts() {
  curl -v https://"$1"/.well-known/mta-sts.txt
}

whatsmyip() {
  curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'
}

cnamelookup() {
  dig cname "$1" +noall +answer
}

txtlookup() {
  dig txt "$1" +noall +answer
}

soalookup() {
  dig soa "$1" +noall +answer
}

tcplookup() {
  nc -vz "$1" "$2"
}

httplookup() {
  curl -I http://"$1"
}

httpslookup() {
  curl -I https://"$1"
}

pinglookup() {
  ping "$1"
}

tracelookup() {
  tracert "$1"
}

# Check if the user has provided a command-line argument

if [ $# -eq 0 ]; then
  echo "Please provide a command-line argument."
  exit 1
fi

# Call the appropriate function based on the command-line argument

case $1 in
mxlookup) mxlookup "$2" ;;
blacklist) blacklist "$2" ;;
dnslookup) dnslookup "$2" ;;
testemail) testemail "$2" ;;
reverselookup) reverselookup "$2" ;;
spf) spf "$2" ;;
dkim) dkim "$2" ;;
dmarc) dmarc "$2" ;;
aaaa) aaaa "$2" ;;
srv) srv "$2" ;;
dnskey) dnskey "$2" ;;
cert) cert "$2" ;;
loc) loc "$2" ;;
ipsec) ipsec "$2" ;;
domainhealth) domainhealth "$2" ;;
asn) asn "$2" ;;
rrsig) rrsig "$2" ;;
nsec) nsec "$2" ;;
ds) ds "$2" ;;
nsec3param) nsec3param "$2" ;;
bimi) bimi "$2" ;;
mtasts) mtasts "$2" ;;
whatsmyip) whatsmyip ;;
cnamelookup) cnamelookup "$2" ;;
txtlookup) txtlookup "$2" ;;
soalookup) soalookup "$2" ;;
tcplookup) tcplookup "$2" "$3" ;;
httplookup) httplookup "$2" ;;
httpslookup) httpslookup "$2" ;;
pinglookup) pinglookup "$2" ;;
tracelookup) tracelookup "$2" ;;
*) echo "Invalid command-line argument." ;;
esac

exit 0
