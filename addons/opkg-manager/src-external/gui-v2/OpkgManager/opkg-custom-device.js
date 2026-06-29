
function isCustomService(service, connectedMatch) {
  return service.name.includes("_sid_")
}

function deviceFromServiceName(service) {
  var parts = service.name.split(".")
  for (var j = 0; j < parts.length ; j++) {
    if (parts[j].includes("_sid_"))
      return parts[j]
  }
}

function tryAddCustomDevice(ary, service) {

  var deviceName = deviceFromServiceName(service)

  if (!deviceName)
    return false

  for (var j = 0; j < ary.length ; j++)
    if (ary[j] == deviceName)
      return false

  ary.push(deviceName)
  return true
}
