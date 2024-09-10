#!/bin/bash
cd "$(dirname "$0")"

echo deleting old zip
rm Vizbee-Roku-Demo-SceneGraph-App

echo packing sources
zip -r Vizbee-Roku-Demo-SceneGraph-App "images"
zip -r Vizbee-Roku-Demo-SceneGraph-App "manifest"
zip -r Vizbee-Roku-Demo-SceneGraph-App "source"
zip -r Vizbee-Roku-Demo-SceneGraph-App "components"

echo sending to Roku
curl -v --anyauth -u "rokudev:1234" -sSF  "archive=@Vizbee-Roku-Demo-SceneGraph-App.zip" -F "mysubmit=Replace" http://$1/plugin_install