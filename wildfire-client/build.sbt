import AssemblyKeys._

assemblySettings

name         := "wildfire"

version      := "0.1"

scalaVersion := "2.10.2"

libraryDependencies ++= Seq(
  "org.scala-lang" % "scala-compiler" % "2.10.2",
  "com.turn" % "ttorrent" % "1.2"
)

resolvers ++= Seq(
  "temp repo" at "http://repository-aidamina.forge.cloudbees.com/snapshot/",
  "JBoss Thirdparty Releases" at "https://repository.jboss.org/nexus/content/repositories/thirdparty-releases")

mergeStrategy in assembly <<= (mergeStrategy in assembly) { 
  (old) => {
    case "rootdoc.txt" => MergeStrategy.concat
    case x => old(x)
  }
}

