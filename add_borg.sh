if ! grep -q BorgConfig chipyard/generators/firechip/src/main/scala/TargetConfigs.scala; then
echo "
class BorgConfig extends Config(
  new borg.WithBorg ++
  new FireSimRocket1GiBDRAMConfig)" >> chipyard/generators/firechip/src/main/scala/TargetConfigs.scala
fi

if ! grep -q borg chipyard/build.sbt; then
sed -ie "s/compressacc, saturn, ara)/compressacc, saturn, ara, borg)/" chipyard/build.sbt
echo "
lazy val borg = (project in file(\"generators/borg\"))
  .dependsOn(rocketchip)
  .settings(libraryDependencies ++= rocketLibDeps.value)
  .settings(commonSettings)" >> chipyard/build.sbt
fi

mkdir -p ./chipyard/generators/borg/src/main/scala
cp Borg.scala ./chipyard/generators/borg/src/main/scala/
