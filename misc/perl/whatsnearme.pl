#!/usr/bin/perl -w
# original author:
# David Farrell
# perltricks.com
use strict;
use warnings;
use feature 'say';
use Net::ARP;
use Net::Address::IP::Local;
use Net::Frame::Device;
use Net::Frame::Dump::Online;
use Net::Frame::Simple;
use Net::Netmask;
use Net::Pcap ();
use URI::Escape;

my $network_device_name = $ARGV[0] if @ARGV;

unless ($network_device_name) {
	$network_device_name = Net::Pcap::pcap_lookupdev(\my $error_msg);
	die "pcap device lookup failed " . ($error_msg || '')
	if $error_msg || not defined $network_device_name;
}

my $device = Net::Frame::Device->new(dev => $network_device_name);

my $pcap = Net::Frame::Dump::Online->new(
	dev => $network_device_name,
	filter => 'arp and dst host ' . $device->ip,
	promisc => 0,
	unlinkOnStop => 1,
	timeoutOnNext => 10
);

printf "Gateway IP: %s\nStarting scan\n", $device->gatewayIp;

$pcap->start;

for my $ip_address (Net::Netmask->new($device->subnet)->enumerate) {
	Net::ARP::send_packet(
		$network_device_name,
		$device->ip,
		$ip_address,
		$device->mac,
		"ff:ff:ff:ff:ff:ff", # broadcast
		"request",
	);
}

until ($pcap->timeout) {
	if (my $next = $pcap->next) {
		my $frame = Net::Frame::Simple->newFromDump($next);
		my $local_ip = Net::Address::IP::Local->public;
		my $frame_ip = $frame->ref->{ARP}->srcIp;
		my $frame_mac = $frame->ref->{ARP}->src;
		my $encmac = uri_escape($frame_mac);
		my $vendor = qx(curl -m 2 -s http://api.macvendors.com/$encmac);
		if ($vendor) {
			say "$frame_ip $frame_mac $vendor". ($local_ip eq $frame_ip ? ' (this machine)' : '');
		} else {
			say "$frame_ip $frame_mac". ($local_ip eq $frame_ip ? ' (this machine)' : '');
		}
	}
}
END { say "Exiting."; $pcap->stop }
