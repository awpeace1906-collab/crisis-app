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
            {row.map((cell, j) => (
              <td key={j} data-label={block.headers[j] ?? ''} dangerouslySetInnerHTML={{ __html: cell }} />
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
          <p dangerouslySetInnerHTML={{ __html: block.html }} />
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
