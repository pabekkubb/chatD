import std.socket;
import std.stdio;
import std.string;
import std.array;
import std.algorithm;
import std.datetime;
import core.thread;

class ChatClient {
  public:
    this(string serverIP, string port) {
      _tg = new ThreadGroup;
      _serverAddress = parseAddress(serverIP, port);
      _client = new TcpSocket;
      _err = false;
      //_client.blocking(false);
    }

    ~this() {
      if (!_err) {
        _client.send([false]);
        _client.shutdown(SocketShutdown.BOTH);
        _client.close();
      }
    }

    void start() {
      try {
        connect_to_server();
        _tg.create(&send_msg);
        _tg.create(&receive_msg);
      } catch {
        writeln("Serever is down"); 
        _err = true;
      }
    }

  private:
    void connect_to_server() {
      writef("Connecting to Server...%s ", _serverAddress.toAddrString());
      _client.connect(_serverAddress);
      writeln("Connected");
      writefln("Your IP Address: %s", _client.localAddress().toAddrString());
    }

    void send_msg() {
      while (1) {
        try {
          char[] text;
          text = readln().dup;
          _client.send(text);
        } catch {}
      }
    }

    void receive_msg() {
      while (1) {
        try {
          char[1024] buffer;
          auto received = _client.receive(buffer);
          if (received < 0) throw new Exception("There is no msg");
          string text = cast(string)buffer[0..received/buffer[0].sizeof];
          write("<< ");
          write(text);
        } catch {}
      }
    }

    ThreadGroup _tg;
    Address _serverAddress;
    TcpSocket _client;
    string[] _ipList;
    bool _err;
}

void main(string[] args) {
  string serverIP = args[1];
  string port = args[2];

  ChatClient client = new ChatClient(serverIP, port);
  client.start();
}

