using System.Windows;

namespace SSDSpeedTestWin
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            this.DispatcherUnhandledException += (s, ex) =>
            {
                MessageBox.Show($"Critical Error: {ex.Exception.Message}\n\n{ex.Exception.StackTrace}", "SSD Speed Test - Error", MessageBoxButton.OK, MessageBoxImage.Error);
                // We keep it unhandled if it's too severe, but usually we want to see the error.
                // ex.Handled = true; 
            };
            base.OnStartup(e);
        }
    }
}
