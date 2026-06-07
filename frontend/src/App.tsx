import { useMemo, useState } from 'react';

type RoadEventType =
  | 'ROAD_CLOSURE'
  | 'ROAD_CONSTRUCTION'
  | 'ROAD_INCIDENT'
  | 'ROAD_DEBRIS'
  | 'ROAD_WEATHER'
  | 'ROAD_OTHER';

type StatsItem = { type: string; count: number };
type ArchiveItem = { key: string; lastModified: string; size: number };

type LoginResult = {
  accessToken: string;
  idToken: string;
  refreshToken?: string;
};

const eventTypes: RoadEventType[] = [
  'ROAD_CLOSURE',
  'ROAD_CONSTRUCTION',
  'ROAD_INCIDENT',
  'ROAD_DEBRIS',
  'ROAD_WEATHER',
  'ROAD_OTHER',
];

const defaultApiBase =
  import.meta.env.VITE_API_BASE || (window as any).__API_BASE__ || '';

export function App() {
  const [apiBase, setApiBase] = useState(defaultApiBase);
  const [email, setEmail] = useState('jan3@test.com');
  const [password, setPassword] = useState('Password123!');
  const [firstName, setFirstName] = useState('Jan');
  const [lastName, setLastName] = useState('Kowalski');
  const [birthDate, setBirthDate] = useState('1990-01-01');
  const [phoneNumber, setPhoneNumber] = useState('+48123456789');
  const [token, setToken] = useState('');
  const [eventType, setEventType] = useState<RoadEventType>('ROAD_INCIDENT');
  const [latitude, setLatitude] = useState('52.2297');
  const [longitude, setLongitude] = useState('21.0122');
  const [eventId, setEventId] = useState('');
  const [stats, setStats] = useState<StatsItem[]>([]);
  const [archive, setArchive] = useState<ArchiveItem[]>([]);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const normalizedApi = useMemo(() => apiBase.replace(/\/$/, ''), [apiBase]);

  const callApi = async <T,>(path: string, init?: RequestInit): Promise<T> => {
    const response = await fetch(`${normalizedApi}${path}`, {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        ...(init?.headers ?? {}),
      },
    });

    if (!response.ok) {
      const bodyText = await response.text();
      throw new Error(`${response.status} ${response.statusText}: ${bodyText}`);
    }

    return (await response.json()) as T;
  };

  const register = async () => {
    setBusy(true);
    setError('');
    setMessage('');
    try {
      const res = await callApi<{ id: string }>('/user-data/users', {
        method: 'POST',
        body: JSON.stringify({
          email,
          password,
          name: firstName,
          lastName,
          birthDate,
          phoneNumber,
        }),
      });
      setMessage(`User created: ${res.id}`);
    } catch (e: any) {
      setError(e.message || 'Registration failed');
    } finally {
      setBusy(false);
    }
  };

  const login = async () => {
    setBusy(true);
    setError('');
    setMessage('');
    try {
      const res = await callApi<LoginResult>('/user-data/users/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      setToken(res.idToken);
      setMessage('Logged in. ID token loaded.');
    } catch (e: any) {
      setError(e.message || 'Login failed');
    } finally {
      setBusy(false);
    }
  };

  const publishEvent = async () => {
    setBusy(true);
    setError('');
    setMessage('');
    try {
      const res = await callApi<{ eventId: string }>('/road-events/events', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: JSON.stringify({
          eventType,
          latitude: Number(latitude),
          longitude: Number(longitude),
        }),
      });
      setEventId(res.eventId);
      setMessage(`Road event created: ${res.eventId}`);
    } catch (e: any) {
      setError(e.message || 'Creating event failed');
    } finally {
      setBusy(false);
    }
  };

  const fetchStats = async () => {
    setBusy(true);
    setError('');
    try {
      const res = await callApi<StatsItem[]>('/statistics/stats');
      setStats(res);
      setMessage('Statistics refreshed');
    } catch (e: any) {
      setError(e.message || 'Stats fetch failed');
    } finally {
      setBusy(false);
    }
  };

  const fetchArchive = async () => {
    setBusy(true);
    setError('');
    try {
      const res = await callApi<ArchiveItem[]>('/authorities/archive?limit=20');
      setArchive(res);
      setMessage('Archive refreshed (Lambda output from S3)');
    } catch (e: any) {
      setError(e.message || 'Archive fetch failed');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="page">
      <header className="hero">
        <h1>Road Events Control Panel</h1>
        <p>
          End-to-end demo: user registration, Cognito login, event publish,
          stats, and Lambda archive preview.
        </p>
      </header>

      <section className="card">
        <h2>1. API Config</h2>
        <label>
          ALB URL
          <input
            value={apiBase}
            onChange={(e) => setApiBase(e.target.value)}
            placeholder="http://microservices-alb-...eu-north-1.elb.amazonaws.com"
          />
        </label>
      </section>

      <section className="grid">
        <article className="card">
          <h2>2. Register</h2>
          <input
           
           
           
         
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email"
          />
          <input
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Password"
            type="password"
          />
          <input
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            placeholder="First name"
          />
          <input
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            placeholder="Last name"
          />
          <input
            value={birthDate}
            onChange={(e) => setBirthDate(e.target.value)}
            placeholder="YYYY-MM-DD"
          />
          <input
            value={phoneNumber}
            onChange={(e) => setPhoneNumber(e.target.value)}
            placeholder="+48123456789"
          />
          <button disabled={busy || !normalizedApi} onClick={register}>
            Create user
          </button>
        </art
            icle>
          

        <article className="card">
          <h2>3. Login</h2>
          <p>
            Logs in through /user-data/users/login (Cognito under the hood).
          </p>
          <button disabled={busy || !normalizedApi} onClick={login}>
            Login
          </button>
          <label>
            ID Token
            <textarea
              value={token}
              onChange={(e) => setToken(e.target.value)}
              placeholder="Token appears here after login"
              rows={5}
            />
          </label>
        </article>

        <article className="card">
          <h2>4. Create Road Event</h2>
          <select
            value={eventType}
            onChange={(e) => setEventType(e.target.value as RoadEventType)}
          >
            {eventTypes.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </select>
          <input
            value={latitude}
            onChange={(e) => setLatitude(e.target.value)}
            placeholder="Latitude"
          />
           
           
          
          <input
            value={longitude}
            onChange (
           ={(e) => setLongitude(e.target.value)}
          )
            placeholder="Longitude"
          />
          <button
            disabled={busy || !token || !normalizedApi}
            onClick={publishEvent}
          >
            Publish event
          </button>
          {eventId ? (
            <p className="inline-note">Last event: {eventId}</p>
          ) : null}
        </article>
      </section>

      <section className="grid">
        <article className="card">
          <h2>5. Statistics</h2>
          <button disabled={busy || !normalizedApi} onClick={fetchStats}>
            Refresh stats
          </button>
          <ul>
            {stats.map((item) => (
              <li key={item.type}>
                <strong>{item.type}</strong>: {item.count}
              </li>
            ))}
          </ul>
        </article>

        <article className="card">
          <h2>6. Lambda Archive (S3)</h2>
          <button disabled={busy || !normalizedApi} onClick={fetchArchive}>
            Refresh archive
          </button>
          <ul>
            {archive.map((item) => (
              <li key={item.key}>
                <div>{item.key}</div>
                <small>
                  {item.lastModified || 'n/a'} | {item.size} bytes
                </small>
              </li>
            ))}
          </ul>
        </article>
      </section>

      {message ? <p className="banner ok">{message}</p> : null}
      {error ? <p className="banner err">{error}</p> : null}
    </div>
  );
}
