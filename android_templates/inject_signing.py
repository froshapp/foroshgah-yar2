from pathlib import Path
import re

for gpath in Path("android/app").glob("build.gradle*"):
    g = gpath.read_text()
    if "signingConfigs" in g and "keystoreProperties" in g:
        print("already signed", gpath)
        continue
    key_loader = (
        "\n"
        "def keystoreProperties = new Properties()\n"
        "def keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
        "}\n"
    )
    if "keystoreProperties" not in g:
        g = g.replace("android {", key_loader + "\nandroid {", 1)
    signing = (
        "\n"
        "    signingConfigs {\n"
        "        release {\n"
        "            if (keystorePropertiesFile.exists()) {\n"
        "                keyAlias keystoreProperties[\"keyAlias\"]\n"
        "                keyPassword keystoreProperties[\"keyPassword\"]\n"
        "                storeFile file(keystoreProperties[\"storeFile\"])\n"
        "                storePassword keystoreProperties[\"storePassword\"]\n"
        "            }\n"
        "        }\n"
        "    }\n"
    )
    if "signingConfigs" not in g:
        g = g.replace("buildTypes {", signing + "\n    buildTypes {", 1)
    if "signingConfig signingConfigs.release" not in g:
        g = re.sub(
            r"(release\s*\{)",
            r"\1\n            signingConfig signingConfigs.release",
            g,
            count=1,
        )
    gpath.write_text(g)
    print("signing injected", gpath)
