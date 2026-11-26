import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import './i18n.js'
import { loadRemoteTranslations } from './services/translationService'
import App from './App.jsx'

// Fire-and-forget: pull the admin-editable translation overlay from the API.
// Static bundles already render the full UI; the overlay only rewords them.
loadRemoteTranslations()

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
