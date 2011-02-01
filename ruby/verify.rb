#v0.1
def check_os
  unless File.file?("/etc/debian_version")
    $stderr.puts "Incorrect OS."
    exit 2
  end
end

def grep_file filename, regex, errmsg
  File.open(filename, "r") { |file|
    unless file.read =~ regex
      $stderr.puts errmsg
      exit 2
    end
  }
end

def run_cmd cmd, regex, errmsg
  %x{#{cmd}}.each { |output|
    if output =~ regex
      $stderr.puts errmsg
      exit 2
    end
  }
end

def count_output cmd
  i = 0
  %x{#{cmd}}.each { |line|
    i = i+1
  }
  return i
end

def check_updated_packages
  a = count_output "find /var/lib/apt/lists/ -mtime -14"
  b = count_output "apt-show-versions -u"

  if (a == 0)
    $stderr.puts "apt-repo-sources not updated last two weeks."
    exit 2
  end

  if (b > 15)
    $stderr.puts "More than 15 packages needs to be updated."
    exit 2
  end
end

def verify_security
  count = count_output "find /tmp/mnodaemon.tmp -mtime -14"
  puts count
  if count == 0
    if File.exists?("/tmp/(mnodaemon.tmp");  File.delete("/tmp/mnodaemon.tmp"); end
    %x{wget -q -O /tmp/mnodaemon.tmp http://spheniscus.uio.no/ubuntu/dists/}
  end
  curr = %x{grep security /etc/apt/sources.list|cut -d " " -f 3|tail -n 1}.strip!
  grep_file "/tmp/mnodaemon.tmp", Regexp.new("/.*" + curr + ".*/"), "distribution no longer maintained."
end

loop do
  check_os
  grep_file "/etc/shadow", /^mnouser.*/, "mnouser not found"
  grep_file "/etc/sudoers", /^mnouser ALL=NOPASSWD: ALL.*/, "mnouser not found in sudoers"
  run_cmd "ps ax", /.*dhcpd.*/, "DHCP Daemon running."
  run_cmd "dmesg", /.*entered promiscuous mode.*/, "NIC running in promiscuous mode."
  check_updated_packages
  verify_security
  sleep 300
end
