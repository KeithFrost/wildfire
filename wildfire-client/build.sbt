import AssemblyKeys._

assemblySettings

name         := "wildfire"

version      := "0.1"

scalaVersion := "2.10.2"

libraryDependencies ++= Seq(
  "org.scala-lang" % "scala-compiler" % "2.10.2")

mergeStrategy in assembly <<= (mergeStrategy in assembly) { 
  (old) => {
    case "rootdoc.txt" => MergeStrategy.concat
    case x => old(x)
  }
}

