require 'logger'
require 'socket'
require 'yaml'

class EasyTCP
  class Server
    attr_reader :name, :pid, :addr
    
    def initialize name, pid, addr
      @name, @pid, @addr = name, pid, addr
    end
  end
  
  class EasyFormatter < Logger::Formatter
    Format = "%s: %s: %s\n"

    def call(severity, time, progname, msg)
      Format % [severity[0..0], progname, msg2str(msg)]
    end
  end

  def self.default_logger
    log = Logger.new($stderr)
    log.formatter = EasyFormatter.new
    log
  end
  
  def self.null_logger
    log = Logger.new('/dev/null')
    log.level = Logger::FATAL
    log
  end

  attr_accessor :log
  attr_accessor :servers
  attr_reader :clients
  attr_reader :servers_file
  attr_reader :interactive
  
  def self.start(log: default_logger, **opts)
    et = new(**opts, log: log)
    yield et
  rescue => ex
    log.error ex
    raise
  ensure
    et.cleanup if et
  end

  def initialize **opts
    @servers_file = opts[:servers_file]
    @interactive = opts[:interactive]
    @log = opts[:log] || self.class.null_logger
    @clients = [] # pid
    @owner = false
    
    if servers_file
      @servers =
        begin
          File.open(servers_file) do |f|
            YAML.load(f)
          end
        rescue Errno::ENOENT
          nil
        end
    end
    
    unless @servers
      @servers = {} # name => Server
      @owner = true
    end
  end
  
  def cleanup
    clients.each do |pid|
      Process.waitpid pid
    end
    
    if @owner
      servers.each do |name, server|
        log.info "stopping #{name.inspect}"
        Process.kill "TERM", server.pid
      end
      (FileUtils.rm servers_file if servers_file) rescue Errno::ENOENT
    end
  end
  
  def start_servers
    if @owner
      yield

      if servers_file
        File.open(servers_file, "w") do |f|
          YAML.dump(servers, f)
        end
      end
    end
  end
  
  def server name
    rd, wr = IO.pipe

    pid = fork do
      rd.close
      log.progname = name
      log.info "starting"
      
      svr = TCPServer.new '127.0.0.1', 0
      yield svr if block_given?
      no_interrupt_if_interactive

      addr = svr.addr(false).values_at(2,1)
      Marshal.dump addr, wr
      wr.close
      sleep
    end

    wr.close
    addr = Marshal.load rd
    rd.close
    servers[name] = Server.new(name, pid, addr)
  end

  def client *server_names
    clients << fork do
      conns = server_names.map {|sn| TCPSocket.new(*servers[sn].addr)}
      yield *conns if block_given?
      no_interrupt_if_interactive
    end
  end
  
  def local *server_names
    conns = server_names.map {|sn| TCPSocket.new(*servers[sn].addr)}
    yield *conns if block_given?
  ensure
    conns and conns.each do |conn|
      conn.close unless conn.closed?
    end
  end

  # ^C in the irb session (parent process) should not kill the
  # server (child process)
  def no_interrupt_if_interactive
    trap("INT") {} if interactive
  end
end
