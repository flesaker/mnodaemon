#v0.1

def grep_file filename, regex, errmsg
  File.open(filename, "r") { |file|
    unless file.read =~ regex
      $stderr.puts errmsg
      exit 2
    end
  }
end

def run_cmd cmd, regex, errmsg
  if %x[#{cmd}] =~ regex
    $stderr.puts errmsg
    exit 2
  end
end

def count_output cmd
  i = 0
  %x[#{cmd}].split(/\n\s*/).each { |line|
    i = i+1
  }
  return i
end
## Ubuntu checks ##
def check_updated_packages
  if (count_output("find /var/lib/apt/lists/ -mtime -14") == 0)
    $stderr.puts "apt-repo-sources not updated last two weeks."
    exit 2
  end

  if (count_output("apt-show-versions -u") > 15)
    $stderr.puts "More than 15 packages needs to be updated."
    exit 2
  end
end

def verify_security
  count = count_output "find /tmp/mnodaemon.tmp -mtime -14 2> /dev/null"
  puts count
  if count == 0
    if File.exists?("/tmp/(mnodaemon.tmp");  File.delete("/tmp/mnodaemon.tmp"); end
    %x{wget -q -O /tmp/mnodaemon.tmp http://spheniscus.uio.no/ubuntu/dists/}
  end
  curr = %x{grep security /etc/apt/sources.list|cut -d " " -f 3|tail -n 1}.strip!
  grep_file "/tmp/mnodaemon.tmp", Regexp.new("/.*" + curr + ".*/"), "distribution no longer maintained."
end

def check_os
  if File.file?("/etc/debian_version")
    return lambda do
      check_updated_packages
      verify_security
    end
  elsif File.file?("/etc/SuSE-release")
    return lambda do
      if (count_output("find /tmp/mnodaemon.tmp -mtime -14 2> /dev/null") == 0)
        run_cmd "curl --write-out %{http_code} --silent --output /dev/null http://download.opensuse.org/update/$(grep VERSION /etc/SuSE-release | egrep -o '[0-9]+\.[0-9]+')/", /^200.$/, "distro no longer supported"
        %x[touch /tmp/mnodaemon.tmp]
      end

      if (count_output("zypper --no-refresh lu | tail -n +4") > 15)
        $stderr.puts "More than 15 packages needs to be updated."
        exit 2
      end

      %x[zypper --no-refresh lr | egrep "Yes\s+.\s+(Yes|No)" | cut -d " " -f 4].split(/\s+/).each do |repo|
        if count_output("find /var/cache/zypp/raw/#{repo} -mtime -14 | egrep \"content$|repomd.xml$\"") == 0
          $stderr.puts "Repo #{repo} needs to be updated"
          exit 2
        end
      end
    end
  else
    $stderr.puts "Incorrect OS."
    exit 2
  end
end

loop do
  verifier = check_os
  grep_file "/etc/shadow", /^mnouser.*/, "mnouser not found"
  grep_file "/etc/sudoers", /^mnouser ALL=NOPASSWD: ALL.*/, "mnouser not found in sudoers"
  run_cmd "ps ax", /.*dhcpd.*/, "DHCP Daemon running."
  run_cmd "dmesg", /.*entered promiscuous mode.*/, "NIC running in promiscuous mode."
  verifier.call
  sleep 300
end
