function StepsBlock({ block }) {
  return (
    <div className="box">
      {block.steps.map((step, i) => (
        <div className="step-row" key={i}>
          <div className="step-num" style={{ background: `var(--${step.color})` }}>{step.num}</div>
          <div className="step-body">
            <div className="step-title">{step.title}</div>
            <div className="step-desc" dangerouslySetInnerHTML={{ __html: step.html }} />
          </div>
        </div>
      ))}
    </div>
  );
}

const COLSPAN = '<!--colspan-->';

/** Group a row's cells with the placeholder columns their colspan covers
 *  (crisis-content emits COLSPAN for each), so the span is rebuilt on the
 *  table and the card label names every column the value belongs to. */
function spannedCells(row, headers) {
  const out = [];
  row.forEach((cell, j) => {
    if (cell === COLSPAN) return;
    let span = 1;
    while (row[j + span] === COLSPAN) span++;
    out.push({ html: cell, col: j, span, label: headers.slice(j, j + span).filter(Boolean).join(' / ') });
  });
  return out;
}

// Three or more columns cannot fit a phone as a grid, so below phone width
// they reflow to one card per row (see .rt-stack in tokens.css): the first
// cell is the card's title and every other cell carries its column header
// via data-label. Two-column tables stay a real table with a fixed first
// column, so headers and cells always line up.
function TableBlock({ block }) {
  const cols = Math.max(block.headers.length, ...block.rows.map((r) => r.length));
  return (
    <table className={cols >= 3 ? 'rt rt-stack' : 'rt'}>
      <tbody>
        <tr className="rt-head">{block.headers.map((h, i) => <th key={i}>{h}</th>)}</tr>
        {block.rows.map((row, i) => (
          <tr key={i}>
            {spannedCells(row, block.headers).map((c) => (
              <td key={c.col} colSpan={c.span > 1 ? c.span : undefined} data-label={c.label} dangerouslySetInnerHTML={{ __html: c.html }} />
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function SourcesBlock({ block }) {
  return (
    <ul className="sources">
      {block.items.map((item, i) => (
        <li key={i}>
          {item.tier && <span className="tier">{item.tier}</span>}
          <span dangerouslySetInnerHTML={{ __html: item.html }} />
        </li>
      ))}
    </ul>
  );
}

export function Block({ block }) {
  switch (block.type) {
    case 'steps':
      return <StepsBlock block={block} />;
    case 'box':
      return <div className={`box t-${block.color}`} dangerouslySetInnerHTML={{ __html: block.html }} />;
    case 'alert':
      return (
        <div className={`alert ${block.color}`}>
          {block.title && <div className="alert-t">{block.title}</div>}
          {/* A div, not a <p>: a multi-paragraph alert arrives as <p>…</p><p>…</p>,
              and a <p> inside a <p> is invalid HTML that the browser splits apart. */}
          <div className="alert-body" dangerouslySetInnerHTML={{ __html: block.html }} />
        </div>
      );
    case 'table':
      return <TableBlock block={block} />;
    case 'figure':
      return (
        <figure className="fig">
          <div className="fig-svg" role="img" aria-label={block.alt} dangerouslySetInnerHTML={{ __html: block.svg }} />
          {block.caption && <figcaption dangerouslySetInnerHTML={{ __html: block.caption }} />}
        </figure>
      );
    case 'xref':
      return <div className="xref" dangerouslySetInnerHTML={{ __html: block.html }} />;
    case 'sources':
      return <SourcesBlock block={block} />;
    case 'html':
      return <div dangerouslySetInnerHTML={{ __html: block.html }} />;
    case 'tagline':
      return <div className="tagline" dangerouslySetInnerHTML={{ __html: block.html }} />;
    default:
      return null;
  }
}

export function SectionBlocks({ blocks }) {
  return blocks.map((block, i) => <Block block={block} key={i} />);
}
