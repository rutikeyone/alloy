import 'package:alloy/alloy.dart';

class Clock {
  const Clock();
}

class Logger {
  const Logger();
}

class Api {
  Api(this.clock);

  final Clock clock;
}

/// Asks for a [Logger] nobody registers — the hole `checkGraph` is for.
class Broken {
  Broken(this.logger);

  final Logger logger;
}

class Ticket {
  Ticket(this.id);

  final String id;
}

final class TicketFactory implements AlloyParamFactory<Ticket, String> {
  const TicketFactory();

  @override
  Ticket create(AlloyResolver resolver, String param) => Ticket(param);
}
