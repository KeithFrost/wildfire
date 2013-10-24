package org.wildfire.client

import java.io.File
import java.net.InetAddress

import com.turn.ttorrent.client.{Client, SharedTorrent}

object Main {
  org.apache.log4j.BasicConfigurator.configure()
  def main(args: Array[String]) {
    val client = new Client(
      InetAddress.getLocalHost,
      SharedTorrent.fromFile(new File(args(0)), new File(args(1))))
    client.download()
    println("Download from torrent %s begun to %s".format(args(0), args(1)))
    client.waitForCompletion()
    println("Download Complete!")
    Thread.sleep(10000)
  }
}
