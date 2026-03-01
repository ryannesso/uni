# Správa z laboratórneho cvičenia č. 2
**Téma:** Optimalizácia funkcií pomocou genetického algoritmu (GA)
**Predmet:** Umelá inteligencia (UMINT)

---

## 1. Úloha: Optimalizácia Novej Schwefelovej funkcie (10-D)

### (1) Graf priebehu fitness pre viac behov
![Graf 10-D Schwefel](cesta_k_vasmu_obrazku_1.png)
*(Poznámka: Tu vložte screenshot grafu s 5 líniami pre nVar=10, popSize=50, maxGen=500).*

### (2) Použité nastavenia GA a popis experimentovania
V rámci úlohy sme testovali vplyv parametrov na hľadanie globálneho minima ($f_{min} \approx -7927.2$). 

**Zvolené parametre pre hlavné porovnanie:**
| Parameter | Hodnota |
| :--- | :--- |
| **nVar** | 10 |
| **popSize** | 10, 50 |
| **maxGen** | 100, 500 |
| **mutRate** | 0.02, 0.50 |
| **Space** | [-1000, 1000] |

**Krátky popis experimentovania:**
*   **Vplyv mutácie:** Pri `mutRate = 0.50` (50%) sme pozorovali tzv. "Černobyľský efekt". Algoritmus vykazoval chaotický priebeh, neustále ničil dobré riešenia a nedokázal presne konvergovať (fitness okolo -7209). Optimálna hodnota sa ukázala byť `0.02`.
*   **Vplyv populácie:** Pri malej populácii (`popSize = 10`) algoritmus stále dokáže nájsť minimum, ale konvergencia trvá dlhšie a je náchylnejšia na uviaznutie v lokálnych minimách.
*   **Čas hľadania:** Pri `maxGen = 100` algoritmus nestihol úplne "dosadnúť" na dno jamy (-7894), zatiaľ čo pri 500 generáciách dosiahol presnejší výsledok (-7925).

### (3) Výsledné riešenie (Najlepší jedinec)
*   **Najlepšie fitness:** -7925.5104
*   **Gény (Súradnice X):** Väčšina súradníc sa ustálila v blízkosti hodnoty **-864.72**.

### (4) Komentár k pozorovaným rozdielom medzi behmi
Jednotlivé behy (Run 1-5) vykazujú rozdiely v počiatočnej fáze kvôli náhodnej inicializácii. Niektoré línie klesajú strmšie, čo znamená, že počiatočná populácia bola bližšie k sľubnej oblasti. Všetky behy pri nízkej mutácii však nakoniec úspešne konvergujú k podobným hodnotám.

---

## 2. Bonus A: Schwefelova funkcia pre 100 premenných (100-D)

### (1) Graf priebehu fitness (100-D)
![Graf 100-D Schwefel](cesta_k_vasmu_obrazku_3.png)

### (2) Použité nastavenia
*   **nVar:** 100
*   **popSize:** 50, 100
*   **maxGen:** 1000, 1500
*   **mutRate:** 0.01
*   **Špeciálne:** Implementovaná funkcia `change` na elimináciu klonov a dynamická amplitúda mutácie.

### (3) Výsledné riešenie
*   **Najlepšie celkové fitness (100-D):** **-79261.0661**
*   *(Poznámka: Teoretické minimum pre 100-D je -79272).*

### (4) Komentár
V 100-rozmernom priestore je hľadanie extrémne náročné. Z grafov je zrejmé, že pri zvýšení počtu generácií na 1500 sa presnosť výrazne zlepšuje. Algoritmus vďaka funkcii `change` neustále generuje novú diverzitu, čo zabraňuje stagnácii na úrovni lokálnych miním. Dosiahnutá presnosť je nad 99.9%.

---

## 3. Bonus B: Funkcia Eggholder (10-D)

### (1) Graf priebehu fitness (Eggholder)
![Graf Eggholder](cesta_k_vasmu_obrazku_4.png)

### (2) Použité nastavenia
*   **nVar:** 10
*   **popSize:** 50, 100
*   **maxGen:** 1000, 1500
*   **mutRate:** 0.02
*   **Space:** [-512, 512]

### (3) Výsledné riešenie
*   **Najlepšie fitness:** **-7530** (v teste s popSize 50)
*   *V teste s popSize 100 bol dosiahnutý výsledok -7357.*

### (4) Komentár
Eggholderova funkcia je typická svojím "schodovitým" grafom. Algoritmus uviazne v lokálnom minime (plochá časť grafu) a trvá mnoho generácií, kým mutácia objaví cestu do hlbšej "jamky". Rozdiely medzi behmi sú tu najvýraznejšie kvôli extrémne členitému povrchu funkcie.

---

**Záver:**
Všetky úlohy boli úspešne vyriešené. Experimenty preukázali dôležitosť správneho nastavenia mutácie a populácie, najmä pri zvyšovaní dimenzionality problému.