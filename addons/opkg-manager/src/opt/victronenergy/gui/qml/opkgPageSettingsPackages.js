
.pragma library

// Version comparison helper
function versionGreaterThan(v1, v2) {
 
  if (!v2 && v1) return false;
  if (!v1 || !v2) return false;
  var a = v1.split('.').map(Number);
  var b = v2.split('.').map(Number);
  for (var i = 0; i < Math.max(a.length, b.length); i++) {
    var n1 = a[i] || 0;
    var n2 = b[i] || 0;
    if (n1 > n2) return true;
    if (n1 < n2) return false;
  }
  return false;
}
 
function getFooter(model, showCompact) {
  if (!model || showCompact )
    return ""
 
  //console.log("getDescription:" + model + "," + model.description_short + "," + model.description_long)
 
  var installed = model.installedVersion?.length > 0
  var available = true
  if (installed)
    available = versionGreaterThan(model.version, model.installedVersion)
  return (installed ? "Installed: " + model.installedVersion + "  ": "")  + 
      (available ? "Available: " + model.version + "  ": "")  + 
      "  Feed: " + model.feed
}
 

 
function loadPackages(opkgBridge, packageModel, operationName, args) {
  if (opkgBridge.running) {
    return
  }
  packageModel.clear()
  
  var commandArgs = ["package", "list"]
  if (args && args.length > 0)
    commandArgs.push(args)
  console.log("opkgBridge: start: " + operationName)
  opkgBridge.operationName = operationName
  opkgBridge.start(commandArgs)
}
 
function loadPackagesFromFile(file, packageModel, fileHelper) {
 
  var filePath = file.trim();
  if (filePath.length == 0) {
    throw new Error("No package list file path returned");
  }

  var jsonText = fileHelper.readFile(filePath);
  
  if (!jsonText || jsonText.length === 0) {
    throw new Error("Failed to read package file: File is empty: " + filePath);
  }

  var packages = JSON.parse(jsonText)
  for (var i = 0; i < packages.length; i++) {
    var pkg = packages[i]
    packageModel.append({
      name: pkg.package || "",
      description: pkg.description || "",
      //description_long: pkg.description_long || "",
      version: pkg.version || "",
      feed: pkg.feed || "",
      installedVersion: pkg.installed_version || ""
    })
  }
 
}
