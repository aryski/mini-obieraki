import asyncio
import httpx
import time
import sys

BASE_URL = "https://api-242c-8000.prg1.zerops.app"

async def get_valid_course_id(client: httpx.AsyncClient) -> str:
    """Pobiera pierwszy poprawny identyfikator przedmiotu z serwera."""
    response = await client.get(f"{BASE_URL}/przedmioty")
    response.raise_for_status()
    data = response.json()
    if not data:
        raise Exception("Brak przedmiotów w bazie danych na serwerze.")
    return data[0]["id"]

async def run_gemini_rate_limit_test():
    """Testuje przekroczenie limitu 5 RPM (zapytań na minutę) API Gemini."""
    print("\n=== TEST 1: PRZEKROCZENIE LIMITU GEMINI API (5 RPM) ===")
    print("Cel: Wysłanie 8 opinii w ciągu kilku sekund i sprawdzenie, czy serwer prawidłowo obsłuży błędy Rate Limit (HTTP 429).")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            course_id = await get_valid_course_id(client)
            print(f"Pobrano poprawny course_id do testu: {course_id}")
        except Exception as e:
            print(f"Błąd pobierania course_id: {e}")
            return

        # Przygotowujemy 8 unikalnych, merytorycznych opinii (długość > 10 znaków)
        opinie_payloads = [
            {"ocena": 5, "trudnosc": 2, "tresc": f"Opinia testowa numer {i}. Przedmiot jest całkiem ciekawy i warto na niego chodzić."}
            for i in range(1, 9)
        ]

        tokens = []
        print("Wysyłanie 8 opinii...")
        for i, payload in enumerate(opinie_payloads, 1):
            try:
                resp = await client.post(f"{BASE_URL}/przedmioty/{course_id}/opinie", json=payload)
                if resp.status_code == 202:
                    token = resp.json()["token_opinii"]
                    tokens.append(token)
                    print(f"  [{i}/8] Opinia wysłana pomyślnie (status 202). Token: {token[:8]}...")
                else:
                    print(f"  [{i}/8] Błąd wysyłania (status {resp.status_code}): {resp.text}")
            except Exception as e:
                print(f"  [{i}/8] Wyjątek podczas wysyłania: {e}")

        # Odczekajmy 15 sekund na zakończenie asynchronicznych zadań w tle na serwerze
        print("Oczekiwanie 15 sekund na przetworzenie opinii przez asynchronicznego moderatora w tle...")
        await asyncio.sleep(15.0)

        # Sprawdzamy statusy opinii
        print("Sprawdzanie statusów opinii:")
        success_count = 0
        rate_limit_count = 0
        
        results_summary = []
        for i, token in enumerate(tokens, 1):
            try:
                resp = await client.get(f"{BASE_URL}/opinie/{token}")
                if resp.status_code == 200:
                    status_data = resp.json()
                    status = status_data["status"]
                    reason = status_data.get("powod_odrzucenia")
                    print(f"  Opinia {i} (Token: {token[:8]}...): Status = '{status}', Powód = {reason}")
                    results_summary.append((i, token[:8], status, reason))
                    if status in ["opublikowana", "zmieniona_i_opublikowana"]:
                        success_count += 1
                    elif status == "blad_weryfikacji":
                        rate_limit_count += 1
                else:
                    print(f"  Błąd sprawdzania opinii {i} (status {resp.status_code})")
            except Exception as e:
                print(f"  Wyjątek podczas sprawdzania opinii {i}: {e}")

        print("\nPodsumowanie Testu Gemini:")
        print(f"  - Wysłano łącznie: {len(tokens)}")
        print(f"  - Zmoderowano pomyślnie: {success_count} (limity API Gemini zachowane)")
        print(f"  - Odrzucono jako 'blad_weryfikacji' (przekroczenie limitu / 429): {rate_limit_count}")
        print("WYNIK: " + ("SUKCES (Serwer obsłużył błędy Gemini i nie wywalił się)" if rate_limit_count > 0 else "Brak błędów rate limit - być może limit nie został jeszcze przekroczony."))
        return results_summary


async def send_single_stress_request(client: httpx.AsyncClient, req_id: int):
    """Wysyła pojedyncze zapytanie GET i mierzy czas oraz status."""
    start_time = time.perf_counter()
    try:
        resp = await client.get(f"{BASE_URL}/przedmioty")
        duration = (time.perf_counter() - start_time) * 1000.0  # ms
        return req_id, resp.status_code, duration, None
    except Exception as e:
        duration = (time.perf_counter() - start_time) * 1000.0  # ms
        return req_id, None, duration, str(e)

async def run_concurrency_stress_test(concurrency: int = 150):
    """Testuje przeciążenie serwera i bazy danych poprzez 150 równoległych żądań."""
    print(f"\n=== TEST 2: STRESS TEST CONCURRENCY ({concurrency} równoległych żądań) ===")
    print(f"Cel: Wysłanie {concurrency} zapytań GET /przedmioty jednocześnie w celu wywołania przeciążenia serwera.")

    # Wyłączamy limity połączeń w httpx, by wysłać wszystko na raz
    limits = httpx.Limits(max_keepalive_connections=None, max_connections=None)
    async with httpx.AsyncClient(limits=limits, timeout=30.0) as client:
        tasks = [send_single_stress_request(client, i) for i in range(1, concurrency + 1)]
        
        print(f"Uruchamianie {concurrency} zapytań równolegle...")
        start_test = time.perf_counter()
        results = await asyncio.gather(*tasks)
        total_test_duration = time.perf_counter() - start_test

        # Analiza wyników
        success_count = 0
        error_count = 0
        connection_failed_count = 0
        status_codes = {}
        durations = []

        for req_id, status_code, duration, err_msg in results:
            durations.append(duration)
            if err_msg:
                connection_failed_count += 1
                error_count += 1
            else:
                status_codes[status_code] = status_codes.get(status_code, 0) + 1
                if status_code == 200:
                    success_count += 1
                else:
                    error_count += 1

        durations.sort()
        avg_dur = sum(durations) / len(durations)
        median_dur = durations[len(durations) // 2]
        p95_dur = durations[int(len(durations) * 0.95)]
        p99_dur = durations[int(len(durations) * 0.99)]
        min_dur = min(durations)
        max_dur = max(durations)

        print("\nPodsumowanie Stress Testu:")
        print(f"  - Całkowity czas wykonania serii: {total_test_duration:.2f} s")
        print(f"  - Łączna liczba żądań: {concurrency}")
        print(f"  - Pomyślne (HTTP 200): {success_count} ({success_count/concurrency*100:.2f}%)")
        print(f"  - Błędne (HTTP >= 400 lub awaria sieci): {error_count} ({error_count/concurrency*100:.2f}%)")
        print(f"  - Rozkład kodów odpowiedzi HTTP: {status_codes}")
        print(f"  - Awaria połączenia (Network/Timeout Error): {connection_failed_count}")
        print(f"  - Czasy odpowiedzi:")
        print(f"    - Min: {min_dur:.2f} ms")
        print(f"    - Średni: {avg_dur:.2f} ms")
        print(f"    - Mediana: {median_dur:.2f} ms")
        print(f"    - p95: {p95_dur:.2f} ms")
        print(f"    - p99: {p99_dur:.2f} ms")
        print(f"    - Max: {max_dur:.2f} ms")
        
        return {
            "total_duration": total_test_duration,
            "success_count": success_count,
            "error_count": error_count,
            "status_codes": status_codes,
            "connection_failed": connection_failed_count,
            "min": min_dur,
            "avg": avg_dur,
            "median": median_dur,
            "p95": p95_dur,
            "p99": p99_dur,
            "max": max_dur
        }

async def main():
    await run_gemini_rate_limit_test()
    print("\n--- URUCHAMIANIE TESTU GRANICY WYDAJNOŚCI (65 CONCURRENT) ---")
    await run_concurrency_stress_test(65)
    print("\n--- URUCHAMIANIE EKSTREMALNEGO STRESS TESTU (80 CONCURRENT) ---")
    await run_concurrency_stress_test(80)

if __name__ == "__main__":
    asyncio.run(main())
