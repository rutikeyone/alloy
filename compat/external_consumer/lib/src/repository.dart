import 'package:alloy/alloy.dart';

class User {
  const User(this.name);

  final String name;
}

class Order {
  const Order(this.id);

  final int id;
}

abstract interface class Repository<T> {
  List<T> all();
}

@AlloyInject(exposeAs: Repository<User>)
class UserRepository implements Repository<User> {
  UserRepository();

  @override
  List<User> all() => const [User('ada')];
}

@AlloyInject(exposeAs: Repository<Order>)
class OrderRepository implements Repository<Order> {
  OrderRepository();

  @override
  List<Order> all() => const [Order(1), Order(2)];
}

@alloyInject
class Catalog {
  Catalog(this.users, this.orders);

  final Repository<User> users;
  final Repository<Order> orders;
}
