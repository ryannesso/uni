# Odvodenie Denavit-Hartenbergových (DH) parametrov

Tento dokument obsahuje detailný postup určenia štandardných DH parametrov pre priamu kinematiku 6-osového robotického ramena na základe zadanej kinematickej štruktúry a modelu URDF.

## 1. Štandardná Denavit-Hartenbergova (DH) konvencia

Na popísanie polohy a orientácie koncového bodu (TCP) používame štandardnú DH konvenciu, ktorá každému kĺbu priraďuje lokálny súradnicový systém na základe nasledujúcich pravidiel:
*   **Os $Z_{i-1}$** leží v osi rotácie (alebo posuvu) kĺbu $i$.
*   **Os $X_i$** leží na spoločnej normále medzi osami $Z_{i-1}$ a $Z_i$.
*   **Os $Y_i$** dopĺňa systém tak, aby bol pravotočivý.

**Štyri DH parametre popisujúce transformáciu z rámu $i-1$ do rámu $i$:**
1.  **$\theta_i$ (uhol kĺbu):** Uhol otočenia okolo osi $Z_{i-1}$ od osi $X_{i-1}$ po os $X_i$. (Premenná pre rotačné kĺby).
2.  **$d_i$ (offset článku):** Posunutie pozdĺž osi $Z_{i-1}$ od osi $X_{i-1}$ po os $X_i$. (Premenná pre prismatické kĺby).
3.  **$a_i$ (dĺžka článku):** Posunutie pozdĺž osi $X_i$ od osi $Z_{i-1}$ po os $Z_i$.
4.  **$\alpha_i$ (skrútenie článku):** Uhol otočenia okolo osi $X_i$ od osi $Z_{i-1}$ po os $Z_i$.

---

## 2. Analýza nulovej polohy a priradenie osí

Podľa modelu robota v URDF je rameno v nulovej polohe ($q_i = 0$) **vystreté vertikálne nahor pozdĺž osi Z**.

Fyzické vzdialenosti medzi kĺbmi podľa tabuľky:
*   $l_0 = 0$ m, $l_1 = 0$ m
*   $l_2 = 0,203$ m (vzdialenosť J2 -> J3)
*   $l_3 = 0,203$ m (vzdialenosť J3 -> J4)
*   $l_4 = 0,05$ m (vzdialenosť J4 -> J5)
*   $l_5 = 0,15$ m (základná vzdialenosť J5 -> J6)

Smerovanie osí rotácie:
*   **J1:** okolo Z
*   **J2:** okolo Y
*   **J3:** okolo Y
*   **J4:** okolo Z (kĺb roluje rameno)
*   **J5:** okolo Y
*   **J6:** posuv pozdĺž Z (teleskopický/prismatický kĺb)

---

## 3. Tabuľka DH parametrov

Na základe rigorózneho priradenia súradnicových systémov v priestore získavame nasledujúcu tabuľku štandardných DH parametrov:

| Článok ($i$) | Kĺb | $\theta_i$ [rad] | $d_i$ [m] | $a_i$ [m] | $\alpha_i$ [rad] |
| :---: | :---: | :--- | :--- | :--- | :--- |
| **1** | **J1** (Z) | $q_1$ | $0$ | $0$ | $-\pi/2$ |
| **2** | **J2** (Y) | $q_2 - \pi/2$ | $0$ | $l_2 = 0,203$ | $0$ |
| **3** | **J3** (Y) | $q_3 + \pi/2$ | $0$ | $0$ | $\pi/2$ |
| **4** | **J4** (Z) | $q_4$ | $l_3 + l_4 = 0,253$ | $0$ | $-\pi/2$ |
| **5** | **J5** (Y) | $q_5$ | $0$ | $0$ | $\pi/2$ |
| **6** | **J6** (Z) | $0$ | $l_5 + q_6 = 0,15 + q_6$ | $0$ | $0$ |

*(Kde $q_1$ až $q_5$ sú uhly natočenia rotačných kĺbov a $q_6$ je výsuv prismatického kĺbu z intervalu $<0; 0,1>$.)*

---

## 4. Krok za krokom: Detailné vysvetlenie výpočtu

**Rám 0 (Základňa):** Os $Z_0$ leží v osi Z (nahor). Os $X_0$ leží v osi X.

*   **Transformácia 1 (J1 -> J2):**
    J1 rotuje okolo Z ($Z_0$). Nasledujúci kĺb J2 rotuje okolo Y, takže os $Z_1$ smeruje v osi Y. Osi sa pretínajú v počiatku ($a_1=0, d_1=0$). Aby sme otočili os Z do osi Y okolo X, uplatníme rotáciu $\alpha_1 = -90^\circ$ ($-\pi/2$).

*   **Transformácia 2 (J2 -> J3):**
    Obe osi $Z_1$ aj $Z_2$ rotujú okolo Y, sú teda rovnobežné. Spoločná normála $X_2$ musí smerovať k J3. Keďže rameno smeruje vertikálne nahor, $X_2$ musí smerovať nahor. Aby os X smerovala nahor, musíme ju otočiť o $-90^\circ$. Preto je kĺbová premenná posunutá: $\theta_2 = q_2 - \pi/2$. Vzdialenosť medzi kĺbmi je $a_2 = 0,203$ m. 

*   **Transformácia 3 (J3 -> J4):**
    Kĺb J3 rotuje okolo Y ($Z_2$). Kĺb J4 rotuje okolo Z ($Z_3$). Keďže os J4 smeruje zhora presne cez stred J3, osi $Z_2$ a $Z_3$ sa **pretínajú** v strede J3. Keďže sa pretínajú, $a_3 = 0$ a $d_3 = 0$. Os $X_3$ vraciame do horizontálnej polohy rotáciou $+90^\circ$ ($\theta_3 = q_3 + \pi/2$). Preklop osí Y -> Z je $\alpha_3 = \pi/2$. Počiatok rámu 3 zostáva v strede J3.

*   **Transformácia 4 (J4 -> J5):**
    Tu prichádza najdôležitejší posun. Os $Z_3$ je os Z (J4). Os $Z_4$ je os Y (J5). Pretínajú sa v strede kĺbu J5. Počiatok rámu 4 je v J5. Posun pozdĺž osi $Z_3$ od počiatku rámu 3 (ktorý zostal v J3) až po J5 pokrýva obidva úseky $l_3$ aj $l_4$. Preto $d_4 = l_3 + l_4 = 0,203 + 0,05 = 0,253$ m. Kríženie osí Z -> Y vyžaduje $\alpha_4 = -\pi/2$.

*   **Transformácia 5 (J5 -> J6):**
    J5 rotuje okolo Y ($Z_4$). J6 je prismatický pozdĺž Z ($Z_5$). Osi sa opäť pretínajú priamo v telese J5. Počiatok rámu 5 je v J5. Platí $a_5 = 0, d_5 = 0$. Preklop osí Y -> Z určuje $\alpha_5 = \pi/2$.

*   **Transformácia 6 (J6 -> tool0):**
    Os $Z_5$ leží v osi prismatického kĺbu. Koncový bod sa posúva pozdĺž tejto osi. Fixná časť dĺžky je $l_5 = 0,15$ m, k nej sa pripočítava premenná vysunutia $q_6$. Osi sa nekrížia ($\alpha_6 = 0, a_6 = 0$). Celkový posun $d_6 = 0,15 + q_6$.

---

## 5. Rovnice pre priamu kinematiku

Výsledná pozícia a orientácia koncového bodu voči základni je daná súčinom matíc homogénnej transformácie:

$$ T_{0}^{6} = A_1 \cdot A_2 \cdot A_3 \cdot A_4 \cdot A_5 \cdot A_6 $$

Všeobecný tvar transformačnej matice $A_i$ pre $i$-ty článok (na základe štandardnej DH konvencie) je definovaný ako:

$$
A_i = \begin{bmatrix} 
\cos\theta_i & -\sin\theta_i\cos\alpha_i & \sin\theta_i\sin\alpha_i & a_i\cos\theta_i \\
\sin\theta_i & \cos\theta_i\cos\alpha_i & -\cos\theta_i\sin\alpha_i & a_i\sin\theta_i \\
0 & \sin\alpha_i & \cos\alpha_i & d_i \\
0 & 0 & 0 & 1
\end{bmatrix}
$$

Dosadením konkrétnych parametrov z tabuľky vyššie do tohto maticového vzťahu získame analytický model kinematiky robota pripravený na implementáciu v C++/Matlabe.