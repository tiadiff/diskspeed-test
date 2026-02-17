using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace SSDSpeedTestWin.Models
{
    public enum TestStatus
    {
        Idle,
        Testing,
        Success,
        Error
    }

    public class VolumeTestState : INotifyPropertyChanged
    {
        public string DriveName { get; set; } = string.Empty;
        public string RootPath { get; set; } = string.Empty;
        public bool IsReady { get; set; }

        private TestStatus _status = TestStatus.Idle;
        public TestStatus Status
        {
            get => _status;
            set { _status = value; OnPropertyChanged(); }
        }

        private double _writeSpeed;
        public double WriteSpeed
        {
            get => _writeSpeed;
            set { _writeSpeed = value; OnPropertyChanged(); }
        }

        private double _readSpeed;
        public double ReadSpeed
        {
            get => _readSpeed;
            set { _readSpeed = value; OnPropertyChanged(); }
        }

        private double _progress;
        public double Progress
        {
            get => _progress;
            set { _progress = value; OnPropertyChanged(); }
        }

        private string? _errorText;
        public string? ErrorText
        {
            get => _errorText;
            set { _errorText = value; OnPropertyChanged(); }
        }

        public event PropertyChangedEventHandler? PropertyChanged;
        protected void OnPropertyChanged([CallerMemberName] string? name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }
    }
}
