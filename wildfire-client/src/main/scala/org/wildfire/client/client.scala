package org.wildfire.client

import java.io.File
import java.net.InetAddress
import java.util.Properties
import javax.naming.Context
import javax.naming.directory.{DirContext, InitialDirContext}
import javax.naming.NamingException

import com.turn.ttorrent.client.{Client, SharedTorrent}

object Main {
  val master = System.getenv("MASTER")
  val dns = new Dns("dns://" + master)
  val url = dns.getTxtRecord("release.wildfire.net")
  println("release.wildfire.net TXT = " + url)
  org.apache.log4j.BasicConfigurator.configure()
  def main(args: Array[String]) {
    val localHost = InetAddress.getLocalHost
    val client = new Client(
      localHost, SharedTorrent.fromFile(new File(args(0)), new File(args(1))))
    val start = System.currentTimeMillis
    client.download()
    println("Download from torrent %s begun to %s".format(args(0), args(1)))
    client.waitForCompletion()
    val elapsed = System.currentTimeMillis - start
    println("Download Completed after %f seconds".format(elapsed * 0.001))
    while (true) {
      Thread.sleep(1000)
    }
  }
}

//  "dns://10.183.138.92"

class Dns(source: String) {
  val env = new Properties()
  env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.dns.DnsContextFactory")
  env.put(Context.PROVIDER_URL, source)
  val directoryContext = new InitialDirContext(env)

  def getTxtRecord(hostname: String): String = {
    try {
      val attrs = directoryContext.getAttributes(hostname, Array("TXT"))
      val attr = attrs.get("TXT")
      if (attr != null) attr.get.toString else ""
    } catch {
      case ex: NamingException => return ""
    }
  }
}
