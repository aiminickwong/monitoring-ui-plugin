#!/usr/bin/perl

# COPYRIGHT:
#
# This software is Copyright (c) 2013 by René Koch
#                             <r.koch@ovido.at>
#
# This file is part of Monitoring UI-Plugin.
#
# (Except where explicitly superseded by other copyright notices)
# Monitoring UI-Plugin is free software: you can redistribute it 
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of 
# the License, or any later version.
#
# Monitoring UI-plugin is distributed in the hope that it will be 
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Monitoring UI-Plugin.  
# If not, see <http://www.gnu.org/licenses/>.


package oVirtUI::Data;

BEGIN {
    $VERSION = '0.330'; # Don't forget to set version and release
}  						# date in POD below!

use strict;
use warnings;
use YAML::Syck;
use Carp;
use File::Spec;
use JSON::PP;

# for debugging only
#use Data::Dumper;


=head1 NAME

  oVirtUI::Data - Connect to data backend

=head1 SYNOPSIS

  use oVirtUI::Data;
  my $details = oVirtUI::Data->new(
  		provider	=> 'ido',
  		provdata	=> $provdata,
  		host		=> $host,
  	 );
  $json = $details->get_services();

=head1 DESCRIPTION

This module fetches service details for given hosts from various backends like
IDOutils and mk-livestatus.

=head1 CONSTRUCTOR

=head2 new ( [ARGS] )

Creates an oVirtUI::Data object. <new> takes at least the provider and provdata.
Arguments are in key-value pairs.
See L<EXAMPLES> for more complex variants.

=over 4

=item provider

name of datasource provider (supported: ido|mk-livestatus)

=item provdata

provider specific connection data

IDO:
  host: hostname (e.g. localhost)
  port: port (e.g. 3306)
  type: mysql|pgsql
  database: database name (e.g. icinga)
  username: database user (e.g. icinga)
  password: database password (e.g. icinga)
  prefix: database prefix (e.g. icinga_)
  
mk-livestatus:
  socket: socket of mk-livestatus
  server: ip/hostname of mk-livestatus
  port: port of mk-livestatus

=item host

name of Icinga host object to query service details from
required for oVirtUI::Data->get_services()

=cut


sub new {
  my $invocant	= shift;
  my $class 	= ref($invocant) || $invocant;
  my %options	= @_;
    
  my $self 		= {
  	"host"		=> undef,	# name of host to query data for
  	"service"	=> undef,	# name of service to query data for
  	"provider"	=> "ido",	# provider (ido | mk-livestatus)
  	"provdata"	=> undef,	# provider details like hostname, username,... 
  };
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
  
  # parameter validation
  # TODO!
  
  bless $self, $class;
  return $self;
}


#----------------------------------------------------------------

=head1 METHODS	

=head2 get_services

 get_services ( 'host' => $host )

Connects to backend and queries service status of given host.
Returns JSON data.

  my $json = $details->get_services( 'host' => $host );                              	

=cut

sub get_services {
	
  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
  
  my $result = undef;
  # fetch data from Icinga/Nagios
  if ($self->{'provider'} eq "ido"){
  	
  	# construct SQL query
  	my $sql;
    # Is service defined?
    # Service must be given for components like datacenters, clusters, storage and pools
  
  	if (defined $self->{ 'service' }){
  	  $sql = $self->_query_ido( $self->{ 'host' }, $self->{ 'service' } );
  	}else{
  	  $sql = $self->_query_ido( $self->{ 'host' } );
  	}
  	# get results
  	$result = eval { $self->_get_ido( $sql ) };
  	
  }elsif ($self->{'provider'} eq "mk-livestatus"){
  	
  	# construct query
  	my $query;
  	# Is service defined?
    # Service must be given for components like datacenters, clusters, storage and pools
    
    if (defined $self->{ 'service' }){
      $query = $self->_query_livestatus( $self->{ 'host' }, $self->{ 'service' });
    }else{	
  	  $query = $self->_query_livestatus( $self->{ 'host' } );
    }
    
  	# get results
  	$result = eval { $self->_get_livestatus( $query ) };
  	
  }else{
  	croak ("Unsupported provider: $self->{'provider'}!");
  }
  
  # change hash into array of hashes for JS template processing
  my $tmp;
  foreach my $key (sort keys %{ $result }){
  	
  	$result->{ $key }{ 'state' } = "../share/images/icons/arrow-" . $result->{ $key }{ 'state' } . ".png";
  	push @{ $tmp }, $result->{ $key };
  	
  }
  
  # produce json output
  my $json = JSON::PP->new->pretty;
  # if host/service is not found $tmp is a simple scalar
  if (ref $tmp eq "ARRAY"){
    $json = $json->encode( $tmp );
  }
  
  return $json;
  
}


#----------------------------------------------------------------

=head1 METHODS	

=head2 get_details

 get_details ( 'host' => $host, service => $service )

Connects to backend and queries details of given host and service.
Returns JSON data.

  my $json = $details->get_details ( 'host' => $host, service => $service );
  
=cut

sub get_details {
	
  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
  
  my $result = undef;
  # fetch data from Icinga/Nagios
  if ($self->{'provider'} eq "ido"){
  	
  	# construct SQL query
  	my $sql = $self->_query_ido( $self->{ 'host' }, $self->{ 'service' } );
  	# get results
  	$result = eval { $self->_get_ido( $sql ) };
  	
  }elsif ($self->{'provider'} eq "mk-livestatus"){
  	
  	# construct query
  	my $query = $self->_query_livestatus( $self->{ 'host' }, $self->{ 'service' } );
  	# get results
  	$result = eval { $self->_get_livestatus( $query ) };
  	
  }else{
  	croak ("Unsupported provider: $self->{'provider'}!");
  }
  
  # change hash into array of hashes for JS template processing
  # bring in format:
  # [
  #    { name: key,
  #      value: key
  #    },
  #    { ... }
  # ]
  my $tmp;
  foreach my $key (sort keys %{ $result->{ $self->{ 'service' } } }){
  	
  	my $x;
  	$x->{ 'name' } = $key;
  	$x->{ 'value' } = $result->{ $self->{ 'service' } }{ $key };
  	
  	# bring values into more understandable format
  	if ($key eq "state"){
  		
  	  $x->{ 'name' } = "State";
  		
  	  # display states
  	  if ($result->{ $self->{ 'service' } }{ $key } == 0){
  	  	$x->{ 'value' } = "OK";
  	  }elsif ($result->{ $self->{ 'service' } }{ $key } == 1){
  	  	$x->{ 'value' } = "WARNING";
  	  }elsif ($result->{ $self->{ 'service' } }{ $key } == 2){
  	  	$x->{ 'value' } = "CRITICAL";
  	  }else{
  	  	$x->{ 'value' } = "UNKNOWN";
  	  }
  		
  	}else{
  		
  	  if (defined $result->{ $self->{ 'service' } }{ $key } && $result->{ $self->{ 'service' } }{ $key } eq "0"){
  	    $x->{ 'value' } = "no";
   	  }elsif (defined $result->{ $self->{ 'service' } }{ $key } && $result->{ $self->{ 'service' } }{ $key } eq "1"){
  	    $x->{ 'value' } = "yes";
  	  }
  	 
  	 # rename colums
  	 $x->{ 'name' } = ucfirst( $x->{ 'name' } );
  	 $x->{ 'name' } =~  s/_/ /g;
  	 $x->{ 'name' } = "Service name" if $x->{ 'name' } eq "Display name" || $x->{ 'name' } eq "Service";
  	 $x->{ 'name' } = "Performance data" if $x->{'name' } eq "Perf data";
  	  
  	}
  	
  	push @{ $tmp }, $x;
  	
  }
  
  # produce json output
  my $json = JSON::PP->new->pretty;
  # if host/service is not found $tmp is a simple scalar
  if (ref $tmp eq "ARRAY"){
    $json = $json->encode( $tmp );
  }
  
  return $json;
  
}


#----------------------------------------------------------------

=head1 METHODS	

=head2 get_graphs

 get_graphs ( 'host' => $host, service => $service )

Connects to backend and prepares pnp4nagios graph urls.
Returns JSON data.

  my $json = $graphs->get_graphs ( 'host' => $host, service => $service );
  
=cut

sub get_graphs {
	
  my $self		= shift;
  my %options 	= @_;
  
  for my $key (keys %options){
  	if (exists $self->{ $key }){
  	  $self->{ $key } = $options{ $key };
  	}else{
  	  croak "Unknown option: $key";
  	}
  }
  
  my $result = undef;
  # PNP4Nagios graphs
  if ($self->{'provider'} eq "pnp"){
  	
  	$result->{ '4hours' }	= $self->{ 'provdata' }{ 'url' } . "/image?host=" . $self->{ 'host' } ."&srv=" . $self->{ 'service' } . "&view=0";
    $result->{ '25hours' }	= $self->{ 'provdata' }{ 'url' } . "/image?host=" . $self->{ 'host' } ."&srv=" . $self->{ 'service' } . "&view=1";
    $result->{ '1week' }	= $self->{ 'provdata' }{ 'url' } . "/image?host=" . $self->{ 'host' } ."&srv=" . $self->{ 'service' } . "&view=2";
    $result->{ '1month' }	= $self->{ 'provdata' }{ 'url' } . "/image?host=" . $self->{ 'host' } ."&srv=" . $self->{ 'service' } . "&view=3";
    $result->{ '1year' }	= $self->{ 'provdata' }{ 'url' } . "/image?host=" . $self->{ 'host' } ."&srv=" . $self->{ 'service' } . "&view=4";
    
  }else{
  	croak ("Unsupported provider: $self->{'provider'}!");
  }
  
  # change hash into array of hashes for JS template processing
  my $tmp;
  push @{ $tmp }, $result;
  
  # produce json output
  my $json = JSON::PP->new->pretty;
  $json = $json->encode( $tmp );
  
  return $json;
  
}


#----------------------------------------------------------------

# internal methods
##################

# construct SQL query for IDOutils
sub _query_ido {
	
  my $self		= shift;
  my $hostname	= shift or croak ("Missing hostname!");
  my $service	= shift;
  
  chomp $hostname;
  my $sql = undef;
  
  # if service is given get service details otherwise get services
  if ($service){
  	
  	if (ref $service eq "ARRAY"){
  		
  	  # get service status for given host and services
  	  # construct SQL query
      $sql  = "SELECT name2 AS service, current_state AS state, output, problem_has_been_acknowledged AS acknowledged, notifications_enabled, is_flapping FROM " . $self->{'provdata'}{'prefix'} . "objects, " . $self->{'provdata'}{'prefix'} . "servicestatus ";
      $sql .= "WHERE object_id = service_object_id AND is_active = 1 AND name1 = '$hostname' AND name2 IN (";
  
      # go through service array
  	  for (my $i=0;$i< scalar @{ $service };$i++){
  	  	$sql .= "'" . $service->[$i] . "', ";
  	  }
  	  
  	  # remove trailing ', '
      chop $sql;
      chop $sql; 
      $sql .= ")";
  
  	}else{
  	
  	  # get service details	
  	  # construct SQL query and name colums same as for mk-livestatus
  	  # this is required for easier renaming
  	  $sql  = "SELECT name2 AS service, current_state AS state, last_check, last_state_change, output AS plugin_output, long_output AS long_plugin_output, perfdata AS perf_data, last_notification, last_state_change, ";
  	  $sql .= "latency, next_check, notifications_enabled, problem_has_been_acknowledged AS acknowledged, comment_data AS comments, is_flapping ";
  	  $sql .= "FROM " . $self->{'provdata'}{'prefix'} . "objects INNER JOIN " . $self->{'provdata'}{'prefix'} . "servicestatus ";
  	  $sql .= "ON " . $self->{'provdata'}{'prefix'} . "objects.object_id = service_object_id LEFT OUTER JOIN " . $self->{'provdata'}{'prefix'} . "comments ";
  	  $sql .= "ON " . $self->{'provdata'}{'prefix'} . "objects.object_id = " . $self->{'provdata'}{'prefix'} . "comments.object_id ";
  	  $sql .= "WHERE is_active = 1 AND name1 = '$hostname' AND name2 = '$service'";
  	  
  	}
  	
  }else{
  
    # construct SQL query
    $sql  = "SELECT name2 AS service, current_state AS state, output, problem_has_been_acknowledged AS acknowledged, notifications_enabled, is_flapping FROM " . $self->{'provdata'}{'prefix'} . "objects, " . $self->{'provdata'}{'prefix'} . "servicestatus ";
    $sql .= "WHERE object_id = service_object_id AND is_active = 1 AND name1 = '$hostname';";
    
  }
  
  return $sql;
  
}


#----------------------------------------------------------------

# construct livetstatus query
sub _query_livestatus {
	
  my $self		= shift;
  my $hostname	= shift or croak ("Missing hostname!");
  my $service   = shift;
  
  chomp $hostname;
  my $query = undef;
  
  # if service is given get service details otherwise get services
  if ($service){
  	
  	if (ref $service eq "ARRAY"){
  		
  	  # get service status for given host and services
  	  # construct livestatus query
  	  $query = "GET services\n
Columns: display_name state plugin_output acknowledged notifications_enabled is_flapping\n";
  
      # go through service array
  	  for (my $i=0;$i< scalar @{ $service };$i++){
  	  	$query .= "Filter: display_name = " . $service->[$i] . "\n";
  	  }
  	  
      $query .= "Or: " . scalar @{ $service } . "\n" if scalar @{ $service } > 1;
      $query .= "Filter: host_name =~ $hostname\n
And: 2";
  
  	}else{
  	
  	  # get service details
  	  # construct livestatus query
  	  $query = "GET services\n
Columns: display_name state last_check last_state_change plugin_output long_plugin_output perf_data last_notification last_state_change latency next_check notifications_enabled acknowledged comments is_flapping\n
Filter: host_name =~ $hostname\n
Filter: display_name =~ $service\n";

  	}
  	
  }else{
  
    # construct livestatus query
    $query = "GET services\n
Columns: display_name state plugin_output acknowledged notifications_enabled is_flapping\n
Filter: host_name =~ $hostname";

  }
  
  return $query;
  
}


#----------------------------------------------------------------

# get service status from IDOutils
sub _get_ido {
	
  my $self	= shift;
  my $sql	= shift or croak ("Missing SQL query!");
  
  my $result;
  
  my $dsn = undef;
  # database driver
  if ($self->{'provdata'}{'type'} eq "mysql"){
    use DBI;	  # MySQL
  	$dsn = "DBI:mysql:database=$self->{'provdata'}{'database'};host=$self->{'provdata'}{'host'};port=$self->{'provdata'}{'port'}";
  }elsif ($self->{'provdata'}{'type'} eq "pgsql"){
	use DBD::Pg;  # PostgreSQL
  	$dsn = "DBI:Pg:dbname=$self->{'provdata'}{'database'};host=$self->{'provdata'}{'host'};port=$self->{'provdata'}{'port'}";
  }else{
  	croak "Unsupported database type: $self->{'provdata'}{'type'}";
  }
  
  # connect to database
  my $dbh   = eval { DBI->connect_cached($dsn, $self->{'provdata'}{'username'}, $self->{'provdata'}{'password'}) };
  if ($DBI::errstr){
  	croak "Can't connect to database: $DBI::errstr: $@";
  }
  my $query = $dbh->prepare( $sql );
  eval { $query->execute };
  if ($DBI::errstr){
  	croak "Can't execute query: $DBI::errstr: $@";
    #$dbh->disconnect;
  }
  
  # prepare return
  $result = $query->fetchall_hashref('service');
  
  # disconnect from database
  #$dbh->disconnect;
  
  return $result;
  
}


#----------------------------------------------------------------

# get service status from mk-livestatus
sub _get_livestatus {
	
  my $self	= shift;
  my $query	= shift or croak ("Missing livestatus query!");
  
  my $result;
  my $ml;
  
  use Monitoring::Livestatus;
  
  # use socket or hostname:port?
  if ($self->{'provdata'}{'socket'}){
    $ml = Monitoring::Livestatus->new( 	'socket' 	=> $self->{'provdata'}{'socket'},
    									'keepalive' => 1 );
  }else{
    $ml = Monitoring::Livestatus->new( 	'server' 	=> $self->{'provdata'}{'server'} . ':' . $self->{'provdata'}{'port'},
    									'keepalive'	=> 1 );
  }
  
  $ml->errors_are_fatal(0);
  $result = $ml->selectall_hashref($query, "display_name");
  
  if($Monitoring::Livestatus::ErrorCode) {
    croak "Getting Monitoring checkresults failed: $Monitoring::Livestatus::ErrorMessage";
  }
  
  foreach my $key (keys %{ $result }){
  	
    # rename columns
    $result->{ $key }{ 'service' } = delete $result->{ $key }{ 'display_name' };
    $result->{ $key }{ 'output' } = delete $result->{ $key }{ 'plugin_output' };
    
  }
  
  return $result;
  
}


1;


=head1 EXAMPLES

Get service details from IDOutils for host named 'localhost'

  use oVirtUI::Data;
  my $details = oVirtUI::Data->new(
  	provider	=> 'ido',
  	provdata	=> $provdata,
  	host		=> "localhost",
  );
  $json = $details->get_services();


=head1 SEE ALSO

See oVirtUI::Config for reading and parsing config files.

=head1 AUTHOR

Rene Koch, E<lt>r.koch@ovido.atE<gt>

=head1 VERSION

Version 0.330  (Dec 11 2013))

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Rene Koch <r.koch@ovido.at>

This library is free software; you can redistribute it and/or modify
it under the same terms as oVirtUI itself.

=cut


