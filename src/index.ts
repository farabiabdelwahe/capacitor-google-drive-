import { registerPlugin } from '@capacitor/core';

import type { GoogleDrivePlugin } from './definitions';

const GoogleDrive = registerPlugin<GoogleDrivePlugin>('GoogleDrive', {
  web: () => import('./web').then((m) => new m.GoogleDriveWeb()),
});

export * from './definitions';
export { GoogleDrive };
