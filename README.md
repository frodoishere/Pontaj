# Pontaj - aplicatie iOS de pontaj pe proiect

Aplicatie nativa SwiftUI pentru iPhone. Alegi un proiect, apesi **Start**, iar
cand termini apesi **Stop**. Aplicatia ia automat data si ora de la telefon si
salveaza fiecare pontaj. Totul este stocat **local pe telefon** (fisiere JSON),
fara server si fara cont.

## Functii

- Buton mare **Start** / **Stop**.
- Data si ora preluate automat de la telefon (`Date()`), in formatul local.
- Cronometru live cat timp pontajul este pornit (HH:MM:SS).
- Mai multe proiecte: le adaugi/stergi din ecranul **Proiecte** (iconita folder).
- **Descriere "ce am facut"**: cand apesi Stop, poti scrie ce ai lucrat. O poti
  edita oricand apasand pe un pontaj din lista (sau stergi pontajul tinand apasat).
- **Filtrare**: poti filtra pontajele dupa proiect si dupa perioada (Toate, Azi,
  Saptamana, Luna sau un interval de date ales). Totalul afisat se actualizeaza
  dupa filtru.
- **Rezumat + ore suplimentare**: un card arata, pentru pontajele filtrate, orele
  in **program normal** vs **ore suplimentare**, plus totalul pe fiecare proiect.
  Orele suplimentare se calculeaza pe zi: ce depaseste pragul zilnic (implicit
  **8:30**) intr-o zi este suplimentar. Pragul se schimba din ecranul Proiecte
  ("Program normal pe zi").
- **Export CSV**: butonul de share (sus-stanga) genereaza un fisier `.csv` cu
  pontajele din filtrul curent. Fisierul are 3 sectiuni:
  1. **Pontaje**: proiect, start, stop, durata (HH:MM:SS), ore (zecimal), descriere.
  2. **Rezumat pe zile**: data, total, normal, suplimentar - in **ore zecimale**.
  3. **Total** general: total, normal, suplimentar - in ore zecimale.
  Orele zecimale (ex: 8:30 -> 8.50, cu punct) permit calcule directe in Excel.
  Il poti trimite pe mail, salva in Fisiere, deschide in Excel etc.
- Istoric de pontaje cu durata fiecaruia si total per proiect.
- Sesiunea activa este salvata: daca inchizi aplicatia in timpul unui pontaj,
  cronometrul continua de unde a ramas la redeschidere.

## Structura proiectului

```
Pontaj/
├─ Pontaj.xcodeproj/          # proiectul Xcode
└─ Pontaj/
   ├─ PontajApp.swift         # punctul de intrare al aplicatiei
   ├─ ContentView.swift       # ecranul principal (Start/Stop, cronometru, lista)
   ├─ Models/
   │  ├─ Project.swift        # modelul de proiect
   │  └─ TimeEntry.swift      # modelul unui pontaj (start/stop/durata)
   ├─ Store/
   │  ├─ PontajStore.swift    # logica + salvarea locala
   │  └─ Stats.swift          # calcul rezumat (normal vs suplimentar, per proiect)
   ├─ Views/
   │  ├─ ProjectsView.swift   # adaugare/stergere proiecte
   │  ├─ EntryRow.swift       # randul unui pontaj din lista
   │  ├─ EntryNoteView.swift  # editare descriere "ce am facut"
   │  ├─ FilterBar.swift      # filtrare dupa proiect si perioada
   │  ├─ SummaryView.swift    # rezumat normal/suplimentar + per proiect
   │  └─ ShareSheet.swift     # partajare fisier CSV exportat
   ├─ Utils/
   │  └─ Formatters.swift     # formatare data/ora/durata
   └─ Assets.xcassets/        # iconita si culoare accent
```

## Cum o compilezi si o rulezi (necesita un Mac)

> O aplicatie iOS nativa se poate construi doar pe un Mac cu Xcode. Codul de aici
> este complet; trebuie doar deschis pe un Mac.

1. Copiaza folderul `Pontaj` pe un Mac.
2. Instaleaza **Xcode 16** sau mai nou (din App Store).
3. Deschide `Pontaj/Pontaj.xcodeproj` (dublu-click).
4. In Xcode, selecteaza un simulator de iPhone sus (ex: *iPhone 15*) si apasa
   butonul **Run** (▶) sau `Cmd + R`. Aplicatia porneste in simulator.

### Ca sa o pui pe iPhone-ul tau real

1. Conecteaza iPhone-ul prin cablu la Mac.
2. In Xcode, selecteaza tinta **Pontaj**, tab-ul **Signing & Capabilities**.
3. La **Team** alege contul tau Apple (un Apple ID gratuit este suficient pentru
   testare pe propriul telefon). Schimba si **Bundle Identifier** in ceva unic,
   ex: `com.numeletau.Pontaj`.
4. Sus, alege iPhone-ul tau ca destinatie si apasa **Run**.
5. Pe iPhone: *Setari → General → VPN si gestionare dispozitiv* → ai incredere in
   certificatul tau de developer (necesar prima data).

## Note

- Cerinta minima: iOS 16.0.
- Datele se pastreaza intre porniri si raman doar pe telefon. Daca dezinstalezi
  aplicatia, se sterg.
- Cu un Apple ID gratuit, aplicatia instalata pe telefon expira dupa ~7 zile si
  trebuie reinstalata din Xcode. Cu un cont platit de developer expira dupa 1 an.
