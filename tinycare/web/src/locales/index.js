import common from './partials/common.js';
import auth from './partials/auth.js';
import adminCore from './partials/admin-core.js';
import adminFinance from './partials/admin-finance.js';
import adminDaily from './partials/admin-daily.js';
import adminMgmt from './partials/admin-mgmt.js';
import parent from './partials/parent.js';
import components from './partials/components.js';
import misc from './partials/misc.js';

const groups = [common, auth, adminCore, adminFinance, adminDaily, adminMgmt, parent, components, misc];

const resources = {
  id: Object.assign({}, ...groups.map((g) => g.id)),
  en: Object.assign({}, ...groups.map((g) => g.en)),
};

export default resources;