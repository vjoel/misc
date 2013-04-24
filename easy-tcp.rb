require 'logger'
require 'socket'

class EasyTCP
  class Server
    attr_reader :name, :pid, :addr
    
    def initialize name, pid, addr
      @name, @pid, @addr = name, pid, addr
    end
    
    def not_mine!
      @not_mine = true
      self
    end
    
    def mine?
      !@not_mine
    end
  end
  
  attr_accessor :log
  attr_accessor :servers
  attr_reader :clients
  
  def self.start log = Logger.new($stderr)
    et = new(log)
    yield et
  rescue => ex
    log.error ex
    raise
  ensure
    et.cleanup if et
  end

  def initialize log
    @log = log
    @servers = {} # name => Server
    @clients = [] # pid
  end
  
  def cleanup
    clients.each do |pid|
      Process.waitpid pid
    end
    
    servers.each do |name, server|
      if server.mine?
        log.info "stopping #{name.inspect}"
        Process.kill "TERM", server.pid
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
end
