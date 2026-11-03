// Browser expression for the existing CDP helper. No new connection or requests.
// Only releases the observed rc-queue-anim placeholder for this resume page.
(() => {
  if (location.origin !== 'https://jobs.bytedance.com' ||
      !['/campus/resume/view', '/campus/resume/edit'].includes(location.pathname)) {
    throw new Error('Expected the authorized ByteDance resume page');
  }
  const expected = location.pathname.endsWith('/edit') ? 'resumeEdit' : 'resumeView';
  const rootElement = document.querySelector('#bd');
  if (!rootElement) throw new Error('Resume page root missing');
  const key = Object.keys(rootElement).find(k =>
    k.startsWith('__reactContainer') || k.startsWith('__reactInternal'));
  const root = key ? rootElement[key] : rootElement._reactRootContainer?._internalRoot?.current;
  const matches = [], seen = new Set();
  function walk(node) {
    if (!node || seen.has(node)) return;
    seen.add(node);
    const instance = node.stateNode;
    if (instance?.state && 'childrenShow' in instance.state &&
        node.memoizedProps?.animConfig &&
        typeof instance.performEnterBegin === 'function' &&
        Array.isArray(instance.state.children) &&
        instance.state.children.length === 1 &&
        instance.state.children[0]?.key === expected) matches.push(instance);
    walk(node.child);
    walk(node.sibling);
  }
  walk(root?.current || root);
  if (matches.length !== 1) throw new Error('Expected one observed resume animation wrapper');
  const animation = matches[0];
  const before = !!animation.state.childrenShow[expected];
  if (!before) animation.performEnterBegin(expected);
  return { page: expected, placeholderAlreadyReleased: before,
    labelCount: document.querySelectorAll('label').length,
    sectionCount: document.querySelectorAll('.resumeViewSection-title').length };
})()
