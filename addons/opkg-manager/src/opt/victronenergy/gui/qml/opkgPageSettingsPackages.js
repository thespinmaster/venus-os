
.pragma library

function parseVersionParts(version) {
  var normalized = (version || "").trim();
  var match = normalized.match(/^(\d+(?:\.\d+)*)/);
  var baseVersion = match ? match[1] : "";
  var suffixVersion = normalized.slice(baseVersion.length);
  var suffixNumbers = suffixVersion.match(/\d+/g) || [];

  return {
    base: baseVersion ? baseVersion.split('.').map(Number) : [],
    suffix: suffixNumbers.map(Number)
  };
}

// Version comparison helper
function versionGreaterThan(v1, v2) {
  if (!v2 && v1) return false;
  if (!v1 || !v2) return false;
  var parsedV1 = parseVersionParts(v1);
  var parsedV2 = parseVersionParts(v2);
  var a = parsedV1.base;
  var b = parsedV2.base;
  for (var i = 0; i < Math.max(a.length, b.length); i++) {
    var n1 = a[i] || 0;
    var n2 = b[i] || 0;
    if (n1 > n2) return true;
    if (n1 < n2) return false;
  }

  var suffixA = parsedV1.suffix;
  var suffixB = parsedV2.suffix;
  for (var j = 0; j < Math.max(suffixA.length, suffixB.length); j++) {
    var s1 = suffixA[j] || 0;
    var s2 = suffixB[j] || 0;
    if (s1 > s2) return true;
    if (s1 < s2) return false;
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
