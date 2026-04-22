% =========================================================================
% EE 674: Communication Protocols - Course Project
% Author: Steven Iden
% Project: Securing ADS-B Against Spoofing Attacks
% 
% Phase 3: The Security Wrapper Algorithm
% Description: This script generates a mixed, noisy RF environment containing
% both legitimate traffic (Alice) and spoofed traffic (Eve). It then passes 
% all traffic through the Security Wrapper algorithm. The wrapper compares 
% the theoretical change in RSS (based on claimed distance) against the 
% actual change in RSS. Packets violating physics are dropped.
% =========================================================================

clear; clc; close all;

%% 1. Generate the Mixed RF Environment (Alice + Eve)
disp('Initializing Phase 3: RF Environment Generation...');

t_total = 120; time_vector = 1:t_total;
gs_lat = 47.9253; gs_lon = -97.0329; freq_MHz = 1090; tx_power_dBm = 50;
noise_variance = 0.5; % Added realistic RF noise (dBm)

% Arrays to hold the raw traffic buffer
raw_buffer = [];

for t = time_vector
    % --- ALICE (Legitimate) ---
    a_lat = 47.7500 + (0.0015 * t); a_lon = -97.5000 + (0.0020 * t);
    a_dist = sqrt(((a_lat - gs_lat)*111)^2 + ((a_lon - gs_lon)*85)^2 + (30000*0.0003048)^2);
    a_rss = tx_power_dBm - (20*log10(a_dist) + 20*log10(freq_MHz) + 32.44) + (randn*noise_variance);
    
    % Package Alice (ID 1, True=1)
    raw_buffer = [raw_buffer; t, 1, a_lat, a_lon, a_dist, a_rss, 1]; 
    
    % --- EVE (Attacker/Ghost) ---
    e_lat = 47.9253 + (0.0000 * t); e_lon = -97.4000 + (0.0030 * t);
    e_claimed_dist = sqrt(((e_lat - gs_lat)*111)^2 + ((e_lon - gs_lon)*85)^2 + (15000*0.0003048)^2);
    e_true_dist = sqrt(((47.9000 - gs_lat)*111)^2 + ((-97.1000 - gs_lon)*85)^2); % Stationary Van
    e_rss = tx_power_dBm - (20*log10(e_true_dist) + 20*log10(freq_MHz) + 32.44) + (randn*noise_variance);
    
    % Package Eve (ID 2, True=0)
    raw_buffer = [raw_buffer; t, 2, e_lat, e_lon, e_claimed_dist, e_rss, 0];
end

% Shuffle buffer to simulate mixed packet arrival at the antenna
raw_buffer = raw_buffer(randperm(size(raw_buffer, 1)), :);
% Sort buffer chronologically by timestamp
raw_buffer = sortrows(raw_buffer, 1);

disp('Mixed traffic buffered. Sending to Security Wrapper...');

%% 2. The Security Wrapper Algorithm
% Initialize tracker for previous states: dictionary of [prev_dist, prev_rss]
state_tracker = containers.Map('KeyType', 'double', 'ValueType', 'any');
rss_error_threshold = 2.0; % Threshold in dBm to tolerate natural noise

% Output arrays
accepted_packets = [];
dropped_packets = [];
tp = 0; fp = 0; tn = 0; fn = 0; % Metrics

for i = 1:size(raw_buffer,1)
    pkt_t = raw_buffer(i,1); pkt_id = raw_buffer(i,2); 
    pkt_lat = raw_buffer(i,3); pkt_lon = raw_buffer(i,4);
    pkt_dist = raw_buffer(i,5); pkt_rss = raw_buffer(i,6);
    is_real = raw_buffer(i,7);
    
    if ~isKey(state_tracker, pkt_id)
        % First time seeing this aircraft. Accept it to establish a baseline.
        state_tracker(pkt_id) = [pkt_dist, pkt_rss];
        accepted_packets = [accepted_packets; raw_buffer(i,:)];
        if is_real == 1; tn = tn + 1; else; fn = fn + 1; end
        continue;
    end
    
    % Get previous data for this aircraft
    prev_state = state_tracker(pkt_id);
    prev_dist = prev_state(1); prev_rss = prev_state(2);
    
    % --- THE CORE ALGORITHM ---
    % 1. Calculate the theoretical expected change in RSS based on claimed movement
    expected_delta_rss = 20*log10(prev_dist) - 20*log10(pkt_dist);
    
    % 2. Calculate the actual physical change in RSS
    actual_delta_rss = pkt_rss - prev_rss;
    
    % 3. Calculate physics error
    physics_error = abs(actual_delta_rss - expected_delta_rss);
    
    % 4. Decision Gate
    if physics_error > rss_error_threshold
        % SPOOF DETECTED! Drop the packet.
        dropped_packets = [dropped_packets; raw_buffer(i,:)];
        if is_real == 0; tp = tp + 1; else; fp = fp + 1; end
    else
        % VALIDATED! Accept the packet and update tracker.
        state_tracker(pkt_id) = [pkt_dist, pkt_rss];
        accepted_packets = [accepted_packets; raw_buffer(i,:)];
        if is_real == 1; tn = tn + 1; else; fn = fn + 1; end
    end
end

%% 3. Evaluate Performance Metrics
detection_rate = (tp / (tp + fn)) * 100;
false_positive_rate = (fp / (fp + tn)) * 100;

fprintf('\n=== SECURITY WRAPPER PERFORMANCE ===\n');
fprintf('Total Packets Processed: %d\n', size(raw_buffer,1));
fprintf('Packets Accepted: %d\n', size(accepted_packets,1));
fprintf('Packets Dropped: %d\n', size(dropped_packets,1));
fprintf('------------------------------------\n');
fprintf('Detection Rate (DR): %.2f%%\n', detection_rate);
fprintf('False Positive Rate (FPR): %.2f%%\n', false_positive_rate);
fprintf('====================================\n');

%% 4. Visualize the Filtered Airspace (ATC Screen)

figure('Name', 'Filtered ATC Airspace', 'NumberTitle', 'off');
% Plot Alice (Accepted)
alice_accepted = accepted_packets(accepted_packets(:,2) == 1, :);
plot(alice_accepted(:,4), alice_accepted(:,3), 'b-', 'LineWidth', 2); hold on;

% Plot Eve (If any leaked through)
eve_accepted = accepted_packets(accepted_packets(:,2) == 2, :);
if ~isempty(eve_accepted)
    plot(eve_accepted(:,4), eve_accepted(:,3), 'r--', 'LineWidth', 2);
end

% Plot Ground Station
plot(gs_lon, gs_lat, 'k^', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
grid on;
title('ATC Display AFTER Security Wrapper');
xlabel('Longitude'); ylabel('Latitude');
if isempty(eve_accepted)
    legend('Alice (Verified Path)', 'ATC Tower', 'Location', 'best');
    text(-97.2, 47.88, 'Ghost Aircraft Eliminated!', 'Color', 'red', 'FontSize', 12, 'FontWeight', 'bold');
else
    legend('Alice (Verified Path)', 'Eve (Leaked Spoof)', 'ATC Tower', 'Location', 'best');
end
set(gca, 'FontSize', 12);