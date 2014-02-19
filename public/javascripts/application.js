function add_tours_to_available_tours(tours) {
  var insert_html = '';
  jQuery('.published_tours').html(insert_html);

  for(var i = 0; i < tours.length; i++) {
    if(jQuery('#tour_id_'+tours[i]['id']).length == 0) {
      insert_html += '<li class="ui-state-default" id="tour_id_' + tours[i]['id'] + '" tour_info="tour_' + tours[i]['id'] + '"><div class="loi_details"><span style="width:210px">' + tours[i]['name'] + '</span><span class="delete_tour"></span></div></li>';
    }
  }
  jQuery('.published_tours').html(insert_html);
}

function check_city_bbox(tour_or_location) {
  var is_ubertour = false;
  if(tour_or_location == 'ubertour'){ 
    is_ubertour = true;
    tour_or_location = 'tour';
  }

  jQuery('#' + tour_or_location + '_city_message').hide();
  var country = jQuery('#'+tour_or_location+'_country').val();
  var city    = jQuery('#'+tour_or_location+'_city').val();
  
  if (country == '' || city == '') {
    return;
  }
  jQuery.getJSON('/tours/check_city_bbox', {country: country, city: city, is_ubertour: is_ubertour}, function(response) {
    if(typeof(map) != 'undefined' ) { 
      var bounds_points_array = []
      bounds_points_array.push(new L.LatLng(response['bbox'][0][0], response['bbox'][0][1]));
      bounds_points_array.push(new L.LatLng(response['bbox'][1][0], response['bbox'][1][1]));
      var cm_latlng_bounds = new L.LatLngBounds(bounds_points_array);

      var min_zoom_level_for_bounds = map.getBoundsZoom(cm_latlng_bounds);

      if(city != '') {
        map.setView(cm_latlng_bounds.getCenter(), 15);
      } else {
        map.setView(cm_latlng_bounds.getCenter(), min_zoom_level_for_bounds);
      }
    }

    if(is_ubertour && response['tours']) {
      add_tours_to_available_tours(response['tours']);
      var published_tours_height = jQuery('.published_tours').height();
      if(jQuery('.selected_tours').height() < published_tours_height) {
        jQuery('.selected_tours').height(published_tours_height + 'px');
      }
    }

    if(response['result'] === false) {
      jQuery('#'+tour_or_location+'_city_message').html(response['error_message']).show();
    }
  });
}

function add_marker_to_map(latlng) {
    var MyIcon = L.Icon.extend({
      iconUrl: "/javascripts/leaflet/images/marker.png",
      shadowUrl: '/javascripts/leaflet/images/marker-shadow.png',
      iconSize: new L.Point(24, 40),
      iconAnchor: new L.Point(12, 40)
    });
    var icon = new MyIcon();
    marker = new L.Marker(latlng, {icon: icon});
    map.addLayer(marker);
}

function set_autocomplete_on_tags_input() {
  // jQuery UI Autocompleter
  jQuery( "#media_keywords" )
    // don't navigate away from the field on tab when selecting an item
    .bind( "keydown", function( event ) {
      if ( event.keyCode === jQuery.ui.keyCode.TAB &&
        jQuery( this ).data( "autocomplete" ).menu.active ) {
        event.preventDefault();
      }
    })
    .autocomplete({
      html: true,
      source: function( request, response ) {
        jQuery.getJSON( "/media/tagged_with", {
          term: extractLast( request.term )
        }, response );
      },
      search: function() {
        // custom minLength
        var term = extractLast( this.value );
        if ( term.length < 2 ) {
          return false;
        }
      },
      open: function() {
        jQuery('.ui-autocomplete').css({zIndex: 10000}); // 10000 because add_meta_info_to_media extjs window's zindex is 9013
      },
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      select: function( event, ui ) {
        var terms = split( this.value );
        // remove the current input
        terms.pop();
        // add the selected item
        terms.push( ui.item.value );
        // add placeholder to get the comma-and-space at the end
        terms.push( "" );
        this.value = terms.join( ", " );
        return false;
      }
  });
}

function toggle_subcategories(top_category_id) {
  // uncheck all subcats if top category was unchecked
  var top_category = $("#pob_category_" + top_category_id);
  jQuery('.' + top_category_id + '_subcategories').map(function() {
    var checkbox = jQuery(this);
    if (top_category.attr("checked")) {
      checkbox.attr("checked", "checked");
    } else {
      checkbox.removeAttr("checked");
    }
  });
}

function disable_top_category_if_subcats_unchecked(top_category_id) {
  // if all subcats are disabled then disable top_category
  var all_subcats_disabled = true;
  jQuery('.' + top_category_id + '_subcategories').map(function() {
    var checkBox = jQuery(this);
    if(checkBox.attr("checked")) {
      all_subcats_disabled = false;
    }
  });
  if(all_subcats_disabled) {
    jQuery('#pob_category_'+top_category_id).attr("checked", false);
  } else {
    jQuery('#pob_category_'+top_category_id).attr("checked", true);
  }
}

// loi autosave
$(document).ready(function(e){
  $(window).bind(
    "beforeunload", 
    function() { 
      $("iframe").remove();
      if (window.formSubmit != true) {
        var options = {
          async: false, 
          success: function(response) {}
        }
        $("#location_is_draft").val(1);
        $("form.new_location").ajaxSubmit(options);
        $("form.edit_location").ajaxSubmit(options);
      };
    }
  );
});
