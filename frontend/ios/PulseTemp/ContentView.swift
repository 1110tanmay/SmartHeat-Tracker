import SwiftUI

struct ContentView: View {

  init() {
      let _ = WatchConnectivityManager.shared // ✅ Ensures WatchConnectivity is initialized on launch
  }


    var body: some View {
        TabView {
            SummaryView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Summary")
                }

            TrendsView()
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("Trends")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

