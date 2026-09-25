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

function TableBlock({ block }) {
  return (
    <table className="rt">
      <tbody>
        <tr>{block.headers.map((h, i) => <th key={i}>{h}</th>)}</tr>
        {block.rows.map((row, i) => (
          <tr key={i}>
            {row.map((cell, j) => <td key={j} dangerouslySetInnerHTML={{ __html: cell }} />)}
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
