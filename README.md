# Heater control

This enables control of specific fujitsu aircon units.
Commands are sent via a [Iguanaworks IR Transceiver](http://www.iguanaworks.net/) IR 'Hybrid' unit with a 'Wired Emitter'.
The transmitter is connected to a linux box & scripted via Jenkins.
If you need to place the transmitter some distance from the USB dongle,
you can buy a headphone extension cable. We're using one that's 7 meters long without issue.


### Running

```
npm install -g coffee-script
npm install
./start
```

It accepts POST commands:

```
curl -X POST "http://127.0.0.1:2990/on?mode=cool&temp=23"
curl -X POST "http://127.0.0.1:2990/off"
```

There's also a systemd unit file on `other`

### What can it do?

I can't be bothered decoding the IR signal so I've resorted to capturing
some of the most useful commands from a remote control and replaying them.

To capture a command, point the remote at the unit, launch the listener, the press the button.
`igclient.exe --receiver-on --sleep 5 > out.txt`

It generates something like:
```
received 2 signal(s):
  space: 12778
  pulse: 3349
received 7 signal(s):
  space: 1536
  pulse: 469
  space: 320
  pulse: 490
received 7 signal(s):
  space: 320
  pulse: 490
  space: 298
  pulse: 490
  space: 277
  pulse: 469
  space: 1130
```

You may then send the file as is, however the recommended 'clean' file format is:
```
space 1109
pulse 490
space 1130
pulse 490
space 320
pulse 490
space 320
pulse 490
space 277
pulse 490
```


### Troubleshooting

**Does it work?**

```
igclient --get-version --get-id
```

When sending commands, it's best to debug by running the daemon interactively:
```
sudo igdaemon -n -v -v -v
```

and then send the command:
```
igclient --send=filename.txt
```

**Is the command too long?**

Sometimes you'll get length errors.
It seems you can work around this problem:

> Signals with consistently sized pulses can be compressed in our transmission buffer so if you replace all the pulse 469 lines and replace them with the more common pulse 490 then the signal fits.

[Source](http://iguanaworks.net/projects/IguanaIR/ticket/276)
