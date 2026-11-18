import { useState } from 'react';

export interface BarDatum {
  label: string; // rótulo curto no eixo (ex.: "14h", "12/11")
  title: string; // rótulo completo no tooltip (ex.: "Terça, 12/11")
  value: number;
  detail?: string; // linha extra no tooltip (ex.: "3 vendas")
}

interface ColumnChartProps {
  data: BarDatum[];
  format: (value: number) => string;
  caption: string;
  labelEvery?: number; // mostra 1 a cada N rótulos no eixo
}

// Gráfico de colunas de uma série só: barras finas, tooltip ao passar o mouse.
export function ColumnChart({ data, format, caption, labelEvery = 1 }: ColumnChartProps) {
  const [active, setActive] = useState<number | null>(null);
  const max = Math.max(...data.map((d) => d.value), 0);
  const current = active === null ? null : data[active];

  return (
    <figure className="chart">
      <div className="chart-plot" onMouseLeave={() => setActive(null)}>
        <span className="chart-max">{max > 0 ? format(max) : ''}</span>
        <div className="chart-bars">
          {data.map((d, i) => (
            <div
              key={i}
              className={active === i ? 'chart-col active' : 'chart-col'}
              onMouseEnter={() => setActive(i)}
              onFocus={() => setActive(i)}
              onBlur={() => setActive(null)}
              tabIndex={0}
              aria-label={`${d.title}: ${format(d.value)}`}
            >
              <div className="chart-bar" style={{ height: max > 0 ? `${(d.value / max) * 100}%` : 0 }} />
            </div>
          ))}
        </div>
        {current && (
          <div
            className="chart-tooltip"
            style={{ left: `${((active! + 0.5) / data.length) * 100}%` }}
            role="status"
          >
            <span className="muted">{current.title}</span>
            <strong>{format(current.value)}</strong>
            {current.detail && <span className="muted">{current.detail}</span>}
          </div>
        )}
      </div>
      <div className="chart-axis" aria-hidden="true">
        {data.map((d, i) => (
          <span key={i}>{i % labelEvery === 0 ? d.label : ''}</span>
        ))}
      </div>
      <details className="chart-table">
        <summary>Ver em tabela</summary>
        <table>
          <caption>{caption}</caption>
          <tbody>
            {data.map((d, i) => (
              <tr key={i}>
                <th scope="row">{d.title}</th>
                <td>{format(d.value)}</td>
                {d.detail && <td>{d.detail}</td>}
              </tr>
            ))}
          </tbody>
        </table>
      </details>
    </figure>
  );
}

interface LineChartProps {
  data: BarDatum[];
  format: (value: number) => string;
  caption: string;
  labelEvery?: number;
}

// Linha de uma série com área suave; ao passar o mouse mostra a linha-guia e o valor.
export function LineChart({ data, format, caption, labelEvery = 1 }: LineChartProps) {
  const [active, setActive] = useState<number | null>(null);
  const max = Math.max(...data.map((d) => d.value), 0) || 1;
  const x = (i: number) => (data.length > 1 ? (i / (data.length - 1)) * 100 : 50);
  const y = (v: number) => 100 - (v / max) * 100;
  const points = data.map((d, i) => `${x(i)},${y(d.value)}`).join(' ');
  const current = active === null ? null : data[active];

  return (
    <figure className="chart">
      <div className="chart-plot" onMouseLeave={() => setActive(null)}>
        <span className="chart-max">{format(max)}</span>
        <div className="line-area">
          <svg viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
            <polygon className="line-fill" points={`0,100 ${points} 100,100`} />
            <polyline className="line-stroke" points={points} vectorEffect="non-scaling-stroke" />
          </svg>
          {current && (
            <>
              <div className="line-guide" style={{ left: `${x(active!)}%` }} />
              <div
                className="line-dot"
                style={{ left: `${x(active!)}%`, top: `${y(current.value)}%` }}
              />
            </>
          )}
          <div className="line-hits">
            {data.map((d, i) => (
              <div
                key={i}
                tabIndex={0}
                aria-label={`${d.title}: ${format(d.value)}`}
                onMouseEnter={() => setActive(i)}
                onFocus={() => setActive(i)}
                onBlur={() => setActive(null)}
              />
            ))}
          </div>
        </div>
        {current && (
          <div className="chart-tooltip" style={{ left: `${x(active!)}%` }} role="status">
            <span className="muted">{current.title}</span>
            <strong>{format(current.value)}</strong>
            {current.detail && <span className="muted">{current.detail}</span>}
          </div>
        )}
      </div>
      <div className="chart-axis line-axis" aria-hidden="true">
        {data.map((d, i) => (
          <span key={i}>{i % labelEvery === 0 ? d.label : ''}</span>
        ))}
      </div>
      <details className="chart-table">
        <summary>Ver em tabela</summary>
        <table>
          <caption>{caption}</caption>
          <tbody>
            {data.map((d, i) => (
              <tr key={i}>
                <th scope="row">{d.title}</th>
                <td>{format(d.value)}</td>
                {d.detail && <td>{d.detail}</td>}
              </tr>
            ))}
          </tbody>
        </table>
      </details>
    </figure>
  );
}

export interface PairDatum {
  key: string;
  label: string;
  a: number;
  b: number;
}

interface PairBarsProps {
  data: PairDatum[];
  labels: [string, string];
  format: (value: number) => string;
  caption: string;
}

// Duas barras por linha (ex.: vendido x em estoque), sempre com o número escrito ao lado.
export function PairBars({ data, labels, format, caption }: PairBarsProps) {
  const max = Math.max(...data.flatMap((d) => [d.a, d.b]), 0);
  const width = (v: number) => (max > 0 ? `${(v / max) * 100}%` : 0);

  return (
    <figure className="chart">
      <div className="legend">
        <span>
          <i className="swatch-a" /> {labels[0]}
        </span>
        <span>
          <i className="swatch-b" /> {labels[1]}
        </span>
      </div>
      <ul className="pairs">
        {data.map((d) => (
          <li key={d.key}>
            <span className="pair-label">{d.label}</span>
            <div className="pair-bars">
              <div className="pair-row">
                <div className="pair-bar pair-a" style={{ width: width(d.a) }} />
                <span>{format(d.a)}</span>
              </div>
              <div className="pair-row">
                <div className="pair-bar pair-b" style={{ width: width(d.b) }} />
                <span>{format(d.b)}</span>
              </div>
            </div>
          </li>
        ))}
      </ul>
      <details className="chart-table">
        <summary>Ver em tabela</summary>
        <table>
          <caption>{caption}</caption>
          <thead>
            <tr>
              <th scope="col">Produto</th>
              <th scope="col">{labels[0]}</th>
              <th scope="col">{labels[1]}</th>
            </tr>
          </thead>
          <tbody>
            {data.map((d) => (
              <tr key={d.key}>
                <th scope="row">{d.label}</th>
                <td>{format(d.a)}</td>
                <td>{format(d.b)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </details>
    </figure>
  );
}

export interface RankDatum {
  key: string;
  label: string;
  value: number;
  detail?: string;
}

// Ranking em barras horizontais, com nome e valor sempre escritos.
export function RankBars({ data, format }: { data: RankDatum[]; format: (value: number) => string }) {
  const max = Math.max(...data.map((d) => d.value), 0);
  return (
    <ul className="rank">
      {data.map((d) => (
        <li key={d.key}>
          <div className="rank-text">
            <span className="rank-label">{d.label}</span>
            <span className="rank-value">
              {format(d.value)}
              {d.detail && <span className="muted"> · {d.detail}</span>}
            </span>
          </div>
          <div className="rank-track">
            <div className="rank-bar" style={{ width: max > 0 ? `${(d.value / max) * 100}%` : 0 }} />
          </div>
        </li>
      ))}
    </ul>
  );
}
