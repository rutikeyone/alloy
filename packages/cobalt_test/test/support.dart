import 'package:cobalt/cobalt.dart';

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

final class TicketFactory implements CobaltParamFactory<Ticket, String> {
  const TicketFactory();

  @override
  Ticket create(CobaltResolver resolver, String param) => Ticket(param);
}
