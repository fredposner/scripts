#!/usr/bin/perl
use Crypt::Eksblowfish::Bcrypt;
use Crypt::Random;
use strict;
use warnings;

# 
# simple hash example with bcrypt from perl
# props to / heavily influenced by:
# -> https://perlmaven.com/storing-passwords-in-a-an-easy-but-secure-way
# -> https://gist.github.com/gcrawshaw/1071698
#

#
# this is really just a test, so we need two variables
# ARGV[0] is the plain text password
# ARGV[1] is either (a) "encrypt" or (b) the hash
#
# so, usage would be...
# hash-bcrypt.pl "MyPassWord" "encrypt"
# hash-bcrypt.pl "MyPassWord" [hash]
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
	$encrypted = encrypt_password($password);
	print "$password is encrypted as $encrypted\n";
} else {
	if (check_password($password, $hash)) {
		print "good password\n";
	} else {
		print "bad password\n";
	}
}

# 
# Lets do some subroutines
#
sub encrypt_password {
	my $password = shift;
	my $salt = shift || salt(); 

	# Set the cost to 8 and append a NUL
	my $settings = '$2a$08$'.$salt;

	# Encrypt and return
	return Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings);
}

sub check_password {
	my ($plain_password, $hashed_password) = @_;

 	# Regex to extract the salt
 	if ($hashed_password =~ m!^\$2a\$\d{2}\$([A-Za-z0-9+\\.]{22})!) {
		# Use a letter by letter match rather than a complete string match to avoid timing attacks
		my $match = encrypt_password($plain_password, $1);
		my $bad = 0;

		for (my $n=0; $n < length $match; $n++) {
			$bad++ if substr($match, $n, 1) ne substr($hashed_password, $n, 1);
		}

		return $bad == 0;
	} else {
		return 0;
 	 }
}

sub salt {
	return Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::Random::makerandom_octet(Length=>16));
}
