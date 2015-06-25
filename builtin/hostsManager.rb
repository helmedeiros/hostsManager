#!/usr/bin/env ruby

#External Libary
require "yaml"

require 'os'

class HostManager


  private
  #validate working dirs
  #return working dir from hoster
  def getWorkingDir
    if(@workingDir != nil)
      return @workingDir
    end
    currDir = Dir.pwd
    dr = ""
    currDir.split("/").each{ |entry|
      dr = dr+entry+"/"
      #puts dr
      if(File.directory? dr+".hoster")
        @workingDir = dr+".hoster"
      end
    }
    @workingDir
  end

  def projectName
    getWorkingDir.split('/').pop(2)[0]
  end

  def validateWorkingDir!
    dir = getWorkingDir
    return File.exist? (dir == nil ? "" : dir) +'/data.host'
  end

  #for Human readers
  def generateFiles! plataform
    File.open(getWorkingDir+'/Hosts.'+plataform.getName, 'w'){ |f|
      f.write("## WARNING")
      f.write("## This file is autogenerated do not alter, you may loose it's contents.")
      f.write("###########\n")
      f.write(plataform.toString)
    }
  end

  def getHostFile
    hostFile = nil
    if(OS.windows?)
      hostFile = "c:\\windwos\system32\drivers\etc\hosts"
    end

    if(OS.mac?)
      hostFile = "/etc/hosts"
    end

    if(OS.linux?)
      hostFile = "/etc/hosts"
    end

    if(hostFile == nil)
      puts 'Hosts file not found.'
    end

    hostFile
  end


  public
  def initialize
    @plataforms = Hash.new
    @verbose = false
    @workingDir = nil
  end


  #Initialize Repository
  def initRepository
    currDir = Dir.pwd
    workdir = getWorkingDir unless nil
    if(workdir != nil)
      puts ".#{PROGNAME} is already initialized and located at #{workdir}"
    else
      #.hoster not located, so initialize the repository
      if(@verbose)
        puts ".Initializing #{PROGNAME} repository"
      end
      hDir = currDir+"/.hoster"
      Dir.mkdir(hDir)
      File.open(hDir+"/Hosts", "w"){ |f|
          f.write("#Auto-generated file, do not manualy alter.");
      }
      puts "Initialized empty Hosts repository in #{currDir}"
      File.open(hDir+"/data.host", "w"){ |f| }
      if(@verbose)
        puts "Initialized empty Data Hosts DB in #{currDir}"
        puts ".Done"
      end
    end
    #puts workdir
  end

  #controls the verbosity from Hoster
  def setVerbosity(v)
    @verbose = v
  end

  #load Data into memory
  def loadData!
    v = validateWorkingDir!
    @plataforms = YAML::load_file(File.open(getWorkingDir+'/data.host', 'r'))
    if(@plataforms == false)
      @plataforms = Hash.new
    end
    return v
  end

  #persist data from memory
  def persistData!
    File.open(getWorkingDir+'/data.host', 'w') do |f|
      f.write(@plataforms.to_yaml)
    end
  end

  #Methods from Apply, Remove, Add


  def show!
    puts 'Current Hosts:'
    @plataforms.each do |key, plataform|
      puts plataform.toString
    end
  end

  #add the HOST to the respective plataform
  def add(host, ip, plataform)
    #verify if we have the plataform name initialized
    if(! (@plataforms.keys.include? plataform))
        @plataforms[plataform] = Plataform.new(plataform, projectName);
    end
    if( @plataforms[plataform].add(Host.new(ip, host, @plataforms[plataform])))
      puts "Added succefully."
    end

    if(@verbosity)
      puts "Generating Files ..."
    end

    generateFiles! @plataforms[plataform]

  end

  #add the HOST to the respective plataform
  def edit(host, ip, plataform)
    #verify if we have the plataform name initialized
    if(! (@plataforms.keys.include? plataform))
        add(host,ip,plataform)
    else
      #replace the old with the new host
      if( @plataforms[plataform].edit(Host.new(ip, host, @plataforms[plataform])) )
        puts "Edited succefully."
      end
    end

    if(@verbosity)
      puts "Generating Files ..."
    end

    generateFiles! @plataforms[plataform]

  end

  #remove HOST form the respective plataform
  def remove(host, plataform)
    @plataforms[plataform].rem(host)
  end

  def apply pl
    host = getHostFile
    pl.each { |plataform|
      if(! (@plataforms.keys.include? plataform))
        puts 'Plataform not found, these are the plataforms avaliable'
        show!
        return
      end
      @plataforms[plataform].apply! host
    }

  end

  def clean pl
    host = getHostFile

    pl.each { |plataform|
      if(! (@plataforms.keys.include? plataform))
        puts 'Plataform not included'
        return
      end
      @plataforms[plataform].clean! host
    }

  end


end