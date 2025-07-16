#!/usr/bin/perl
use Crypt::ScryptKDF qw(scrypt_hash scrypt_hash_verify);
use strict;
use warnings;

# 
# simple hash example with bcrypt from perl
# props to / heavily influenced by:
# -> https://perlmaven.com/storing-passwords-in-a-an-easy-but-secure-way
#

#
# this is really just a test, so we need two variables
# ARGV[0] is the plain text password
# ARGV[1] is either (a) "encrypt" or (b) the hash
#
# so, usage would be...
# hash-scrypt.pl "MyPassWord" "encrypt"
# hash-scrypt.pl "MyPassWord" [hash]
# if you're sending the hash from the cli, don't forget to /$ the $'s
#

my ($password, $hash, $encrypted);

if ($ARGV[0]) {
	$password = $ARGV[0];
} else {
	print "need password\n";
	exit(0);
}

if ($ARGV[1]) {
	if ($ARGV[1] ne "encrypt") {
		$hash = $ARGV[1];
	} else {
		$hash = "encrypt";
	}
} else {
	print "need hash or action\n";
	exit(0);
}


if ($hash eq "encrypt") {
	$encrypted = scrypt_hash($password, \32);
	print "$password is encrypted as $encrypted\n";
} else {
	if (scrypt_hash_verify($password, $hash)) {
		print "good password\n";
	} else {
		print "bad password\n";
	}
}

