import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import io
import numpy as np

def show_user_detail(user_id: str, supabase):
    st.markdown(f"### User Details: `{user_id}`")
    
    # 1. Fetch Data
    user_profile = supabase.table("user_profiles").select("*").eq("id", user_id).execute()
    morning = supabase.table("morning_checkins").select("*").eq("user_id", user_id).order("date").execute()
    evening = supabase.table("evening_checkins").select("*").eq("user_id", user_id).order("date").execute()
    episodes = supabase.table("episodes").select("*").eq("user_id", user_id).order("date").execute()
    measurements = supabase.table("measurements").select("*").eq("user_id", user_id).order("recorded_at").execute()
    
    profile_data = user_profile.data[0] if user_profile.data else {}
    morning_df = pd.DataFrame(morning.data)
    evening_df = pd.DataFrame(evening.data)
    episodes_df = pd.DataFrame(episodes.data)
    measurements_df = pd.DataFrame(measurements.data)
    
    # --- Profile Section ---
    with st.expander("Patient Profile", expanded=False):
        c1, c2, c3 = st.columns(3)
        c1.write(f"**User ID:** `{user_id}`")
        c1.write(f"**Age:** {profile_data.get('age', 'N/A')}")
        c1.write(f"**Gender:** {profile_data.get('gender', 'N/A')}")
        
        c2.write(f"**Study Code:** {profile_data.get('research_study_code', 'N/A')}")
        c2.write(f"**HADS Anxiety:** {profile_data.get('hads_anxiety_score', 'N/A')}")
        c2.write(f"**HADS Depression:** {profile_data.get('hads_depression_score', 'N/A')}")
        
        c3.write(f"**Comorbidities:** {', '.join(profile_data.get('comorbidities', []) or [])}")
        c3.write(f"**Medications:** {profile_data.get('medications', 'N/A')}")

        st.divider()
        st.markdown("**Export Patient Data**")
        b1, b2, b3, b4 = st.columns(4)
        if not morning_df.empty:
            b1.download_button("Morning Checkins CSV", morning_df.to_csv(index=False), f"{user_id}_morning.csv")
        if not evening_df.empty:
            b2.download_button("Evening Checkins CSV", evening_df.to_csv(index=False), f"{user_id}_evening.csv")
        if not episodes_df.empty:
            b3.download_button("Episodes CSV", episodes_df.to_csv(index=False), f"{user_id}_episodes.csv")
        if not measurements_df.empty:
            b4.download_button("Measurements CSV", measurements_df.to_csv(index=False), f"{user_id}_measurements.csv")


    # --- Charts Comparisons ---
    st.markdown("#### Symptom vs. Physiology")
    
    # Pre-process Data for Plotting
    # We need a unified date axis.
    
    # Available Symptoms
    symptom_options = {} # {Label: (df, column_name)}
    
    if not morning_df.empty:
        morning_df['date'] = pd.to_datetime(morning_df['date'])
        # Add numeric cols
        for col in ['fatigue', 'dizziness', 'tachycardia']:
            if col in morning_df.columns:
                symptom_options[f"Morning {col.replace('_', ' ').title()}"] = (morning_df, col)
                
    if not evening_df.empty:
        evening_df['date'] = pd.to_datetime(evening_df['date'])
        for col in ['fatigue_score']:
             if col in evening_df.columns:
                symptom_options[f"Evening {col.replace('_', ' ').title()}"] = (evening_df, col)

    # Physio Options
    physio_options = {}
    if not measurements_df.empty:
        measurements_df['recorded_at'] = pd.to_datetime(measurements_df['recorded_at'])
        measurements_df['date'] = measurements_df['recorded_at'].dt.date
        # Group by date for easier comparison with checkins (which are Daily)
        # Or keep as high-res. Let's keep high res but maybe smoothed?
        # For comparison with daily checkins, daily average might be best visual.
        daily_physio = measurements_df.groupby('date').agg({'heart_rate': 'mean'}).reset_index()
        daily_physio['date'] = pd.to_datetime(daily_physio['date'])
        
        physio_options["Heart Rate (Daily Avg)"] = (daily_physio, 'heart_rate')


    # Controls
    col_sel1, col_sel2 = st.columns(2)
    selected_symptom = col_sel1.selectbox("Select Symptom", options=list(symptom_options.keys()))
    selected_physio = col_sel2.selectbox("Select Physiological Metric", options=list(physio_options.keys()) + ["None"])

    # Build Chart
    if selected_symptom:
        sym_df, sym_col = symptom_options[selected_symptom]
        
        fig = make_subplots(specs=[[{"secondary_y": True}]])
        
        # Add Symptom Trace
        fig.add_trace(
            go.Scatter(x=sym_df['date'], y=sym_df[sym_col], name=selected_symptom, mode='lines+markers'),
            secondary_y=False
        )
        
        # Add Physio Trace
        if selected_physio and selected_physio != "None":
            phys_df, phys_col = physio_options[selected_physio]
            fig.add_trace(
                go.Scatter(x=phys_df['date'], y=phys_df[phys_col], name=selected_physio, mode='lines+markers', line=dict(dash='dot')),
                secondary_y=True
            )
            fig.update_yaxes(title_text=selected_physio, secondary_y=True)

        fig.update_layout(title_text=f"{selected_symptom} vs {selected_physio if selected_physio else ''}")
        fig.update_xaxes(title_text="Date")
        fig.update_yaxes(title_text="Symptom Level (0-3)", secondary_y=False)
        
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No symptom data available to plot.")

    # --- Episodes Timeline ---
    st.markdown("#### Episodes Timeline")
    if not episodes_df.empty:
         if 'created_at' in episodes_df.columns:
             episodes_df['Timestamp'] = pd.to_datetime(episodes_df['created_at'])
             fig_ep = px.scatter(episodes_df, x='Timestamp', y=[1]*len(episodes_df), title="Episode Occurrences", height=200)
             fig_ep.update_yaxes(visible=False, showticklabels=False)
             st.plotly_chart(fig_ep, use_container_width=True)
    else:
        st.info("No episodes recorded.")

    # --- Raw Data Tables ---
    with st.expander("View Raw Data"):
        tab1, tab2, tab3 = st.tabs(["Check-ins", "Episodes", "Measurements"])
        with tab1:
            st.write("Morning")
            st.dataframe(morning_df)
            st.write("Evening")
            st.dataframe(evening_df)
        with tab2:
            st.dataframe(episodes_df)
        with tab3:
            st.dataframe(measurements_df)

    # --- Raw Signal & Peak Analysis ---
    st.markdown("#### Signal Analysis")
    
    if measurements_df.empty or 'raw_file_path' not in measurements_df.columns:
        st.info("No signal data found for this user.")
    else:
        # Filter for valid file paths
        valid_measurements = measurements_df.dropna(subset=['raw_file_path'])
        valid_measurements = valid_measurements[valid_measurements['raw_file_path'].astype(str).str.strip() != ""]
        
        if valid_measurements.empty:
            st.info("No valid signal data paths found for this user.")
        else:
            # Let user select measurement
            measurement_options = valid_measurements.apply(
                lambda row: f"{pd.to_datetime(row['recorded_at']).strftime('%Y-%m-%d %H:%M:%S') if pd.notnull(row['recorded_at']) else 'Unknown'} - {row.get('source', 'Unknown')} ({str(row.get('measurement_id', ''))[:8]})", axis=1
            ).tolist()
            
            selected_option = st.selectbox("Select Measurement for Signal Analysis", options=measurement_options)
            
            selected_idx = measurement_options.index(selected_option)
            selected_row = valid_measurements.iloc[selected_idx]
            file_path = str(selected_row['raw_file_path']).strip()
            user_id = str(selected_row['user_id']).strip()
            measurement_id = str(selected_row['measurement_id']).strip()
            
            # Auto-correct the file path if it's just the user_id or measurement_id
            if '/' not in file_path:
                if file_path == user_id:
                    file_path = f"{user_id}/{measurement_id}.parquet"
                else:
                    file_path = f"{user_id}/{file_path}"
            if not file_path.endswith('.parquet') and not file_path.endswith('.csv') and not file_path.endswith('.json'):
                file_path = f"{file_path}.parquet"
            
            # Also get the peak file path from the db, fallback to raw logic if missing
            peak_path = selected_row.get('peaks_file_path')
            if pd.isna(peak_path) or not str(peak_path).strip():
                peak_path = file_path.replace('.parquet', '_peaks.parquet')
            else:
                peak_path = str(peak_path).strip()
                if '/' not in peak_path:
                    if peak_path == user_id:
                        peak_path = f"{user_id}/{measurement_id}_peaks.parquet"
                    else:
                        peak_path = f"{user_id}/{peak_path}"
                if not peak_path.endswith('.parquet'):
                    peak_path = f"{peak_path}_peaks.parquet" if not peak_path.endswith('_peaks') else f"{peak_path}.parquet"
            
            with st.spinner(f"Fetching signal data from {file_path}..."):
                try:
                    raw_res = supabase.storage.from_("raw_uploads").download(file_path)
                    peak_res = supabase.storage.from_("peak_indices").download(peak_path)
                    
                    if file_path.endswith('.parquet'):
                        raw_df = pd.read_parquet(io.BytesIO(raw_res))
                        peaks_df = pd.read_parquet(io.BytesIO(peak_res))
                    else:
                        # Assume it's JSON and convert to parquet during data extraction
                        import json
                        try:
                            raw_df = pd.read_json(io.BytesIO(raw_res))
                            peaks_df = pd.read_json(io.BytesIO(peak_res))
                        except ValueError:
                            # In case it's a JSON array of dicts and read_json fails
                            raw_json = json.loads(raw_res.decode('utf-8'))
                            peak_json = json.loads(peak_res.decode('utf-8'))
                            raw_df = pd.DataFrame(raw_json)
                            peaks_df = pd.DataFrame(peak_json)
                            
                        # Convert to parquet during data extraction
                        raw_parquet = raw_df.to_parquet()
                        peaks_parquet = peaks_df.to_parquet()
                        
                        raw_df = pd.read_parquet(io.BytesIO(raw_parquet))
                        peaks_df = pd.read_parquet(io.BytesIO(peaks_parquet))
                    
                    # --- Plot 1: Raw Upload + Peaks Overlaid ---
                    # Filter out time columns to find valid signal channels
                    available_channels = [col for col in raw_df.columns if col.lower() not in ['time', 'timestamp', 'nseq']]
                    if not available_channels:
                        st.warning("No signal channels found. Using first column as fallback.")
                        available_channels = raw_df.columns.tolist()
                        
                    default_idx = 0
                    if 'A1' in available_channels:
                        default_idx = available_channels.index('A1')
                    elif 'signal' in available_channels:
                        default_idx = available_channels.index('signal')
                        
                    signal_col = st.selectbox("Select Signal Channel", options=available_channels, index=default_idx)
                    
                    peak_col = 'peak_index' if 'peak_index' in peaks_df.columns else peaks_df.columns[0]
                    peak_indices = peaks_df[peak_col].dropna().astype(int).values
                    
                    # Estimate sampling frequency
                    fs = 1000
                    if len(peak_indices) > 1:
                        med_diff = np.median(np.diff(peak_indices))
                        est_fs = int(round(med_diff / 100) * 100)
                        if 800 < est_fs < 1200: fs = 1000
                        elif 80 < est_fs < 120: fs = 100
                        elif 200 < est_fs < 300: fs = 250
                        
                    apply_recalc = st.checkbox("Recalculate Peaks (Fix Alignment)", value=False, help="Bypasses the corrupted database peaks and runs HeartPy locally on the raw signal to guarantee perfect mathematical alignment.")
                    
                    if apply_recalc:
                        with st.spinner("Recalculating perfect peak alignment locally..."):
                            import heartpy as hp
                            import scipy.signal as sg
                            
                            # Filter signal slightly for peak detection so HeartPy can find them easily
                            # (0.5 to 8.0 Hz is standard for removing baseline wander for peak detection)
                            sos_hp = sg.butter(4, [0.5, min(8.0, fs/2 - 1)], btype='bandpass', fs=fs, output='sos')
                            sig_for_hp = sg.sosfiltfilt(sos_hp, raw_df[signal_col].values)
                            
                            try:
                                wd, m = hp.process(sig_for_hp, sample_rate=fs, windowsize=0.75, report_time=False)
                                peak_indices = np.array(wd['peaklist'])
                                peaks_df = pd.DataFrame({peak_col: peak_indices})
                            except Exception as e:
                                st.warning(f"Local peak calculation failed: {e}. Falling back to database peaks.")
                    
                    apply_crop = False
                    if not peaks_df.empty:
                        apply_crop = st.checkbox("Apply 5s Crop Offset", value=True, help="Removes the first 5 seconds of data before filtering to prevent filter ringing.")
                        
                        # The peaks (whether from database or recalculated) are on the FULL uncropped signal!
                        # If we crop the first 5s of the signal for visualization, we must shift the peak indices
                        # backwards by 5s so they map to the correct samples in the cropped array.
                        if apply_crop:
                            peak_indices = peak_indices - int(5 * fs)
                            
                        # Make sure indices are within bounds of the array we are going to plot, and filter out negatives
                        expected_len = len(raw_df) - (int(5 * fs) if apply_crop else 0)
                        peak_indices = peak_indices[(peak_indices >= 0) & (peak_indices < expected_len)]
                        
                    signal_display_options = st.multiselect(
                        "Display Signals", 
                        options=["Raw Signal", "Filtered Signal"], 
                        default=["Raw Signal"], 
                        help="Select which traces to overlay on the graph. 'Filtered Signal' applies a bandpass and median filter."
                    )
                    
                    if apply_crop:
                        start_idx = 5 * fs
                    else:
                        start_idx = 0
                        
                    # Calculate time in milliseconds based on the index and the sampling frequency
                    index_array = pd.Series(raw_df.index)[start_idx:]
                    x_raw = (index_array / fs) * 1000
                        
                    y_raw = raw_df[signal_col].iloc[start_idx:].copy()
                    
                    if "Filtered Signal" in signal_display_options:
                        import scipy.signal as signal
                        # 1. Bandpass filter for PPG (0.5 to 8.0 Hz)
                        fLow = 0.5
                        fHigh = 8.0
                            
                        nyquist = fs / 2.0
                        if fHigh >= nyquist:
                            fHigh = nyquist * 0.95
                            
                        sos = signal.butter(4, [fLow, fHigh], btype='bandpass', fs=fs, output='sos')
                        filtered = signal.sosfiltfilt(sos, y_raw.values)
                        
                        # 2. Median filter: 15 ms window
                        med_win = int(round(0.015 * fs))
                        if med_win % 2 == 0:
                            med_win += 1
                        y_smooth = signal.medfilt(filtered, kernel_size=med_win)
                        
                        y_filtered = pd.Series(y_smooth, index=y_raw.index)
                    
                    fig_signal = go.Figure()
                    
                    # Add raw signal trace
                    if "Raw Signal" in signal_display_options:
                        fig_signal.add_trace(go.Scatter(
                            x=x_raw, 
                            y=y_raw,
                            mode='lines',
                            name='Raw Signal',
                            line=dict(color='#000000', width=1) # Black
                        ))

                    # Add filtered signal trace
                    if "Filtered Signal" in signal_display_options:
                        fig_signal.add_trace(go.Scatter(
                            x=x_raw, 
                            y=y_filtered,
                            mode='lines',
                            name='Filtered Signal',
                            line=dict(color='#2563EB', width=2) # Blue
                        ))
                    
                    # Set default zoom to show 15 seconds of data
                    zoom_samples = int(15 * fs)
                    initial_range = None
                    if len(x_raw) > zoom_samples:
                        initial_range = [x_raw.iloc[0], x_raw.iloc[zoom_samples]]
                    elif len(x_raw) > 0:
                        initial_range = [x_raw.iloc[0], x_raw.iloc[-1]]
                        
                    if not peaks_df.empty:
                        # Extract the exact x coordinates for the peaks
                        x_peaks = x_raw.iloc[peak_indices]
                        
                        # Determine which y-values the peaks should be plotted on
                        y_peaks_base = y_filtered if "Filtered Signal" in signal_display_options else y_raw
                        
                        # Add peaks as red dots
                        fig_signal.add_trace(go.Scatter(
                            x=x_peaks,
                            y=y_peaks_base.iloc[peak_indices], 
                            mode='markers',
                            name='Detected Peaks',
                            marker=dict(color='#EF4444', size=8, symbol='x')
                        ))
                    
                    title = "Raw Signal with Peak Detection" if not peaks_df.empty else "Raw Signal"
                    
                    fig_signal.update_layout(
                        title=title, 
                        xaxis_title="Time (ms)", 
                        yaxis_title="Amplitude (mV)",
                        xaxis=dict(
                            rangeslider=dict(visible=True),
                            range=initial_range
                        )
                    )
                    st.plotly_chart(fig_signal, use_container_width=True)
                    
                    # --- Plot 2: NN Intervals Variation ---
                    if not peaks_df.empty and len(peak_indices) > 1:
                        # Convert interval differences from samples to milliseconds
                        nn_intervals_ms = (np.diff(peak_indices) / fs) * 1000
                        nn_times = x_peaks.iloc[1:] if isinstance(x_peaks, pd.Series) else x_peaks[1:]
                        
                        fig_nn = go.Figure()
                        fig_nn.add_trace(go.Scatter(
                            x=nn_times, 
                            y=nn_intervals_ms,
                            mode='lines+markers',
                            name='NN Interval',
                            line=dict(color='#10B981')
                        ))
                        
                        fig_nn.update_layout(
                            title="NN Interval Variation (Heart Rate Variability)",
                            xaxis_title="Time (ms)",
                            yaxis_title="NN Interval (ms)"
                        )
                        st.plotly_chart(fig_nn, use_container_width=True)
                    else:
                        st.info("Not enough peaks detected to calculate NN intervals.")
                    
                except Exception as e:
                    import traceback
                    st.error(f"Error processing signal data: {e}")
                    st.code(traceback.format_exc())
                    st.info(f"Tried to load '{file_path}' from storage.")
