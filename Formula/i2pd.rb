class I2pd < Formula
  desc "Full-featured C++ implementation of I2P client"
  homepage "https://i2pd.website/"
  url "https://github.com/PurpleI2P/i2pd/archive/2.33.0.tar.gz"
  sha256 "6a30eb410263d2da23d238758ad156e36983bff1ed347fe57789763ae986d0f4"
  license "BSD-3-Clause"
  revision 1

  bottle do
    cellar :any
    sha256 "2211cb8d625965e36d350825432df84794ef35fedaaea06823a58d55ab18315d" => :catalina
    sha256 "2feb17a2f91d30d9b5805abf1d4233920fc1e850adf09e78ca512f0a77982e33" => :mojave
    sha256 "dc420798089587474284054d4113868a7ee87e20d41660643e8fd1af24e4db80" => :high_sierra
  end

  depends_on "boost"
  depends_on "miniupnpc"
  depends_on "openssl@1.1"

  def install
    system "make", "install", "DEBUG=no", "HOMEBREW=1", "USE_UPNP=yes",
                              "USE_AENSI=no", "USE_AVX=no", "PREFIX=#{prefix}"

    # preinstall to prevent overwriting changed by user configs
    confdir = etc/"i2pd"
    rm_rf prefix/"etc"
    confdir.install doc/"i2pd.conf", doc/"subscriptions.txt", doc/"tunnels.conf"
  end

  def post_install
    # i2pd uses datadir from variable below. If that path doesn't exist,
    # create the directory and create symlinks to certificates and configs.
    # Certificates can be updated between releases, so we must recreate symlinks
    # to the latest version on upgrade.
    datadir = var/"lib/i2pd"
    if datadir.exist?
      rm datadir/"certificates"
      datadir.install_symlink pkgshare/"certificates"
    else
      datadir.dirname.mkpath
      datadir.install_symlink pkgshare/"certificates", etc/"i2pd/i2pd.conf",
                              etc/"i2pd/subscriptions.txt", etc/"i2pd/tunnels.conf"
    end

    (var/"log/i2pd").mkpath
  end

  plist_options manual: "i2pd"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/i2pd</string>
          <string>--datadir=#{var}/lib/i2pd</string>
          <string>--conf=#{etc}/i2pd/i2pd.conf</string>
          <string>--tunconf=#{etc}/i2pd/tunnels.conf</string>
          <string>--log=file</string>
          <string>--logfile=#{var}/log/i2pd/i2pd.log</string>
          <string>--pidfile=#{var}/run/i2pd.pid</string>
        </array>
      </dict>
      </plist>
    EOS
  end

  test do
    pid = fork do
      exec "#{bin}/i2pd", "--datadir=#{testpath}", "--daemon"
    end
    sleep 5
    Process.kill "TERM", pid
    assert_predicate testpath/"router.keys", :exist?, "Failed to start i2pd"
  end
end
