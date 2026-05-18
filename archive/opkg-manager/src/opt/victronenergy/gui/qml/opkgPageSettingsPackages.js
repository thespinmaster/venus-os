
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

function getDescription(model, showCompact, longDesc) {
  if (!model || showCompact )
    return ""
  
  //console.log("getDescription:" + model + "," + model.description_short + "," + model.description_long)

  var desc = ((longDesc && model.description_long?.length > 0)) 
                ? model.description_long 
                : model.description_short || ""

  //console.log("get desc:" + desc.trim())
  var installed = model.installedVersion?.length > 0
  var available = true
  if (installed)
    available = versionGreaterThan(model.version, model.installedVersion)
  return desc.trim() + "\n" +
      (installed ? "Installed: " + model.installedVersion + "  ": "")  + 
      (available ? "Available: " + model.version + "  ": "")  + 
      "  Feed: " + model.feed
}
 
function doInstllerAction(packageRunner, action, packageName, noAction) {
  var args = ["package", action, packageName]
  if (noAction)
    args.push("--noaction")
  
  console.log("doInstllerAction:" + args)

  packageRunner.logCallback("--- Starting " + action + " for: " + packageName + " ---")
 
  packageRunner.operationName = "package " + action;
  packageRunner.start(args);
}
 
function loadPackages(packageRunner, packageModel, operationName, args) {
  if (packageRunner.running) {
    return
  }
  packageModel.clear()
  packageRunner.operationName = operationName
  var commandArgs = ["package", "list"]
  if (args) {
    commandArgs.push(args)
  }
  packageRunner.start(commandArgs)
}
 
function loadPackagesFromJson(jsonText, packageModel) {
  if (!jsonText || jsonText.length === 0) {
    throw new Error("No package JSON returned");
  }

  var packages = JSON.parse(jsonText)
  for (var i = 0; i < packages.length; i++) {
    var pkg = packages[i]
    packageModel.append({
      name: pkg.name || pkg.package || "",
      description_short: pkg.description_short || "",
      description_long: pkg.description_long || "",
      version: pkg.version || "",
      feed: pkg.feed || "",
      installedVersion: pkg.installedVersion || pkg.installed_version || ""
    })
  }
 
}
