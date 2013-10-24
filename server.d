import std.socket;
import std.stdio;
import std.datetime;
import std.array;
import std.algorithm;
import core.thread;

class ChatServer {
  public:
    this(string ip, string port) {
      _tg = new ThreadGroup;
      _server = new TcpSocket;
      _server.blocking(false);
      //server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true); 

      Address address = parseAddress(ip, port);
      _server.bind(address);
      _server.listen(1);
    }

    ~this() {
      _server.shutdown(SocketShutdown.BOTH);
      _server.close();
    }

    void start() {
      _tg.create(&add_node);
      _tg.create(&send_packet);
      _tg.create(&receive_packet);
    }

  private:
    void add_node() {
      while (1) {
        try {
          _nodes ~= _server.accept();
          _nodes[$-1].blocking(false);
          writefln("[Joined](%s) %s", _nodes[$-1].remoteAddress(), Clock.currTime());
        } catch {}

        Thread.sleep( dur!("seconds")(1) );
      }
    }

    void send_packet() {
      while (1) {
        try {
          foreach (msg; _newMsg) {
            foreach (node; _nodes) {
              if (msg[2] != node.remoteAddress().toPortString()) // You can also restrict IP
                node.send(msg[0]);
            }
          }
          _newMsg.length = 0;
        } catch {}

        Thread.sleep( dur!("msecs")(100) );
      }
    }

    void receive_packet() {
      void remove_node() {
        bool[1] flag;
        _nodes = filter!(x => x.receive(flag))(_nodes).array;
      }

      while (1) {
        try {
          char[1024] buffer;
          foreach (node; _nodes) {
            auto received = node.receive(buffer);
            if (received < 0) continue;
            if (received == 0) remove_node();
            if (received > 0) {
              string text = cast(string)buffer[0..received/buffer[0].sizeof];
              _newMsg ~= [ text, node.remoteAddress().toAddrString(), node.remoteAddress().toPortString() ];
              write(text);
            }
          }
        } catch {}

        Thread.sleep( dur!("msecs")(100) );
      }
    }

    ThreadGroup _tg;
    TcpSocket _server;
    Socket[] _nodes;
    string[3][] _newMsg;
}

void main(string[] args) {
  string ip = args[1];
  string port = args[2];

  ChatServer server = new ChatServer(ip, port);
  server.start();
}

