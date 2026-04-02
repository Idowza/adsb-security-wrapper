# ADS-B Security Wrapper ✈️🛡️

**Course:** EE 674 - Communication Protocols (Spring 2026)  
**Instructor:** Dr. Ahmed Abdelhadi  
**Author:** Steven Iden  

## Overview
Automatic Dependent Surveillance-Broadcast (ADS-B) is critical aviation infrastructure, but it transmits unencrypted, unauthenticated telemetry data. This lack of security makes it highly vulnerable to "Ghost Aircraft" spoofing attacks via Software Defined Radios (SDRs).

This project implements a simulated, software-based Security Wrapper—a receiver-side detection algorithm designed to filter out malicious spoofed packets based on physical layer anomalies, without requiring hardware modifications to legacy aircraft.

## System Model
The simulation models an RF communication link with three distinct nodes:
* **Alice (Legitimate Aircraft):** Broadcasts valid ADS-B packets containing true kinematic trajectory data.
* **Eve (Attacker / Spoofer):** Injects malicious packets with false coordinates or ghost aircraft IDs.
* **Bob (Secure Ground Station):** Implements the Security Wrapper to filter data using physical layer consistency checks, specifically Received Signal Strength (RSS) against reported distance.

## Repository Structure
```text
├── simulations/
│   ├── adsb_baseline_sim.m   # Phase 1: Legitimate flight path and RSS generation
│   ├── adsb_attack_sim.m     # Phase 2: Spoofer injection (Pending)
│   └── adsb_wrapper_sim.m    # Phase 3: Defense algorithm (Pending)
├── reports/
│   ├── proposal/             # LaTeX source for the 1-pager and Quad Chart
│   ├── progress_report/      # LaTeX source for the April 3 report
│   └── final_report/         # LaTeX source for the May 11 IEEE paper
└── README.md
```

## Project Roadmap
- [x] Phase 1: Baseline Simulation. Generate valid ADS-B flight paths, calculating Free Space Path Loss (FSPL) and Expected Received Signal Strength (RSS).
- [ ] Phase 2: Attack Simulation. Introduce an adversary node injecting packets with mismatched physical characteristics.
- [ ] Phase 3: Defense Implementation. Build the wrapper logic to evaluate RSS discrepancies and discard invalid packets.
- [ ] Phase 4: Evaluation. Calculate False Positive Rate (FPR) and Detection Rate (DR).

## How to Run
1. Clone this repository to your local machine.
2. Open MATLAB.
3. Navigate to the `simulations/` directory.
4. Run `adsb_baseline_sim.m` to generate the baseline trajectory map and RSS verification graphs.
