exports = this
current = {}
$ ->
  if $('#bus_stop_list_map').is(':visible')
    $form = $('#bus_stop_list_form')

    map = create_leaflet_map 'bus_stop_list_map'
    current.drawLayer = L.layerGroup().addTo(map)
    current.map = map
    latitude = $('#latitude').val()
    longitude = $('#longitude').val()
    if exports.isBlank(latitude) || exports.isBlank(longitude)
      exports.initMap map
      $form.trigger 'submit'
      if navigator.geolocation
        navigator.geolocation.getCurrentPosition setCurrentPosition, exports.cantGetPosition
    else
      exports.initMap map, latitude, longitude, $('#zoom').val()
      $form.trigger 'submit'

    $form.on 'ajax:success', (e, result, status, xhr) ->
      setResult(result)
      return
    $form.on 'ajax:error', () ->
      clearData()
      $('#stop_list').append noResultTableLine()
      return
    $form.one 'ajax:complete', () ->
      id = $('#selected_id').val()
      $('#selected_id').val("")
      if id
        selected = $('#' + id)
        selected.trigger 'click'
        exports.scrollToDom selected, 'bus_stop_list_list'
      return
    map.on 'moveend', () ->
      setLatLng()
      if current.doSearch
        $form.submit()
      current.doSearch = true
      return
    current.doSearch = true

  if $('#bus_stop_show_map').is(':visible')
    map = create_leaflet_map 'bus_stop_show_map'
    latitude = $('#bus_stop_latitude').data('location')
    longitude = $('#bus_stop_longitude').data('location')
    marker = L.marker([latitude, longitude]).addTo(map)
    map.setView marker.getLatLng(), map.getMaxZoom()

  $('#pager').on 'ajax:success', (e, result, status, xhr)->
    $('#pager').html result.paginator
    $('#pager').find('a').each (index, dom)->
      href = dom.href
      if exports.isBlank(href) and href.indexOf("page=") is -1
        if href.indexOf("?") is -1
          dom.href = href + "?page=1"
        else
          dom.href = href + "&page=1"
      return
    $('#list').html result.list
    $page = $('#page')
    if $page
      $page.val result.page
    return
  return
##
# Global functions
##
exports.create_leaflet_map = (map_id) ->
  map = L.map map_id
  L.tileLayer('https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png', {
    attribution: "<a href='http://www.gsi.go.jp/kikakuchousei/kikakuchousei40182.html' target='_blank'>国土地理院</a>"
  }).addTo(map);
  L.control.scale({imperial: false}).addTo(map);
  return map

exports.initMap = (map, lat, lng, zoom) ->
  if exports.isBlank(lat) || exports.isBlank(lng)
    lat = 35.681109
    lng = 139.766865
  zoom = if exports.isBlank zoom then 13 else zoom
  map.setView [lat, lng], zoom
  return

exports.isBlank = (val)->
  if typeof val is 'undefined' || val is null
    return true
  if val.length is 0
    return true
  if typeof  val is 'object' && val is {}
    return true
  return false

exports.cantGetPosition = () ->
  alert("現在地を取得できませんでした")

exports.highlightTableLine = ($dom, $predom) ->
  if $predom
    $predom.removeClass("success")
  if $dom
    $dom.addClass("success")

exports.scrollToDom = ($dom, scroll_area_id) ->
  list = document.getElementById(scroll_area_id)
  offset = $dom.offset()
  list.scrollTop = offset.top - list.offsetTop + list.scrollTop - (list.clientHeight / 2 - 50)
  return
##
# Local functions
##

# bus_stop#index
setCurrentPosition = (pos) ->
  if pos.coords
    crd = pos.coords
    longitude = crd.longitude
    latitude = crd.latitude
    current.map.setView [latitude, longitude], current.map.getZoom()
  else
    exports.cantGetPosition
  return

setLatLng = () ->
  center = current.map.getCenter()
  $('#latitude').val(center.lat)
  $('#longitude').val(center.lng)
  $('#zoom').val(current.map.getZoom())
  return

searchBusStops = () ->
  center = current.map.getCenter()
  data = {latitude: center.lat, longitude: center.lng}
  $.ajax({
    url: "/api/bus_stops/list",
    data: data,
    dataType: 'json',
    method: 'get'
  }).done(setResult).fail(clearData)

clearData = () ->
  current.drawLayer.clearLayers()
  $('#stop_list').empty()
  return

setResult = (data) ->
  clearData()
  trs = []
  for val in data
    marker = addMarker(val.latitude, val.longitude, val.name)
    trs.push createTableLine(val, marker)
  $('#stop_list').append(trs)
  return

addMarker = (latitude, longitude, name) ->
  return L.marker([latitude, longitude]).bindPopup(name).addTo(current.drawLayer)

createTableLine = (val, marker) ->
  tr = $('<tr>').attr(id: "stop_" + val.id)
  tr.append $('<td>').text(val.name).addClass("stop_name")
  tr.append createActionButtons(val.id).addClass("action")
  tr.on 'click', (e)->
    current.doSearch = false
    current.map.panTo(marker.getLatLng())
    highlightTableLine(tr)
    marker.openPopup()
    return
  marker.on 'click', ()->
    current.doSearch = false
    highlightTableLine(tr)
    exports.scrollToDom(tr, 'bus_stop_list_list')
    current.map.fire 'openpopup'
    return
  return tr

createActionButtons = (id) ->
  path = "bus_stops/"
  if location.pathname.indexOf("bus_stops/") isnt -1
    path = ""
  $show = $('<a>').addClass("btn btn-default").attr("href", path + id).text("詳細")
  return $('<td>').append($show)

noResultTableLine = () ->
  tr = $('<tr>')
  tr.append $('<td>').attr('colspan', 2).text("該当データがありませんでした").css("textAlign", "center")
  return tr

highlightTableLine = ($dom) ->
  exports.highlightTableLine($dom, current.highlightedDom)
  current.highlightedDom = $dom
  $('#selected_id').val($dom.attr('id'))
  return
