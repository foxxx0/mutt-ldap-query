#! /usr/bin/perl
# Use it with mutt by putting in your .muttrc:
# set query_command = "~/bin/mutt-ldap-query.pl '%s'"

use autodie;
use warnings;
use strict;
use Config::Simple;
use Data::Dumper;
use File::Basename;
use Getopt::Long;
use Net::LDAPS;
use POSIX ();

my %opts;
my $ldaph;

sub debug {
	say STDERR @_ if $opts{debug};
}

sub print_usage {
	print "Usage: mutt-ldap-query.pl [-d] [-c config.ini] <search keywords>\n";
	printf "\t%-20s\t%s\n", "-d, --debug", "enable debug output";
	printf "\t%-20s\t%s\n", "", "also usable by setting MUTT_LDAP_QUERY_DEBUG to 1";
	printf "\t%-20s\t%s\n", "-c, --config <file>", "specify an alternate config file";
	printf "\t%-20s\t%s\n", "", "also usable by setting MUTT_LDAP_QUERY_CONFIG to the config file path";
	printf "\t%-20s\t%s\n", "", "(command line parameter takes precedence over ENV var)";
	printf "\t%-20s\t%s\n", "", "defaults to: '\$XDG_CONFIG_HOME/mutt-ldap-query/config.ini'";
}

sub ldap_search {
	my $basedn = shift;
	my $search = shift;

	if (!$search=~/[\.\*\w\s]+/) {
		print("Invalid search parameters\n");
		exit 1;
	}

	my $mesg = $ldaph->search(
		base => $basedn,
		filter => "(|(cn=*$search*) (rdn=*$search*) (uid=*$search*) (mail=*$search*))",
		attrs => ['mail','cn']
	);

	$mesg->code && die $mesg->error;
	debug("ldap result: ", Dumper($mesg));

	print(scalar($mesg->all_entries), " entries found\n");

	foreach my $entry ($mesg->all_entries) {
		if ($entry->get_value('mail')) {
			print($entry->get_value('mail'),"\t",
				  $entry->get_value('cn'),"\tFrom LDAP database\n");
		}
	}
}

sub main {
	Getopt::Long::Configure("bundling");
	GetOptions(
		\%opts,
		"help|h",
		"debug|d",
		"config|c=s"
	) or exit 1;

	if($opts{help}) {
		print_usage();
		return 0;
	}

	$opts{debug} = 1 if ($ENV{'MUTT_LDAP_QUERY_DEBUG'} && $ENV{'MUTT_LDAP_QUERY_DEBUG'} == 1);

	my $config_file = undef;
	if ($ENV{'XDG_CONFIG_HOME'}) {
		$config_file = $ENV{'XDG_CONFIG_HOME'};
	} else {
		$config_file = $ENV{'HOME'};
	}
	$config_file .= '/mutt-ldap-query/config.ini';

	$config_file = $ENV{'MUTT_LDAP_QUERY_CONFIG'} if ($ENV{'MUTT_LDAP_QUERY_CONFIG'});
	$config_file = $opts{config} if ($opts{config});

	if (! -f $config_file) {
		say STDERR "ERROR: unable to read config from: $config_file\n";
		exit 2;
	}
	debug("config_file: ", $config_file);

	my $cfg = new Config::Simple($config_file);
	debug("config: ", Dumper($cfg));

	my $search_string = join(" ", @ARGV);
	debug("search_string: ", $search_string);

	$ldaph = Net::LDAPS->new($cfg->param('ldap.server')) or die "$@";
	$ldaph->bind("$cfg->param('ldap.domain')\\$cfg->param('ldap.username')",
		password=>$cfg->param('ldap.password'));

	ldap_search($cfg->param('ldap.basedn'), $search_string);

	$ldaph->unbind();
	return 0;
}

exit main();
