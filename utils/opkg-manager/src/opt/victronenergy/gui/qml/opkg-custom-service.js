
function isCustomService_old(service, connectedMatch) {
  return service.type === DBusService.DBUS_SERVICE_TEMPERATURE_SENSOR 
    || service.name.startsWith("com.victronenergy.temperature.cdt_")
}

function isCustomService(service, connectedMatch) {
  return service.name.includes("_cdt_")
}

function sdiRuleIdFromServiceName(service) {
  var parts=service.name.split("_cdt_")
  var sdiRuleId=""
  if (parts.length > 1) {
    parts=parts[1].split("_")
    sdiRuleId=parts[0]
  }
  return sdiRuleId
}

function tryAddSdiRuleId(ary, service) {

  var sdiRuleId = sdiRuleIdFromServiceName(service)
  if (!sdiRuleId)
    return false
    
  for (var j = 0; j < ary.length ; j++)
    if (ary[j] == sdiRuleId)
      return false

  ary.push(sdiRuleId)
  return true
}
 