import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  // Create the initialization Future outside of `build`:
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    // TODO initialization

    print('Initialized');
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? MaterialApp(
            title: 'Firebase Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: HomePage(),
          )
        : Material(child: Center(child: CircularProgressIndicator()));
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CounterLogic _logic = CounterLogic();
  final _focus = FocusNode();
  final _controller = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: SafeArea(
          child: StreamBuilder<List<Counter>>(
              initialData: _logic.currentCounters,
              stream: _logic.updates,
              builder: (context, snapshot) {
                final counters = snapshot.data;
                return ListView.builder(
                    itemBuilder: (context, index) {
                      final counter = counters[index];
                      return Dismissible(
                        key: ValueKey(counter.id),
                        child: _CounterItem(
                          counter: counter,
                          onUpdate: _updateCounter,
                        ),
                        onDismissed: (direction) => _deleteCounter(counter),
                      );
                    },
                    itemCount: counters.length);
              }),
        ),
        onTap: _stopEdit,
      ),
      bottomSheet: _editing
          ? WillPopScope(
              onWillPop: () async {
                if (_editing) {
                  _stopEdit();
                  return false;
                }
                return true;
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextField(
                          style: Theme.of(context).textTheme.headline6,
                          controller: _controller,
                          focusNode: _focus),
                    )),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _addCounter,
                    ),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButton: !_editing
          ? FloatingActionButton(
              onPressed: _startEdit,
              tooltip: 'Create',
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void _addCounter() {
    _logic.addCounter(_controller.value.text);
    _stopEdit();
  }

  void _updateCounter(Counter counter, int diff) {
    _logic.update(counter, diff);
    setState(() {});
  }

  void _startEdit() {
    if (_editing) {
      return;
    }
    setState(() => _editing = true);
    _focus.requestFocus();
  }

  void _stopEdit() {
    if (!_editing) {
      return;
    }
    setState(() => _editing = false);
    _controller.clear();
    _focus.unfocus();
  }

  void _deleteCounter(Counter counter) {
    _logic.deleteCounter(counter);
  }
}

class _CounterItem extends StatelessWidget {
  final Counter counter;
  final void Function(Counter counter, int diff) onUpdate;

  const _CounterItem({
    Key key,
    this.counter,
    this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(counter.name, style: Theme.of(context).textTheme.headline6),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.remove),
                onPressed: () => onUpdate?.call(counter, -1)),
            Text(counter.amount.toString(),
                style: Theme.of(context).textTheme.headline6),
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () => onUpdate?.call(counter, 1)),
          ],
        ),
      ),
    );
  }
}

class CounterLogic {
  final _controller = StreamController<Map<String, Counter>>.broadcast();
  final _currentCountersMap = <String, Counter>{};

  List<Counter> get currentCounters => _currentCountersMap.values.toList();

  Stream<List<Counter>> get updates =>
      _controller.stream.map((counters) => counters.values.toList());

  void addCounter(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _currentCountersMap[id] = Counter(id, name, 0);
    _emitUpdate();
  }

  void deleteCounter(Counter counter) {
    _currentCountersMap.remove(counter.id);
    _emitUpdate();
  }

  void update(Counter counter, int diff) {
    _currentCountersMap[counter.id] =
        Counter(counter.id, counter.name, counter.amount + diff);
    _emitUpdate();
  }

  void dispose() {
    _controller.close();
  }

  void _emitUpdate() {
    _controller.add(_currentCountersMap);
  }
}

class Counter {
  final String id;
  final String name;
  final int amount;

  const Counter(this.id, this.name, this.amount);
}
