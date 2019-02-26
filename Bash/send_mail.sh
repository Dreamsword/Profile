#!/usr/bin/expect

set timeout 30
proc abort {} { exit 2 }

spawn nc -C hein.rocketseed.com 25
expect default abort "220 "
send "HELO jhbfw.rocketseed.com\r"
expect default abort "\n250 "
send "MAIL FROM:user@example.com\r"
expect default abort "\n250 "
send "RCPT TO:user@example.com\r"
expect default abort "\n250 "
send "DATA\r"
expect default abort "\n354 "
send "Content-Type: text/plain; charset=us-ascii\r"
send "Subject: Good Day [rs_378]\r"
send "\r"
send "Testing\r"
send ".\r"
expect default abort "\n250 "
send "QUIT\r"
