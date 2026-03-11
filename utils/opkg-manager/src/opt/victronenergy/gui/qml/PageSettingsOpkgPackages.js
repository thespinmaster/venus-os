
// Version comparison helper
function versionGreaterThan(v1, v2) {
  if (!v2 && v1) return true;
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

  if (model.subpage)
    return model.description_short || "" // for options
 
  var desc = ((longDesc && model.description_long?.length > 0)) 
                ? model.description_long 
                : model.description_short || ""

  console.log("get desc:" + desc.trim())
  var installed = model.installedVersion?.length > 0
  var available = versionGreaterThan(model.version, model.installedVersion)
  return desc.trim() + "\n" +
      (installed ? "Installed: " + model.installedVersion + "  ": "")  + 
      (available ? "Available: " + model.version + "  ": "")  + 
      "  Feed: " + model.feed
}
 
function doInstllerAction(packageRunner, action, packageName, noAction) {
  var args = [action + "-package", packageName]
  if (noAction)
    args.push("--noaction")
  
  console.log("doInstllerAction:" + args)

  packageRunner.logCallback("--- Starting " + action + " for: " + packageName + " ---")
 
  packageRunner.operationName = action;
  packageRunner.start(args);
}
 
function loadPackages(packageRunner, packageModel, operationName, args) {
  if (packageRunner.running) {
    return
  }
  packageModel.clear()
  packageRunner.operationName = operationName
  packageRunner.start(["list-packages", args])
}
 
function loadPackagesFromFile(file, fileHelper, packageModel) {
 
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
      name: pkg.name || "",
      description_short: pkg.description_short || "",
      description_long: pkg.description_long || "",
      version: pkg.version || "",
      feed: pkg.feed || "",
      installedVersion: pkg.installedVersion || ""
    })
  }
 
}
