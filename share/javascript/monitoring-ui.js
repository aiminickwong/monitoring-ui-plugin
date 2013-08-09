// This file is part of ovirt-Monitoring UI-Plugin.
//
// ovirt-Monitoring UI-Plugin is free software: you can redistribute it 
// and/or modify it under the terms of the GNU General Public License 
// as published by the Free Software Foundation, either version 3 of the i
// License, or (at your option) any later version.
//
// ovirt-Monitoring UI-Plugin is distributed in the hope that it will be 
// useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ovirt-Monitoring UI-Plugin.  
// If not, see <http://www.gnu.org/licenses/>.


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
  
});



// clickable rows
$(document).on('click', 'tr#mon-res-body-tr', function(){

  var serviceName = $(this).find('#mon-res-body-service').text();
  var hostName = $("div[id='service-details']").attr("host");
  
  // get details for selected service and update details-div
  getDetails(hostName, serviceName);
  
  // get pnp images and update pnp-div
  getPnp(hostName, serviceName);
  
});



// get service stati for selected host/vm
function getResults(){
	
  // get hostname
  var hostName = $("div[id='service-details']").attr("host");
  var compName = $("div[id='service-details']").attr("component");
  $.getJSON( "?host=" + hostName + "&comp=" + compName, function(data){
	  
    jsonData = data;
	$('#mon-res-tbl-services tbody').loadTemplate("../share/js-templates/service_status.html", jsonData, overwriteCache=templateCache);
	  
  })
  
}



// get detailed information for service check
function getDetails(hostName, serviceName){
	
  // get hostname
  $.getJSON( "?host=" + hostName + "&service=" + serviceName, function(data){
		  
    jsonData = data;
	$('#mon-res-tbl-details tbody').loadTemplate("../share/js-templates/service_details.html", jsonData, overwriteCache=templateCache);
	  
  })
	  
}


// get pnp images for service check
function getPnp(hostName, serviceName){
	
  $.getJSON( "?graph=" + hostName + "&service=" + serviceName, function(data){
		
    jsonData = data;
    $('#mon-res-tbl-graph tbody').loadTemplate("../share/js-templates/service_graphs.html", jsonData, overwriteCache=templateCache);

  })
    
}


