import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RadioView()
                .tabItem {
                    Image(systemName: "radio.fill")
                    Text("La Radio")
                }

            NoticiasView()
                .tabItem {
                    Image(systemName: "newspaper.fill")
                    Text("Noticias")
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
