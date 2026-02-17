using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using SSDSpeedTestWin.Models;

namespace SSDSpeedTestWin.Services
{
    public class DiskSpeedTester
    {
        public ObservableCollection<VolumeTestState> VolumeStates { get; } = new ObservableCollection<VolumeTestState>();
        private const long TestFileSize = 1024L * 1024L * 1024L * 2; // 2GB

        public void RefreshVolumes()
        {
            try
            {
                var drives = DriveInfo.GetDrives().Where(d => d.IsReady);
                
                var currentUris = drives.Select(d => d.RootDirectory.FullName).ToList();
                
                // Remove missing
                var toRemove = VolumeStates.Where(s => !currentUris.Contains(s.RootPath)).ToList();
                foreach (var r in toRemove) VolumeStates.Remove(r);

                // Add new
                foreach (var drive in drives)
                {
                    if (!VolumeStates.Any(s => s.RootPath == drive.RootDirectory.FullName))
                    {
                        VolumeStates.Add(new VolumeTestState
                        {
                            DriveName = string.IsNullOrEmpty(drive.VolumeLabel) ? $"Local Disk ({drive.Name.TrimEnd('\\')})" : drive.VolumeLabel,
                            RootPath = drive.RootDirectory.FullName,
                            IsReady = true
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"RefreshVolumes error: {ex.Message}");
            }
        }

        public async Task RunTest(VolumeTestState state)
        {
            if (state.Status == TestStatus.Testing) return;

            state.Status = TestStatus.Testing;
            state.WriteSpeed = 0;
            state.ReadSpeed = 0;
            state.Progress = 0;
            state.ErrorText = null;

            await Task.Run(() =>
            {
                string fileName = $".speedtest_temp_{Guid.NewGuid()}";
                string filePath = Path.Combine(state.RootPath, fileName);

                // Fallback to Temp if root is not writable
                try
                {
                    using (var fs = File.Create(filePath, 1, FileOptions.DeleteOnClose)) { }
                }
                catch
                {
                    filePath = Path.Combine(Path.GetTempPath(), fileName);
                }

                try
                {
                    // --- WRITE TEST ---
                    PerformWriteTest(filePath, state);

                    // --- READ TEST ---
                    PerformReadTest(filePath, state);

                    // Cleanup
                    if (File.Exists(filePath)) File.Delete(filePath);

                    App.Current.Dispatcher.Invoke(() =>
                    {
                        state.Status = TestStatus.Success;
                        state.Progress = 1.0;
                    });
                }
                catch (Exception ex)
                {
                    App.Current.Dispatcher.Invoke(() =>
                    {
                        state.Status = TestStatus.Error;
                        state.ErrorText = ex.Message;
                        if (File.Exists(filePath)) File.Delete(filePath);
                    });
                }
            });
        }

        private void PerformWriteTest(string path, VolumeTestState state)
        {
            const int chunkSize = 1024 * 1024 * 64; // 64MB
            byte[] data = new byte[chunkSize];
            new Random().NextBytes(data);
            int iterations = (int)(TestFileSize / chunkSize);

            Stopwatch sw = Stopwatch.StartNew();

            using (FileStream fs = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None, chunkSize, FileOptions.WriteThrough | (FileOptions)0x20000000)) // 0x20000000 is NoBuffering
            {
                for (int i = 0; i < iterations; i++)
                {
                    fs.Write(data, 0, chunkSize);
                    double p = (double)i / (iterations * 2);
                    App.Current.Dispatcher.Invoke(() => state.Progress = p);
                }
                fs.Flush(true);
            }

            sw.Stop();
            double seconds = sw.Elapsed.TotalSeconds;
            double mbps = (TestFileSize / (1024.0 * 1024.0)) / seconds;

            App.Current.Dispatcher.Invoke(() => state.WriteSpeed = mbps);
        }

        private void PerformReadTest(string path, VolumeTestState state)
        {
            const int chunkSize = 1024 * 1024 * 64; // 64MB
            byte[] buffer = new byte[chunkSize];
            
            Stopwatch sw = Stopwatch.StartNew();

            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.None, chunkSize, (FileOptions)0x20000000)) // NoBuffering
            {
                long totalRead = 0;
                while (totalRead < TestFileSize)
                {
                    int r = fs.Read(buffer, 0, chunkSize);
                    if (r == 0) break;
                    totalRead += r;

                    double p = 0.5 + ((double)totalRead / (TestFileSize * 2));
                    App.Current.Dispatcher.Invoke(() => state.Progress = p);
                }
            }

            sw.Stop();
            double seconds = sw.Elapsed.TotalSeconds;
            double mbps = (TestFileSize / (1024.0 * 1024.0)) / seconds;

            App.Current.Dispatcher.Invoke(() => state.ReadSpeed = mbps);
        }
    }
}
