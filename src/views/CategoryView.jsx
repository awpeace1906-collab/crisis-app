import { useParams } from 'react-router-dom';
import { useCrisisDB } from '../db/DataProvider.jsx';
import EntryList from './EntryList.jsx';

/** Home category tile destination — protocols and procedures mixed together for one category. */
export default function CategoryView() {
  const { categoryId } = useParams();
  const { meta } = useCrisisDB();
  const category = meta?.categories?.find((c) => c.id === categoryId);

  return (
    <EntryList
      kicker="Category"
      title={category?.label ?? 'Category'}
      lede="Protocols and procedures for this category, together."
      searchPlaceholder="Search this category…"
      emptyLabel="Nothing here"
      initialCategory={categoryId}
    />
  );
}
