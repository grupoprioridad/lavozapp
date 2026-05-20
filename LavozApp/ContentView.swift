import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RadioView()
                .tabItem {
                    Image(systemName: "radio.fill")
                    Text("La Radio")
                }
            
            SocioLVPView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Socio LVP")
                }
        }
        .tint(Color.lvpRed)
    }
}
