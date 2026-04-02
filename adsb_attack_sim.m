% =========================================================================
% EE 674: Communication Protocols - Course Project
% Author: Steven Iden
% Project: Securing ADS-B Against Spoofing Attacks
% 
% Phase 2: Attack Simulation (Ghost Aircraft Injection)
% Description: This script simulates a legitimate aircraft (Alice) and an 
% attacker (Eve). Eve is stationary on the ground but injects fake ADS-B 
% packets claiming to be a moving "Ghost Aircraft". The script calculates 
% the Received Signal Strength (RSS) based on TRUE physical locations, 
% revealing the anomaly in Eve's spoofed data.
% =========================================================================

clear; clc; close all;

%% 1. Simulation Parameters
disp('Initializing Phase 2: ADS-B Attack Simulation...');

t_total = 120;           % Total simulation time in seconds
dt = 1;                  % 1 packet per second
time_vector = 0:dt:t_total;

% Ground Station (Receiver) Location
gs_lat = 47.9253; gs_lon = -97.0329; gs_alt = 0; 

% RF Communication Parameters
freq_MHz = 1090;         % ADS-B Frequency
tx_power_dBm = 50;       % Standard transmit power (~100W)
noise_floor = -100;      % Receiver noise floor (dBm)

%% 2. Node Parameters

% ALICE (Legitimate Aircraft)
alice_id = 'AAL123';
alice_start_lat = 47.7500; alice_start_lon = -97.5000; alice_alt = 30000;
alice_vLat = 0.0015; alice_vLon = 0.0020; % Moving North-East

% EVE (Attacker - Stationary on the ground)
eve_true_lat = 47.9000; eve_true_lon = -97.1000; eve_true_alt = 0; 

% EVE'S SPOOFED GHOST AIRCRAFT (Fake Trajectory)
ghost_id = 'EVE666';
ghost_start_lat = 47.9253; ghost_start_lon = -97.4000; ghost_alt = 15000;
ghost_vLat = 0.0000; ghost_vLon = 0.0030; % Claiming to fly directly East

%% 3. Generate Packets (The RF Environment)
num_packets = length(time_vector);
alice_packets = struct('Timestamp', cell(1,num_packets), 'ID', cell(1,num_packets), ...
    'ClaimedLat', cell(1,num_packets), 'ClaimedLon', cell(1,num_packets), ...
    'ClaimedAlt', cell(1,num_packets), 'ClaimedDist', cell(1,num_packets), 'RSS_dBm', cell(1,num_packets));
eve_packets = alice_packets; % Copy structure

for i = 1:num_packets
    t = time_vector(i);
    
    % ---------------------------------------------------------
    % ALICE: Legitimate Transmission
    % ---------------------------------------------------------
    a_lat = alice_start_lat + (alice_vLat * t);
    a_lon = alice_start_lon + (alice_vLon * t);
    
    % True Distance calculation for RF path loss
    a_dist_km = sqrt(((a_lat - gs_lat)*111)^2 + ((a_lon - gs_lon)*85)^2 + (alice_alt*0.0003048)^2);
    a_fspl = 20*log10(a_dist_km) + 20*log10(freq_MHz) + 32.44;
    
    alice_packets(i).Timestamp = t;
    alice_packets(i).ID = alice_id;
    alice_packets(i).ClaimedLat = a_lat;     % Alice tells the truth
    alice_packets(i).ClaimedLon = a_lon;
    alice_packets(i).ClaimedAlt = alice_alt;
    alice_packets(i).ClaimedDist = a_dist_km;
    alice_packets(i).RSS_dBm = tx_power_dBm - a_fspl;

    % ---------------------------------------------------------
    % EVE: Malicious Spoofing Transmission
    % ---------------------------------------------------------
    % The fake coordinates Eve puts INSIDE the data packet
    fake_lat = ghost_start_lat + (ghost_vLat * t);
    fake_lon = ghost_start_lon + (ghost_vLon * t);
    fake_dist_km = sqrt(((fake_lat - gs_lat)*111)^2 + ((fake_lon - gs_lon)*85)^2 + (ghost_alt*0.0003048)^2);
    
    % The TRUE distance the RF wave travels (from Eve's parked van)
    eve_true_dist_km = sqrt(((eve_true_lat - gs_lat)*111)^2 + ((eve_true_lon - gs_lon)*85)^2 + 0);
    eve_fspl = 20*log10(eve_true_dist_km) + 20*log10(freq_MHz) + 32.44;
    
    eve_packets(i).Timestamp = t;
    eve_packets(i).ID = ghost_id;
    eve_packets(i).ClaimedLat = fake_lat;      % Eve lies about position
    eve_packets(i).ClaimedLon = fake_lon;
    eve_packets(i).ClaimedAlt = ghost_alt;
    eve_packets(i).ClaimedDist = fake_dist_km; % Eve claims a changing distance
    % BUT the physical signal strength depends on her TRUE static distance!
    eve_packets(i).RSS_dBm = tx_power_dBm - eve_fspl; 
end

disp('Phase 2 Complete: Attack traffic generated and merged with baseline.');

%% 4. Data Visualization (For Progress Report)

% Figure 1: Spatial Map (What the ATC Screen Sees vs Reality)
figure('Name', 'ATC Map Under Attack', 'NumberTitle', 'off');
plot([alice_packets.ClaimedLon], [alice_packets.ClaimedLat], 'b-', 'LineWidth', 2); hold on;
plot([eve_packets.ClaimedLon], [eve_packets.ClaimedLat], 'r--', 'LineWidth', 2); 
plot(gs_lon, gs_lat, 'k^', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); % Ground Station
plot(eve_true_lon, eve_true_lat, 'rs', 'MarkerSize', 10, 'MarkerFaceColor', 'r'); % Eve's TRUE Location
grid on;
title('Airspace Under Injection Attack');
xlabel('Longitude'); ylabel('Latitude');
legend('Alice (True Path)', 'Ghost Aircraft (Spoofed Path)', 'ATC Tower', 'Attacker SDR Location', 'Location', 'best');
set(gca, 'FontSize', 12);

% Figure 2: The Physical Anomaly (RSS vs Claimed Distance)
% This graph proves why the spoofing is detectable.
figure('Name', 'Physical Anomaly Detection', 'NumberTitle', 'off');
plot([alice_packets.ClaimedDist], [alice_packets.RSS_dBm], 'b-', 'LineWidth', 2); hold on;
plot([eve_packets.ClaimedDist], [eve_packets.RSS_dBm], 'r--', 'LineWidth', 2);
grid on;
title('Received Signal Strength vs. Claimed Distance');
xlabel('Aircraft Claimed Distance to Tower (km)');
ylabel('Actual Received Power (dBm)');
legend('Alice (Follows Path Loss Physics)', 'Eve''s Ghost (Violates Physics)', 'Location', 'best');
set(gca, 'FontSize', 12);