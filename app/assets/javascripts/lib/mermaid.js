import mermaid from 'mermaid';
import { getParameterByName } from '~/lib/utils/url_utility';

const setIframeRenderedSize = (h, w) => {
  const { origin } = window.location;
  window.parent.postMessage({ h, w }, origin);
};

const drawDiagram = (source) => {
  const element = document.getElementById('app');
  const insertSvg = (svgCode) => {
    // eslint-disable-next-line no-unsanitized/property
    element.innerHTML = svgCode;

    const height = parseInt(element.firstElementChild.getAttribute('height'), 10);
    const width = parseInt(element.firstElementChild.style.maxWidth, 10);
    setIframeRenderedSize(height, width);
  };
  mermaid.mermaidAPI.render('mermaid', source, insertSvg);
};

const darkModeEnabled = () => getParameterByName('darkMode') === 'true';

const initMermaid = () => {
  let theme = 'neutral';

  if (darkModeEnabled()) {
    theme = 'dark';
  }

  mermaid.initialize({
    // mermaid core options
    mermaid: {
      startOnLoad: false,
    },
    // mermaidAPI options
    theme,
    flowchart: {
      useMaxWidth: true,
      htmlLabels: true,
    },
    secure: ['secure', 'securityLevel', 'startOnLoad', 'maxTextSize', 'htmlLabels'],
    securityLevel: 'strict',
  });
};

const addListener = () => {
  window.addEventListener(
    'message',
    (event) => {
      if (event.origin !== window.location.origin) {
        return;
      }
      drawDiagram(event.data);
    },
    false,
  );
};

addListener();
initMermaid();
export default {};
