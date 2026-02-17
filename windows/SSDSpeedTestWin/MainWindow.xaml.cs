using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Media;
using SSDSpeedTestWin.Models;
using SSDSpeedTestWin.Services;

namespace SSDSpeedTestWin
{
    public partial class MainWindow : Window
    {
        private readonly DiskSpeedTester _tester = new DiskSpeedTester();

        public MainWindow()
        {
            InitializeComponent();
            DataContext = _tester;
            _tester.RefreshVolumes();
        }

        private void Window_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ChangedButton == MouseButton.Left && e.LeftButton == MouseButtonState.Pressed) 
                DragMove();
        }

        private void Close_Click(object sender, RoutedEventArgs e)
        {
            Application.Current.Shutdown();
        }

        private void Refresh_Click(object sender, RoutedEventArgs e)
        {
            _tester.RefreshVolumes();
        }

        private async void RunTest_Click(object sender, RoutedEventArgs e)
        {
            if (sender is FrameworkElement el && el.DataContext is VolumeTestState state)
            {
                await _tester.RunTest(state);
            }
        }
    }

    public class StatusToColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is TestStatus status)
            {
                switch (status)
                {
                    case TestStatus.Idle: return new SolidColorBrush(Color.FromRgb(234, 179, 8)); // Yellow
                    case TestStatus.Testing: return new SolidColorBrush(Color.FromRgb(249, 115, 22)); // Orange
                    case TestStatus.Success: return new SolidColorBrush(Color.FromRgb(34, 197, 94)); // Green
                    case TestStatus.Error: return new SolidColorBrush(Color.FromRgb(239, 68, 68)); // Red
                }
            }
            return Brushes.Gray;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) => throw new NotImplementedException();
    }
}