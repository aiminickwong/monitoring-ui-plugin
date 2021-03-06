/*
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
*/


// clickable table rows in monitoring results
$(document).ready(function() {

  // get JSON data
  getResults();
  setInterval("getResults()", refreshInterval);
  
  
  // show tabs
  $(function() {
	$( "#tabs" ).tabs({
	  beforeLoad: function( event, ui ) {
		ui.jqXHR.error(function() {
		  ui.panel.html(
		    "Couldn't load tabs. " );
		});
	  }
	});
  });
  
  // refresh page
  $("#refreshButton").click(function(){
	getResults();
  });
  
  // resizable divs
  $("#left").resizable({ handles: 'e' });
  $("#left").bind("resize", function (event, ui) {
    $('#right').width($(document).width() - ui.size.width - 8);
    // don't allow to resize this div over the details div
    // TODO: fix this to a better solution!
    if ( ($(document).width() - $('#left').width() - 8) < 300){
      $('#left').width($(document).width() - $('#right').width() - 8);
    }
    $('#service-details').width($('#left').width());
    $('.td-mon-res-subdetails-scroll').width($('#right').width());
  });
  
  // resizeable service status
  $('#mon-res-service').resizable({ handles: 'e' });
  $('#mon-res-service').bind("resize", function (event, ui) {
	$('#mon-res-tbody-service').width($('#mon-res-service').width());
	$('#mon-res-service-th').width($('#mon-res-service').width());
	$('#mon-res-output').css("margin-left", "5px");
  });
  
  // resizeable service details
  $('#mon-res-name').resizable({ handles: 'e' });
  $('#mon-res-name').bind("resize", function (event, ui) {
	$('#mon-res-tbody-name').width($('#mon-res-name').width());
	$('#mon-res-name-th').width($('#mon-res-name').width());
	$('#mon-res-value').css("margin-left", "5px");
  });
 
  // fix size when browser resizes
  $(window).resize(function() {
	// don't allow to resize this div over the details div
	// TODO: fix this to a better solution!
	// This is still a bit buggy!
	if ( ($(document).width() - $('#left').width() - 8) < 300){
	  $('#left').width($(document).width() - 308);
	}
    $('#service-details').width($('#left').width());
	$('#right').width($(document).width() - $('#left').width() - 8);
    $('.td-mon-res-subdetails-scroll').width($('#right').width());
  });

});



// clickable rows
$(document).on('click', 'tr#mon-res-body-tr', function(){

  var serviceName = $(this).find('#mon-res-body-service').text();
  var hostName = $("div[id='service-details']").attr("host");
  var compName = $("div[id='service-details']").attr("component");
  
  // TODO: make this reload safe!
  $('td').removeClass('mon-res-body-tr-selected');
  $('td', this).toggleClass('mon-res-body-tr-selected');
  
  // get details for selected service and update details-div
  getDetails(hostName, serviceName, compName);
  
  // get pnp images and update pnp-div
  getPnp(hostName, serviceName, compName);
  
});



// get service stati for selected host/vm
function getResults(){
	
  // get hostname
  var hostName = $("div[id='service-details']").attr("host");
  var compName = $("div[id='service-details']").attr("component");
  $.getJSON( "?host=" + hostName + "&comp=" + compName, function(data){
	  
    jsonData = data;
	$('#mon-res-tbl-services tbody').loadTemplate("../share/js-templates/service_status.html", jsonData, overwriteCache=templateCache);
	// change size of td's to previous value as JS template overwrites it
    $('#mon-res-tbody-service').width($('#mon-res-service').width());
    
    if ($('#mon-res-tbl-details tbody').attr('service')){
      // why is this not working?
      $(this).find('#mon-res-body-td').text( $('#mon-res-tbl-details tbody').attr('service') ).toggleClass('mon-res-body-tr-selected');
    }
	  
  })
  .fail(function() { 
    
	// did not receive (correct) data from backend
	$('#mon-res-tbl-services tbody').loadTemplate("../share/js-templates/service_error.html", overwriteCache=templateCache);  
	
  })
  
}



// get detailed information for service check
function getDetails(hostName, serviceName, compName){
	
  // save service name in case service status page gets reloaded
  $('#mon-res-tbl-details tbody').attr("service", serviceName);

  // get hostname
  $.getJSON( "?host=" + hostName + "&service=" + serviceName + "&comp=" + compName, function(data){
		  
    jsonData = data;
	$('#mon-res-tbl-details tbody').loadTemplate("../share/js-templates/service_details.html", jsonData, overwriteCache=templateCache);
	// size of details tabs
	$('#mon-res-tbody-name').width($('#mon-res-name').width());
	  
  })
	  
}


// get pnp images for service check
function getPnp(hostName, serviceName, compName){
	
  $.getJSON( "?graph=" + hostName + "&service=" + serviceName + "&comp=" + compName, function(data){
		
    jsonData = data;
    $('#mon-res-tbl-graph tbody').loadTemplate("../share/js-templates/service_graphs.html", jsonData, overwriteCache=templateCache);

  })
    
}


