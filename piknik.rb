class Piknik < Formula
  desc "Copy/paste anything over the network"
  head "https://github.com/jedisct1/piknik.git"
  homepage "https://github.com/jedisct1/piknik"
  sha256 "4b61e78d7c2f4ddc69cffe9e800a6ca03af8e90540a089469def615388087983"
  url "https://github.com/jedisct1/piknik/archive/0.9.tar.gz"
  version "0.9"

  depends_on "go" => :build
  depends_on "godep" => :build

  def install
    ENV["GOPATH"] = buildpath
    dir = buildpath/"src/github.com/jedisct1/"
    dir.install Dir["*"]
    ln_s buildpath/"src", dir
    cd dir do
      system "godep", "restore"
      system "go", "build", "-o", bin/"piknik", "."
      ln "zsh.aliases", "piknik.sh"
      (prefix/"etc/profile.d").install "piknik.sh"
    end
  end

  def caveats; <<-EOS.undent
    For Bash or Zsh, put something like this in your $HOME/.bashrc or $HOME/.zshrc:
      source $(brew --prefix)/etc/profile.d/piknik.sh
    EOS
  end

  test do
    begin
      conffile = testpath/"testconfig.toml"

      IO.popen([{}, "#{bin}/piknik", "-genkeys"]) do |genkeys|
        lines = genkeys.readlines.grep(/\s+=\s+/).map { |x| x.gsub(/\s+/, " ").gsub(/#.*/, "") }.uniq
        conffile.write lines.join("\n")
      end
      pid = fork do
        exec "#{bin}/piknik", "-server", "-config", conffile
      end
      begin
        IO.popen([{}, "#{bin}/piknik", "-config", conffile, "-copy"], "w+") do |p|
          p.write "test"
        end
        IO.popen([{}, "#{bin}/piknik", "-config", conffile, "-move"], "r") do |p|
          clipboard = p.read
          assert_equal clipboard, "test"
        end
      ensure
        Process.kill("TERM", pid)
        Process.wait(pid)
        conffile.unlink
      end
    end
  end
end
