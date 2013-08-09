#!/usr/bin/perl

# This file is part of ovirt-Monitoring UI-Plugin.
#
# ovirt-Monitoring UI-Plugin is free software: you can redistribute it 
# and/or modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation, either version 3 of the i
# License, or (at your option) any later version.
#
# ovirt-Monitoring UI-Plugin is distributed in the hope that it will be 
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ovirt-Monitoring UI-Plugin.  
# If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;

use Template;
use CGI qw(param referer);
use CGI::Carp qw(fatalsToBrowser);
use CGI::Fast;

# for debugging only
use Data::Dumper;

# define default paths required to read config files
my ($lib_path, $cfg_path);
BEGIN {
  $lib_path = "../lib";		# path to BPView lib directory
  $cfg_path = "../etc";		# path to BPView etc directory
}

# load custom Perl modules
use lib "$lib_path";
use oVirtUI::Config;
use oVirtUI::Web;
use oVirtUI::Data;


### The main script starts here

# open config files
my $conf	= oVirtUI::Config->new();
# open config file directory and push configs into hash
my $config	= $conf->read_dir( 'dir' => $cfg_path );
# validate config
exit 1 unless ( $conf->validate( 'config' => $config ) == 0);

# read static mappings config
my $mappings = $conf->read_dir( 'dir' => $cfg_path . "/mappings" );
# Todo: validate mappings!


# loop for FastCGI
while ( my $q = new CGI::Fast ){

  # process URL
  if (defined param){

    if (defined param("results")){	
  	
      print "Content-type: text/html\n\n";
      
      # display web page
      my $page = oVirtUI::Web->new(
 		data_dir	=> $config->{ 'ui-plugin' }{ 'data_dir' },
 		site_url	=> $config->{ 'ui-plugin' }{ 'site_url' },
 		template	=> $config->{ 'ui-plugin' }{ 'template' },
	  );
      $page->display_page(
    	page		=> "results",
    	content		=> param("host"),		# get name of vm/host
    	component	=> param("results"),
    	refresh		=> $config->{ 'refresh' }{ 'interval' },
    	template_cache	=> $config->{ 'ui-plugin' }{ 'template_cache' }
	  );

    }elsif (defined param("host")){
    	
  	  # JSON Header
      print "Content-type: application/json charset=iso-8859-1\n\n";
      my $json = undef;
  	
  	  # get services for specified host
      my $services = oVirtUI::Data->new(
    	 provider	=> $config->{ 'provider' }{ 'source' },
    	 provdata	=> $config->{ $config->{ 'provider' }{ 'source' } },
      );	
      
      # does hostname differ in oVirt and Nagios?
      my $host = param("host");
      my $checks = undef;

      # datacenters, clusters, storage and pools are mapped differently as the hostname
      # and services names for these checks have to be given in mappings file  
      if (param("comp") eq "vms" || param("comp") eq "hosts"){
      
        chomp $host;
        foreach my $map (keys %{ $mappings }){
      	  $host = $mappings->{ $map } if $host eq $map;
        }
        
      }else{
      	
      	# process datacenters, clusters, storage and pools
      	$host = $mappings->{ 'ovirt' }{ param("comp") }{ param("host") }{ 'host' };
      	$checks = $mappings->{ 'ovirt' }{ param("comp") }{ param("host") }{ 'services' };
      	
      }
    
      # is service given, too then get details for service
      # else get all services for this host
      if (defined param("service")){
    	
        $json = $services->get_details(	'host'		=> $host,
      									'service'	=> param("service")
      								);
    	
      }else{
        $json = $services->get_services( 'host'		=> $host,
        								 'service'	=> $checks
        							);
      }
    
      print $json;
    
    }elsif (defined param("graph")){
  	
  	  # JSON Header
      print "Content-type: application/json charset=iso-8859-1\n\n";
      my $json = undef;  
      
      # do hostname differ in oVirt and Nagios?
      my $host = param("graph");
      chomp $host;
      foreach my $map (keys %{ $mappings }){
      	if ($host eq $map){
      	  $host = $mappings->{ $map };
      	}
      }
    
      # get graphs for specified service
      my $graphs = oVirtUI::Data->new(
    	 provider	=> $config->{ 'graphs' }{ 'source' },
    	 provdata	=> $config->{ $config->{ 'graphs' }{ 'source' } }
      );
       
      $json = $graphs->get_graphs( 	'host'		=> $host,
    								'service'	=> param("service") );
    
      print $json;

    }
	
  }

}


exit 0;

