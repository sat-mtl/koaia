/**
 * Select a process in score, and paste this in score's console
 * in order to find inlet and outlet names easily.
 *
 * Usage:
 *   1. Open score/app.score in ossia score
 *   2. Select one or more processes
 *   3. Open the console (Help > Show Console or similar)
 *   4. Paste this entire script and press Enter
 *   5. Copy the output into qml/koaia/Models/ProcessObjects.qml
 */

const C_KEYWORDS = new Set([
  'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do',
  'double', 'else', 'enum', 'extern', 'float', 'for', 'goto', 'if',
  'int', 'long', 'register', 'return', 'short', 'signed', 'sizeof', 'static',
  'struct', 'switch', 'typedef', 'union', 'unsigned', 'void', 'volatile', 'while',
  '_Bool', '_Complex', '_Imaginary', 'inline', 'restrict'
]);

/**
 * Converts an arbitrary string into a C compatible identifier.
 *
 * @param {string} str The input string to convert.
 * @param {string} [defaultName='_c_identifier'] The name to return if the input
 * is empty or null.
 * @returns {string} A string that is safe to use as a C identifier.
 */
const stringToCIdentifier = (str, defaultName = '_c_identifier') => {
  // 1. Handle empty, null, or undefined input
  if (!str || typeof str !== 'string' || str.length === 0) {
    return defaultName;
  }

  // 2. Replace all non-alphanumeric (and non-underscore) characters with an underscore
  //    Regex: /[^a-zA-Z0-9_]/g
  //    ^ inside [] means "not"
  //    g means "global" (replace all occurrences)
  let identifier = str.replace(/[^a-zA-Z0-9_]/g, '_');

  // 3. Ensure the first character is not a digit
  //    Regex: /^[0-9]/
  //    ^ outside [] means "starts with"
  if (/^[0-9]/.test(identifier)) {
    identifier = '_' + identifier;
  }

  // 4. Check if the resulting name is a C keyword
  if (C_KEYWORDS.has(identifier)) {
    identifier = '_' + identifier; // Prefix with _ to make it valid
  }

  // 5. Handle case where input was just invalid chars (e.g., "!" -> "_")
  //    or empty ("" -> handled by check 1)
  if (identifier.length === 0) {
     return defaultName;
  }
  return identifier[0].toLowerCase() + identifier.slice(1);
};

function func() {
  let txt = "";
  const objs = Score.selectedObjects();
    for(let obj of  objs) {
        const meta = Score.metadata(obj);
        const inls = Score.inlets(obj);
        const outls = Score.outlets(obj);

        // txt += "   property var " + stringToCIdentifier(meta.name) + ";\n";
        txt += `QtObject { id: ${stringToCIdentifier(meta.name)}\n`;
        txt += `   property var process_object : Score.find("${meta.name}");\n`;
        for(var i = 0; i < inls; i++) {
            let port = Score.inlet(obj, i);
            txt += "   property var " + stringToCIdentifier(port.name) + ` : Score.inlet(process_object, ${i});\n`;
        }
        for(var i = 0; i < outls; i++) {
            let port = Score.outlet(obj, i);
            txt += "   property var " + stringToCIdentifier(port.name) + ` : Score.outlet(process_object, ${i});\n`;
        }
        txt += "}\n";
    }
    console.log(txt)
    return txt;
}
func();