# Pontaj - aplicatie iOS de pontaj pe proiect

Aplicatie nativa SwiftUI pentru iPhone. Alegi un proiect, apesi **Start**, iar
cand termini apesi **Stop**. Aplicatia ia automat data si ora de la telefon si
salveaza fiecare pontaj. Totul este stocat **local pe telefon** (fisiere JSON),
fara server si fara cont.

## Functii

- Buton **Start** / **Pauză** / **Reluare** / **Stop**. Pauza nu se contorizează în durata pontajului.
- **Tarif pe oră** per proiect (opțional) → total **facturabil** în rezumat și CSV.
- **Editare proiect**: apasă pe un proiect din listă pentru nume și tarif.
- **Tag-uri rapide** la descriere: Birou, Teren, Deplasare, etc.
- **Swipe stânga → Șterge** pe pontaje (sau ține apăsat pentru meniu).
- **Backup / Restore** JSON din ecranul Proiecte.
- **Notificare** dacă pontajul rămâne pornit peste 12 ore.
- **Feedback haptic** la Start / Stop / Pauză.
- Sesiunea activă (inclusiv pauza) se salvează: poți închide aplicația și continua la redeschidere.
- **Descriere "ce am facut"**: cand apesi Stop, poti scrie ce ai lucrat.
- **Editare / adaugare manuala**: apesi pe un pontaj din lista ca sa-i modifici
  proiectul, ora de start/stop si descrierea (sau sa-l stergi). Cu butonul "+"
  poti adauga manual un pontaj pe trecut (cand ai uitat sa pornesti cronometrul).
- **Grupare pe zile**: pontajele sunt grupate pe zi, cu subtotal pe fiecare zi.
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
   │  ├─ EntryEditView.swift  # editare / adaugare manuala pontaj
   │  ├─ ProjectEditView.swift # editare proiect (nume, tarif)
   │  ├─ FilterBar.swift      # filtrare dupa proiect si perioada
   │  ├─ SummaryView.swift    # rezumat normal/suplimentar + facturabil
   │  ├─ TimerCard.swift      # cronometru izolat (performanta)
   │  └─ ShareSheet.swift     # partajare fisiere exportate
   ├─ Utils/
   │  ├─ Formatters.swift     # formatare data/ora/durata/bani
   │  ├─ Haptics.swift        # feedback la butoane
   │  └─ NotificationManager.swift # memento pontaj uitat
   └─ Assets.xcassets/        # iconita si culoare accent
```

## Cum o compilezi si o rulezi (necesita un Mac)

> O aplicatie iOS nativa se poate construi doar pe un Mac cu Xcode. Codul de aici
> este complet; trebuie doar deschis pe un Mac.

1. Clonează repo-ul pe Mac: `git clone https://github.com/frodoishere/Pontaj.git`
2. Instalează **Xcode 16** sau mai nou (din App Store).
3. Deschide `Pontaj/Pontaj.xcodeproj`.
4. Selectează un simulator de iPhone și apasă **Run** (▶).

Pentru actualizări ulterioare: `git pull` în folderul proiectului.

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
