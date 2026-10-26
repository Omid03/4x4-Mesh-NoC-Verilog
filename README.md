# 4×4 Mesh Network-on-Chip in Verilog

A parameterized, packet-switched Network-on-Chip (NoC) built as a 4×4 two-dimensional mesh. Each of the 16 tiles combines a five-port router with a local traffic node. The router uses input buffering, deterministic XY routing, fixed-priority output arbitration, and request/acknowledge handshakes.

![Complete 4×4 NoC](docs/diagrams/noc-system.svg)

---

## Table of Contents

- [Design Summary](#design-summary)
- [System Architecture](#system-architecture)
- [Router Microarchitecture](#router-microarchitecture)
  - [Input Buffer and Packet Lifecycle](#input-buffer-and-packet-lifecycle)
  - [Flit Format](#flit-format)
  - [XY Routing](#xy-routing)
  - [Switch Allocation and Datapath](#switch-allocation-and-datapath)
- [Handshake Behavior](#handshake-behavior)
- [Repository Layout](#repository-layout)
- [Simulation](#simulation)
- [Configuration](#configuration)
- [Synthesis Status and Known Limitations](#synthesis-status-and-known-limitations)
- [Packet Transfer and Control](#packet-transfer-and-control)
  - [Packet structure and destination capture](#packet-structure-and-destination-capture)
  - [FIFO controller](#fifo-controller)
  - [Illustrative handshake timing](#illustrative-handshake-timing)
- [Example Traffic and Verification](#example-traffic-and-verification)
  - [Concurrent traffic scenario](#concurrent-traffic-scenario)
  - [Expected packet contents](#expected-packet-contents)
  - [Verification status and observation points](#verification-status-and-observation-points)

---

## Design summary

| Property | Default configuration |
| --- | --- |
| Topology | 4×4 bidirectional mesh |
| Number of tiles | 16 |
| Router ports | Local, West, North, East, South |
| Data payload width | 16 bits |
| Flit width | 18 bits: 2-bit type plus 16-bit payload |
| Input buffers | Five FIFOs per router |
| FIFO depth | Four flits |
| Routing | Deterministic XY, X dimension before Y |
| Arbitration | Fixed priority: Local > West > North > East > South |
| Flow control | Per-link request/acknowledge handshake |
| Default top module | `NoC` |
| Main system testbench | `NoC_TB` |

## System architecture

Router IDs use row-major order. For the default configuration, router `0` is at coordinate `(0,0)`, router `3` is at `(3,0)`, and router `15` is at `(3,3)`. The top-level `NoC` module creates the mesh with nested generate loops and connects adjacent tiles through separate data, request, and acknowledge signals in both directions.

| Row | West to east |
| --- | --- |
| 0 | `0` `1` `2` `3` |
| 1 | `4` `5` `6` `7` |
| 2 | `8` `9` `10` `11` |
| 3 | `12` `13` `14` `15` |

Each tile is a `NodeRouter` wrapper. Its local port attaches a traffic-generating `Node` to a `Router`; its remaining four ports attach to neighboring routers.

![NodeRouter integration](docs/diagrams/node-router.svg)

The supplied system testbench starts three packets on consecutive clock edges. These packets travel from node 8 to node 1, node 6 to node 4, and node 7 to node 5. The paths overlap and exercise simultaneous arbitration.

## Router microarchitecture

Every input port owns a four-entry FIFO. After a complete packet has been accepted, the FIFO exposes its destination to the routing unit and requests an output. A single `RoutingUnit` computes a three-bit direction for each of the five input buffers. Five output `Switch` instances then arbitrate independently, select one buffered input, and return the downstream acknowledgement to the selected FIFO.

![Router microarchitecture](docs/diagrams/router-microarchitecture.svg)

| Route code | Output |
| --- | --- |
| `3'b000` | Local |
| `3'b001` | West |
| `3'b010` | North |
| `3'b011` | East |
| `3'b100` | South |

### Input buffer and packet lifecycle

The buffer is split into `fifo_datapath` and `fifo_control`. The datapath stores payload and flit-type bits in parallel memories, maintains read and write pointers, and tracks occupancy. The controller waits for an upstream request, acknowledges packet admission, writes the incoming flits, requests a routed output, and drains the stored packet after output arbitration succeeds.

![FIFO logic](docs/diagrams/fifo-gate-level.svg)

The controller follows this sequence:

`WRI → GAI → WAIT1 → WAIT2 → RDI → RP → GRO → WAO → WAIT3 → SDO`

| State group | Function |
| --- | --- |
| `WRI`, `GAI` | Wait for and acknowledge the upstream packet request |
| `WAIT1`, `WAIT2` | Provide handshake settling cycles |
| `RDI` | Write flits until a tail flit is observed |
| `RP` | Request allocation for the decoded destination |
| `GRO`, `WAO` | Request the output and wait for the downstream handshake |
| `WAIT3`, `SDO` | Read and transmit the packet until its tail leaves the FIFO |

### Flit format

The external data path is `DATA_WIDTH + 2` bits. With the default `DATA_WIDTH = 16`, every flit is 18 bits wide.

| Bits | Field | Meaning |
| --- | --- | --- |
| `[17:16]` | Flit ID | `01` header, `00` body, `10` tail |
| `[15:8]` | Header metadata | Traffic-pattern field used by the supplied node |
| `[7:4]` | Source | Four-bit source node ID in header flits |
| `[3:0]` | Destination | Four-bit destination node ID in header flits |

The destination register captures `data[3:0]` when the stored flit ID equals `2'b01`. The built-in traffic node emits fixed four-flit packets consisting of one header, two body flits, and one tail.

### XY routing

`CordinateChecker` derives destination coordinates as `xd = dest % DIM` and `yd = dest / DIM`. It compares those coordinates with the current router coordinates. Horizontal movement has priority: West or East is selected until `xd` equals the local X coordinate, after which North or South is selected. A matching X and Y coordinate selects the Local output.

![Routing-unit logic](docs/diagrams/routing-unit-gate-level.svg)

This order is deterministic and prevents routing cycles for the intended rectangular mesh because packets never return to the X dimension after entering the Y dimension.

### Switch allocation and datapath

One `SwitchAllocator` is instantiated for each output port. Each allocator checks all five input requests against that output's port ID. Matching requests enter a fixed-priority AND chain. `BusyChecker` locks the current decision while an active request still owns its grant, preventing a newly arriving, higher-priority input from interrupting a packet already in flight.

![Switch-allocator logic](docs/diagrams/switch-allocator-gate-level.svg)

The selected grant controls two primitives. A five-input one-hot multiplexer forwards `{reqO, data}` to the chosen output, while a one-hot demultiplexer returns the downstream acknowledgement only to the selected input buffer.

## Handshake behavior

The design uses two related handshakes around each input buffer. At packet admission, an upstream sender raises `reqI` and waits for `ackI`; after admission, it lowers `reqI` and presents the flits. For forwarding, the FIFO raises `reqA` to obtain a switch grant and then raises `reqO` toward the next hop. The downstream `ackO` completes the transfer. The switch maps these signals to the appropriate input without broadcasting acknowledgements to competing inputs.

Signal names are written from the buffer's point of view:

| Signal | Direction at FIFO | Purpose |
| --- | --- | --- |
| `reqI`, `ackI` | Input, output | Packet-admission request and acknowledgement |
| `reqA`, `ackA` | Output, input | Switch-allocation request and grant |
| `reqO`, `ackO` | Output, input | Downstream transfer request and acknowledgement |
| `data_in`, `data_out` | Input, output | 18-bit flit path at default width |

## Repository layout

```text
.
├── README.md
├── rtl
│   ├── FIFO.v
│   ├── NoC.v
│   ├── Node.v
│   ├── NodeRouter.v
│   ├── Router.v
│   ├── RoutingUnit.v
│   ├── SwitchAlocator.v
│   └── premitives.v
├── tb
│   ├── FIFO_TB.v
│   ├── NoC_TB.v
│   └── NodeRouterTB.v
└── docs
    └── diagrams
        ├── fifo-gate-level.svg
        ├── noc-system.svg
        ├── node-router.svg
        ├── router-microarchitecture.svg
        ├── routing-unit-gate-level.svg
        └── switch-allocator-gate-level.svg
```

| Source file | Role |
| --- | --- |
| `premitives.v` | Enabled register, five-input one-hot mux, and five-output one-hot demux |
| `FIFO.v` | Input-buffer datapath and handshake FSM |
| `RoutingUnit.v` | Coordinate comparison and next-hop selection |
| `SwitchAlocator.v` | Busy detection, fixed-priority allocation, and switch datapath |
| `Router.v` | Five FIFOs, one routing unit, and five output switches |
| `Node.v` | Simulation traffic source and sink |
| `NodeRouter.v` | Router plus local node wrapper |
| `NoC.v` | Generated two-dimensional mesh |

The filenames `premitives.v` and `SwitchAlocator.v` retain the spelling used by the original source. Module names and compile commands therefore remain compatible with the submitted project.

## Simulation

The testbenches use SystemVerilog-compatible constructs and `$stop`. QuestaSim or ModelSim is the most direct environment for reproducing the reported waveforms.

```tcl
vlib work
vlog -sv rtl/premitives.v rtl/FIFO.v rtl/RoutingUnit.v \
  rtl/SwitchAlocator.v rtl/Router.v rtl/Node.v \
  rtl/NodeRouter.v rtl/NoC.v tb/NoC_TB.v
vsim -voptargs=+acc NoC_TB
add wave -r sim:/NoC_TB/NoC_UT/*
run -all
```

For Icarus Verilog with SystemVerilog enabled:

```bash
mkdir -p build
iverilog -g2012 -s NoC_TB -o build/noc_tb.vvp \
  rtl/*.v tb/NoC_TB.v
vvp build/noc_tb.vvp
```

The included tests cover three levels:

| Testbench | Scope |
| --- | --- |
| `FIFO_TB.v` | Four-flit write, allocation handshake, and packet readout |
| `NodeRouterTB.v` | Two neighboring NodeRouter instances and an inter-router transfer |
| `NoC_TB.v` | Three concurrent packets across the full 4×4 mesh |

`NodeRouterTB.v` leaves its router reset ports open in the original source. Connect `.rst(rst)` on both instances before using that test as a strict reset-sensitive regression.

## Configuration

`NoC.v` derives its mesh dimension using `$sqrt(SIZE)`, while `RoutingUnit.v` uses `$clog2(SIZE)` as the coordinate divisor. Both evaluate to four when `SIZE = 16`; they are not equivalent for arbitrary sizes. Treat the current top level as a 4×4 design unless both expressions and destination widths are revised together.

## Synthesis status and known limitations

The router datapath is written as RTL, but the complete repository should be treated as a simulation-oriented course design. The SVGs labeled “gate-level” are logic schematics derived directly from the RTL operators and state elements. They are not technology-mapped standard-cell netlists.

| Area | Current RTL behavior | Recommended correction before synthesis |
| --- | --- | --- |
| `Node.v` | Contains event controls, `while` loops, and test traffic inside clocked procedures | Replace it with a synthesizable network interface or exclude it from synthesis |
| FIFO pointers | Pointer wrap checks compare the old pointer to `DEPTH`, allowing an out-of-range index before wrap | Wrap at `DEPTH - 1` or size pointers from `$clog2(DEPTH)` |
| FIFO occupancy | Separate nonblocking assignments to `fifo_count` conflict when read and write occur together | Use a combined `{write_en, read_en}` update case |
| FIFO reset | The datapath reset is generated by the FIFO FSM; `fifo_control` has no explicit reset input | Add a top-level reset to the controller and datapath |
| Primitive reset | `flopenr` resets registers to high impedance | Reset state-holding registers to a defined binary value |
| Mesh boundaries | Edge-facing link arrays have no explicit terminators | Tie inactive inputs low and provide defined acknowledgements |
| Parameterization | Coordinate math only agrees for the default 16-node case | Derive one `DIMENSION` value and use it consistently |
| Test visibility | Testbenches stop without a self-checking scoreboard | Add assertions, packet monitors, and pass/fail reporting |

The FIFO memory is not cleared after a packet. Only its pointers and occupancy control are recycled, so stale or unknown values can appear on internal data wires before a valid request. Consumers must qualify data with the handshake signals.

## Packet Transfer and Control

### Packet structure and destination capture

The supplied traffic generator sends four-flit packets: one header, two body flits, and one tail. With the default configuration, each flit contains a 16-bit payload and a 2-bit type identifier. Header, body, and tail identifiers are `01`, `00`, and `10`, respectively.

![Packet structure and destination capture](docs/diagrams/additions/packet-format.png)

In a header, bits `[15:8]` contain the pattern byte chosen by `Node.v`, bits `[7:4]` contain the source ID, and bits `[3:0]` contain the destination ID. The router uses the destination to select the next hop; it does not decode the pattern byte or source ID for routing. The source/destination interpretation applies to headers only.

The destination register is enabled by `flitID_mem[0] == 2'b01` and captures `fifo_mem[0][3:0]` on a rising clock edge when enabled and not reset. This is a memory-slot-zero check, not a check of the current read pointer. Memory contents are retained between packets, so the enable can remain asserted while a previous header remains in slot zero; it is not a one-cycle header-arrival pulse.

### FIFO controller

The FIFO controller receives a complete packet before requesting an output. Its ten states coordinate upstream admission, writing, output allocation, downstream admission, and reading.

![FIFO controller states, transition conditions, and output decoding](docs/diagrams/additions/fifo-fsm.png)

`WRI` asserts the internal datapath reset. `GAI` acknowledges the upstream request, and `WAIT1` and `WAIT2` provide two intervening states before `RDI` enables writing. The controller exits `RDI` when the incoming flit type is `10`, then holds `reqA` in `RP` until an allocation grant arrives.

`GRO` raises the downstream request. Once `ackO` is high, `WAO` lowers that request and waits for the acknowledgement to fall. Reading begins in `WAIT3` and continues in `SDO` until the registered output flit type equals `10`. The controller then returns to `WRI`. All outputs not listed as high in the diagram are low.

The controller has no explicit reset input. This sequence describes operation after entry into `WRI`; it does not establish deterministic hardware startup. Although `full` and `empty` are controller inputs, they do not affect its state transitions. The datapath separately guards writes with `!full` and reads with `!empty`.

### Illustrative handshake timing

![Illustrative timing, not a simulation waveform](docs/diagrams/additions/handshake-timing.png)

This drawing summarizes signal levels across symbolic state intervals. It is not a waveform captured from simulation and must not be used to infer latency, cycle counts, or setup/hold timing. `RDI`, `RP`, `GRO`, `WAO`, and `SDO` can persist for multiple cycles. External input transitions are shown schematically at state boundaries; the corresponding condition must be present for the controller to advance at a rising clock edge.

The upstream `reqI/ackI` exchange admits a packet. `reqA/ackA` obtains an output allocation, which is retained during forwarding by keeping `reqA` asserted. The downstream `reqO/ackO` exchange finishes before the FIFO starts draining: `ackO` is not a per-flit valid signal. Packet contents must be interpreted using the protocol state and flit identifiers rather than by treating every visible data value as a new flit.

## Example Traffic and Verification

### Concurrent traffic scenario

`NoC_TB.v` starts traffic mode `01` at node 8, mode `10` at node 6, and mode `11` at node 7 on consecutive stimulus steps. Their destination IDs are defined by the corresponding headers in `Node.v`. With `SIZE = 16`, router coordinates are `x = ID % 4` and `y = ID / 4`.

![Expected paths of the three test packets](docs/diagrams/additions/traffic-paths.png)

| Packet | Expected router sequence | Output-port sequence |
| --- | --- | --- |
| 8 → 1 | 8 → 9 → 5 → 1 | East → North → North → Local |
| 6 → 4 | 6 → 5 → 4 | West → West → Local |
| 7 → 5 | 7 → 6 → 5 | West → West → Local |

The paths follow the X coordinate first and the Y coordinate second. Sharing a router does not necessarily imply output contention. At router 6, the packet injected locally for node 4 and the packet arriving from the East for node 5 both need the West output. If both are eligible when allocation occurs, Local has priority over East. An already active transfer is intended to retain its grant through `BusyChecker`; exact ordering depends on arrival and allocation timing.

### Expected packet contents

Each value below is an 18-bit flit written as five hexadecimal digits. The type bits are included. These are expected values derived from the literals in `Node.v`, not measured receiver outputs.

| Source → destination | Header (`01`) | Body 1 (`00`) | Body 2 (`00`) | Tail (`10`) |
| --- | --- | --- | --- | --- |
| 8 → 1 | `18'h12281` | `18'h0A236` | `18'h0365A` | `18'h2F2AF` |
| 6 → 4 | `18'h18264` | `18'h0AF74` | `18'h0705E` | `18'h2928B` |
| 7 → 5 | `18'h10275` | `18'h0B3F7` | `18'h0B7DA` | `18'h2F3EF` |

### Verification status and observation points

The paths and packet contents above were checked against the source. No new HDL simulation or synthesis run accompanies these additions. The supplied testbench is stimulus-driven and does not contain a self-checking packet scoreboard. Neither the diagrams nor the expected values establish successful delivery.

For a simulator run, inspect `data_out_LS` and `reqOut_LS` on the destination router, together with its local acknowledgement `ackOut_LS`. Under `NoC_TB.NoC_UT`, the three destination router instances are:

| Destination | Relative router instance path |
| --- | --- |
| 1 | `GENERATING_NODE_ROUTERS_IN_ROWS[0].GENERATING_NODE_ROUTERS_IN_COLUMNS[1].node_routers.router` |
| 4 | `GENERATING_NODE_ROUTERS_IN_ROWS[1].GENERATING_NODE_ROUTERS_IN_COLUMNS[0].node_routers.router` |
| 5 | `GENERATING_NODE_ROUTERS_IN_ROWS[1].GENERATING_NODE_ROUTERS_IN_COLUMNS[1].node_routers.router` |

Simulator hierarchy notation may vary. For a valid packet window, verify the header destination, the exact ordered flit values, and a single tail. Check that each packet is delivered once to its intended local interface. Capture an English-labeled waveform from that run before claiming a simulation pass. Data outside a packet window can be stale, unknown, or high impedance and should not be counted as additional traffic.

