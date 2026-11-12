import { fileURLToPath } from 'node:url';

const appRoot = fileURLToPath(new URL('../', import.meta.url));
const scenes = [
  ['inbox', 'Toutes vos\ndiscussions', 'Support et messages directs au même endroit.', '#45259B', 'hero'],
  ['live', 'Échangez\nen direct', 'Voyez quand votre interlocuteur écrit.', '#224579', 'tilt-right'],
  ['delivery', 'Gardez le fil\ndes livraisons', 'Retrouvez chaque échange dans sa conversation.', '#633556', 'classic'],
  ['support', 'Un support\nplus humain', 'Identifiez la personne qui a répondu.', '#6A3A29', 'tilt'],
];

export default {
  appRoot,
  appPath: `${appRoot}build/ios/iphonesimulator/Runner.app`,
  bundleId: 'com.zeroonesupplies.chat.dev',
  devices: ['iphone-6.9'],
  locales: ['fr-FR'],
  frame: { variant: '17-pro-silver' },
  theme: {
    headlineColor: '#FFFFFF',
    subheadColor: '#E4DFF2',
    fontFamily: 'DM Sans',
    copyHeightRatio: 0.25,
    deviceWidthRatio: 0.76,
    background: '#080811',
  },
  store: { name: '01 Chat', developer: 'Sogenuvo', category: 'Productivité' },
  scenes: scenes.map(([id, headline, subhead, glow, layout]) => ({
    kind: 'screenshot',
    id,
    flow: id,
    headline: { 'fr-FR': headline },
    subhead: { 'fr-FR': subhead },
    background: `linear-gradient(155deg, #080811 10%, ${glow} 100%)`,
    layout,
  })),
};
