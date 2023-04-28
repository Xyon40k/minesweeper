import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';

import 'package:icon_decoration/icon_decoration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campo Minato',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Campo Minato'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int size = 10;
  final Color cellcolor = const Color.fromARGB(255, 196, 196, 196);
  int difficulty = 2;
  late int bombs;
  late int flags;
  late int toclick;
  late Timer timer;
  late Color bgcolor;
  int elapsed = 0;
  bool stopped = false;
  bool settingup = false;
  bool firstclick = true;

  late TextEditingController custombombs;

  late List<Widget> _containers;
  late List<List<bool>> _bombs;
  late List<List<bool>> _clicked;
  late List<List<bool>> _flags;

  final List<double> difficulties = [8, 6.5, 5, 4];
  Map<int, Color> colors = {
    1: const Color.fromARGB(255, 0, 0, 212),
    2: const Color.fromARGB(255, 3, 179, 3),
    3: const Color.fromARGB(255, 232, 12, 12),
    4: const Color.fromARGB(255, 183, 11, 246),
    5: Colors.amber,
    6: const Color.fromARGB(255, 79, 186, 200),
    7: const Color.fromARGB(255, 125, 25, 58),
    8: const Color.fromARGB(255, 23, 23, 23)
  };

  _MyHomePageState() {
    setup();
  }

  void setup([int? nbombs]) {
    if (settingup) {
      return;
    }

    settingup = true;

    _containers = [];
    _bombs = [];
    _clicked = [];
    _flags = [];

    bombs = nbombs ?? (size * size / difficulties[difficulty]).floor();
    flags = bombs;
    toclick = size * size - bombs;
    elapsed = 0;
    stopped = false;
    bgcolor = Colors.white;
    firstclick = true;

    custombombs = TextEditingController();

    createfields();

    for (int i = 1; i < size + 1; i++) {
      for (int j = 1; j < size + 1; j++) {
        _containers.add(
          Container(
            color: cellcolor,
            alignment: Alignment.center,
            child: TextButton(
                onPressed: () {
                  reveal(i, j);
                },
                onLongPress: () {
                  flag(i, j);
                },
                child: const Text("")),
          ),
        );
      }
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsed++;
      });
    });

    settingup = false;
  }

  void createfields() {
    for (int i = 0; i < size + 2; i++) {
      _bombs.add(<bool>[]);
      _clicked.add(<bool>[]);
      _flags.add(<bool>[]);
      for (int j = 0; j < size + 2; j++) {
        _bombs[i].add(false);
        _clicked[i].add(false);
        _flags[i].add(false);
      }
    }
  }

  void placebombs(int y, int x) {
    Random r = Random();
    while (bombs > 0) {
      int cx = r.nextInt(size) + 1;
      int cy = r.nextInt(size) + 1;
      if (_bombs[cy][cx] == false && !(cx == x && cy == y)) {
        _bombs[cy][cx] = true;
        bombs--;
      }
    }
    bombs = flags;
  }

  int near(int y, int x) {
    int count = 0;
    for (int i = -1; i < 2; i++) {
      for (int j = -1; j < 2; j++) {
        if (_bombs[y + i][x + j]) {
          count++;
        }
      }
    }
    return count;
  }

  void reveal(int y, int x) {
    if (stopped) {
      return;
    }

    if (y == 0 || y == size + 1 || x == 0 || x == size + 1) {
      return;
    }

    if (_flags[y][x]) {
      return;
    }

    if (_clicked[y][x]) {
      return;
    }

    if (firstclick) {
      placebombs(y, x);
      firstclick = false;
    }

    _clicked[y][x] = true;

    Widget toadd;

    if (_bombs[y][x]) {
      setState(() {
        _containers[(y - 1) * size + (x - 1)] = Container(
            color: Colors.white,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(1),
            child: const Icon(Icons.sunny, color: Colors.black));
      });
      lose();
      return;
    }

    toclick--;
    int num = near(y, x);

    if (num == 0) {
      toadd = Container(
          color: Colors.white,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(1),
          child: const Icon(null));

      for (int dy = -1; dy < 2; dy++) {
        for (int dx = -1; dx < 2; dx++) {
          reveal(y + dy, x + dx);
        }
      }
    } else {
      toadd = Container(
          color: Colors.white,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(1),
          child:
              Text("$num", style: TextStyle(fontSize: 26, color: colors[num])));
    }

    if (toclick == 0) {
      win();
    }

    setState(() {
      _containers[(y - 1) * size + (x - 1)] = toadd;
    });
  }

  void flag(int y, int x) {
    if (stopped) {
      return;
    }

    bool newstate = !_flags[y][x];
    setState(() {
      _flags[y][x] = newstate;
      newstate ? flags-- : flags++;
      _containers[(y - 1) * size + (x - 1)] = newstate
          ? Container(
              color: cellcolor,
              alignment: Alignment.center,
              child: Stack(alignment: Alignment.center, children: [
                const DecoratedIcon(
                  icon: Icon(Icons.flag, color: Colors.red, size: 30,),
                  decoration: IconDecoration(
                    border: IconBorder(color: Colors.black, width: 2)
                  ),
                ),
                TextButton(
                    onPressed: () {
                      reveal(y, x);
                    },
                    onLongPress: () {
                      flag(y, x);
                    },
                    child: const Text("")),
              ]),
            )
          : Container(
              color: cellcolor,
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  reveal(y, x);
                },
                onLongPress: () {
                  flag(y, x);
                },
                child: const Text(""),
              ),
            );
    });
  }

  void lose() {
    timer.cancel();
    stopped = true;

    for (int i = 1; i < size + 1; i++) {
      for (int j = 1; j < size + 1; j++) {
        if(_flags[i][j]) {
          if(!_bombs[i][j]) {
            _containers[(i - 1) * size + (j - 1)] = Container(
              color: cellcolor,
              alignment: Alignment.center,
              child: Stack(alignment: Alignment.center, children: const [
                DecoratedIcon(
                  icon: Icon(Icons.flag, color: Colors.red, size: 35,),
                  decoration: IconDecoration(
                    border: IconBorder(color: Colors.black, width: 2)
                  ),
                ),
                Icon(Icons.close, size: 30, color: Colors.black),
              ]),
            );
          } else {
            _containers[(i - 1) * size + (j - 1)] = Container(
              color: cellcolor,
              alignment: Alignment.center,
              child: const DecoratedIcon(
                icon: Icon(Icons.flag, color: Colors.red, size: 30,),
                decoration: IconDecoration(
                  border: IconBorder(color: Colors.black, width: 2)
                )
              )
            );
          }
        } else {
          if(_bombs[i][j]) {
            _containers[(i - 1) * size + (j - 1)] = Container(
              color: cellcolor,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(1),
              child: const Icon(Icons.sunny, color: Colors.black)
            );
          } else if(!_clicked[i][j]) {
            _containers[(i - 1) * size + (j - 1)] = Container(
              color: cellcolor,
            );
          }
        }
      }
    }

    setState(() {
      bgcolor = const Color.fromARGB(255, 241, 66, 66);
    });
  }

  void win() {
    timer.cancel();
    stopped = true;

    for (int i = 1; i < size + 1; i++) {
      for (int j = 1; j < size + 1; j++) {
        if(!_flags[i][j]) {
          if(_bombs[i][j]) {
            _containers[(i - 1) * size + (j - 1)] = Container(
              color: cellcolor,
              alignment: Alignment.center,
              child: DecoratedIcon(
                icon: Icon(Icons.flag, color: Colors.amber[900], size: 30,),
                decoration: const IconDecoration(
                  border: IconBorder(color: Colors.black, width: 2)
                )
              )
            );
          }
        } else {
          _containers[(i - 1) * size + (j - 1)] = Container(
            color: cellcolor,
            alignment: Alignment.center,
            child: const DecoratedIcon(
              icon: Icon(Icons.flag, color: Colors.red, size: 30,),
              decoration: IconDecoration(
                border: IconBorder(color: Colors.black, width: 2)
              )
            )
          );
        }
      }
    }

    setState(() {
      bgcolor = Colors.green;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
          color: bgcolor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                  flex: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const SizedBox(width: 30),
                        const DecoratedIcon(
                          icon: Icon(Icons.flag, color: Colors.red, size: 30,),
                          decoration: IconDecoration(
                            border: IconBorder(color: Colors.black, width: 2)
                          ),
                        ),
                        Text(" $flags ", style: const TextStyle(fontSize: 22)),
                      ]),
                      Row(children: [
                        Text("Tempo: ${elapsed}s",
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 30),
                      ]),
                    ],
                  )),
              const Flexible(flex: 1, child: Icon(null)),
              Flexible(
                flex: 8,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                          color: bgcolor,
                          padding: const EdgeInsets.all(5),
                          child: Container(
                              color: Colors.black,
                              padding: const EdgeInsets.all(5),
                              child: GridView.count(
                                  crossAxisCount: size,
                                  shrinkWrap: true,
                                  mainAxisSpacing: 2,
                                  crossAxisSpacing: 2,
                                  children: List.from(_containers))))
                    ]),
              )
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => SimpleDialog(
              contentPadding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              title: const Text("Scegli la difficoltà:"),
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => SimpleDialog(
                        contentPadding: const EdgeInsets.all(30),
                        alignment: Alignment.center,
                        title: const Text("Personalizzato"),
                        children: [
                          TextField(
                            controller: custombombs,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Numero di bombe:',
                              hintText: 'Digita il numero di bombe',
                            ),
                          ),
                          TextButton(
                              onPressed: () {
                                int? a = int.tryParse(custombombs.text);
                                if (a == null || a < 1 || a > size * size - 1) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Errore"),
                                      content: Text(
                                          "'${custombombs.text}' non è un valore valido"),
                                      actions: <Widget>[
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("Ok"))
                                      ],
                                    ),
                                  );
                                } else {
                                  timer.cancel();
                                  setup(a);
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text("Fatto",
                                  style: TextStyle(fontSize: 20)))
                        ],
                      ),
                    );
                  },
                  child: const Text("Personalizzato",
                      style: TextStyle(fontSize: 20, color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    timer.cancel();
                    setState(() {
                      difficulty = 0;
                    });
                    setup();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Facile",
                      style: TextStyle(fontSize: 20, color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    timer.cancel();
                    setState(() {
                      difficulty = 1;
                    });
                    setup();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Medio",
                      style: TextStyle(fontSize: 20, color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    timer.cancel();
                    setState(() {
                      difficulty = 2;
                    });
                    setup();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Difficile",
                      style: TextStyle(fontSize: 20, color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    timer.cancel();
                    setState(() {
                      difficulty = 3;
                    });
                    setup();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Molto difficile",
                      style: TextStyle(
                          fontSize: 22, color: Color.fromARGB(255, 255, 0, 0))),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Chiudi", style: TextStyle(fontSize: 18)),
                )
              ],
            ),
          );
        },
        tooltip: "Restarts the game",
        child: const Icon(Icons.restart_alt, color: Colors.white),
      ),
    );
  }
}
