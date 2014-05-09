library shelf_alchemy;
import 'dart:async';
import 'package:alchemy/core.dart';
import 'package:alchemy/server.dart';
import 'package:shelf/shelf.dart';
import 'package:stack_trace/stack_trace.dart' show Chain;

Database db;

Future runWithConnection(fun()) =>
  db.connect().then((conn) => runZoned(fun, zoneValues: { #alchemy_db : conn }));


Middleware connectionManager(String connStr) {
  db = new Database(connStr);
  Connection.setCurrentGetter(() => Zone.current[#alchemy_db]);
  
  return (Handler sub) => (Request req) {
    return db.connect().then((conn) => runZoned(() {
      if(conn == null) 
        throw new Exception("No database");
        
      return Chain.track(new Future.sync(() {
        return sub(req);
      }).whenComplete(conn.close));
    }, zoneValues: { #alchemy_db : conn, #alchemy_req : req }));
  };
}

Request getCurrentRequest() => Zone.current[#alchemy_req];