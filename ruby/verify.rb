def check_os
  unless File.file?("/etc/debian_version")
    $stderr.puts "Incorrect OS."
    exit 2
  end
end

def check_user
  File.open("/etc/shadow", "r") { |file|
    unless file.read =~ /^mnouser.*/
      $stderr.puts "mnouser not found."
      exit 2
    end
  }
end

def check_sudo
  File.open("/etc/sudoers", "r") { |file|
    unless file.read =~ /^mnouser ALL=NOPASSWD: ALL.*/
      $stderr.puts "mnouser not found in sudoers."
      exit 2
    end
  }
end

def check_dhcpd
  %x{ps ax}.each { |proc|
    if proc =~ /.*dhcpd.*/
      $stderr.puts "DHCP Daemon running."
      exit 2
    end
  }
end

def check_promiscuous
  %x{dmesg}.each { |line|
    if line =~ /.*entered promiscuous mode.*/
      $stderr.puts "NIC running in promiscuous mode."
      exit 2
    end
  }
end

def check_updated_packages
  i = 0
  %x{find /var/lib/apt/lists/ -mtime -14}.each { |line|
    i = i+1
  }
  if (i == 0)
    $stderr.puts "apt-repo-sources not updated last two weeks."
    exit 2
  end
  i = 0
  %x{apt-show-versions -u}.each { |line|
    i = i+1
  }
  if (i > 15)
    $stderr.puts "More than 15 packages needs to be updated."
    exit 2
  end
end

loop do
  check_os
  check_user
  check_sudo
  check_dhcpd
  check_promiscuous
  check_updated_packages
  sleep 300
end
