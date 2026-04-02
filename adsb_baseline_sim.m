% =========================================================================
% EE 674: Communication Protocols - Course Project
% Author: Steven Iden
% Project: Securing ADS-B Against Spoofing Attacks
% 
% Phase 1: Baseline Simulation (Legitimate Aircraft)
% Description: This script simulates the flight path of a legitimate 
% aircraft and generates the unencrypted baseline ADS-B telemetry packets 
% that are received by a Ground Station. It also calculates the Received 
% Signal Strength (RSS), which will be used in Phase 3 for verification.
% =========================================================================

clear; clc; close all;

%% 1. Simulation Parameters
disp('Initializing ADS-B Baseline Simulation...');

% Time Parameters
t_total = 120;           % Total simulation time in seconds
dt = 1;                  % ADS-B broadcasts 1 packet per second
time_vector = 0:dt:t_total;

% Ground Station (Receiver) Location (e.g., Grand Forks, ND)
gs_lat = 47.9253;
gs_lon = -97.0329;
gs_alt = 0;              % Ground level

% Legitimate Aircraft (Alice) Initial Parameters
aircraft_id = 'AAL123';  % Flight Callsign (Hex ID representation)
start_lat = 47.7500;     % Starting Latitude
start_lon = -97.5000;    % Starting Longitude
altitude_ft = 30000;     % Constant cruising altitude in feet

% Velocity vector (Degrees per second - simplified for simulation)
% Approx: 450 knots. 1 deg Lat = ~60 NM.
lat_velocity = 0.0015;   % Moving North
lon_velocity = 0.0020;   % Moving East

% RF Communication Parameters (1090 MHz)
freq_MHz = 1090;         % ADS-B operates on 1090 MHz
tx_power_dBm = 50;       % Standard ADS-B transmit power (~100 Watts)

%% 2. Generate Legitimate Trajectory & ADS-B Packets
% Preallocate a structure array to hold the ADS-B packets
num_packets = length(time_vector);
adsb_packets = struct('Timestamp', cell(1, num_packets), ...
                      'ID', cell(1, num_packets), ...
                      'Lat', cell(1, num_packets), ...
                      'Lon', cell(1, num_packets), ...
                      'Alt', cell(1, num_packets), ...
                      'True_Dist_km', cell(1, num_packets), ...
                      'RSS_dBm', cell(1, num_packets));

% Loop to simulate the aircraft flying and broadcasting over time
for i = 1:num_packets
    % Current Time
    t = time_vector(i);
    
    % Update Position (Kinematic equations)
    current_lat = start_lat + (lat_velocity * t);
    current_lon = start_lon + (lon_velocity * t);
    
    % Calculate exact physical distance from Aircraft to Ground Station (in km)
    % Note: Using a simplified Euclidean distance for small coordinate changes
    lat_diff_km = (current_lat - gs_lat) * 111; % 1 deg lat approx 111 km
    lon_diff_km = (current_lon - gs_lon) * 85;  % 1 deg lon approx 85 km at this latitude
    alt_diff_km = (altitude_ft * 0.0003048);    % Convert feet to km
    
    true_distance = sqrt(lat_diff_km^2 + lon_diff_km^2 + alt_diff_km^2);
    
    % Calculate Received Signal Strength (RSS) using Free Space Path Loss (FSPL)
    % FSPL(dB) = 20*log10(d) + 20*log10(f) + 32.44
    fspl_dB = 20*log10(true_distance) + 20*log10(freq_MHz) + 32.44;
    
    % Received Power = Transmit Power - Path Loss
    received_power_dBm = tx_power_dBm - fspl_dB;
    
    % Package the data into the simulated ADS-B cleartext packet
    adsb_packets(i).Timestamp = t;
    adsb_packets(i).ID = aircraft_id;
    adsb_packets(i).Lat = current_lat;
    adsb_packets(i).Lon = current_lon;
    adsb_packets(i).Alt = altitude_ft;
    adsb_packets(i).True_Dist_km = true_distance;
    adsb_packets(i).RSS_dBm = received_power_dBm;
end

disp('Simulation Complete. Legitimate ADS-B packets generated.');

%% 3. Extract Data for Plotting
% Convert struct data back to arrays for easy MATLAB plotting
plot_lat = [adsb_packets.Lat];
plot_lon = [adsb_packets.Lon];
plot_rss = [adsb_packets.RSS_dBm];
plot_time = [adsb_packets.Timestamp];

%% 4. Data Visualization (Figures for the Progress Report)

% Figure 1: Spatial Trajectory (Map View)
figure('Name', 'ADS-B Spatial Trajectory', 'NumberTitle', 'off');
plot(plot_lon, plot_lat, 'b-', 'LineWidth', 2);
hold on;
plot(gs_lon, gs_lat, 'k^', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); % Ground Station
plot(plot_lon(1), plot_lat(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g'); % Start
plot(plot_lon(end), plot_lat(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); % End
grid on;
title('Legitimate Aircraft Trajectory (Phase 1)');
xlabel('Longitude (Degrees)');
ylabel('Latitude (Degrees)');
legend('Flight Path', 'Ground Station (Receiver)', 'Start', 'End', 'Location', 'best');
set(gca, 'FontSize', 12); % Larger font for IEEE paper readability

% Figure 2: Received Signal Strength over Time
% As the aircraft gets closer to the ground station, RSS should increase.
figure('Name', 'Received Signal Strength (RSS)', 'NumberTitle', 'off');
plot(plot_time, plot_rss, 'g-', 'LineWidth', 2);
grid on;
title('Expected Signal Strength at Receiver');
xlabel('Time (Seconds)');
ylabel('Received Power (dBm)');
legend('Valid Signal (Alice)', 'Location', 'best');
set(gca, 'FontSize', 12);

% Print a sample packet to the command window to show what the "cleartext" looks like
fprintf('\n--- Sample ADS-B Packet at t=60s ---\n');
disp(adsb_packets(61));