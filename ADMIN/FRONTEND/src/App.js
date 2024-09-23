import React from 'react';
import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom';
import SuperAdminApp from './adminApps/SuperAdminApp';
import ResellerAdminApp from './adminApps/ResellerAdminApp';
import ClientAdminApp from './adminApps/ClientAdminApp';
import AssociationAdminApp from './adminApps/AssociationAdminApp';
import Log from './log/Logs';
import OcppConfig from './ocppconfig/page/OcppConfig';
import SessionLog from './sessionlog/page/SessionLogs';
const App = () => {
  
  return (
    <Router>
      <Routes>
        <Route path="/superadmin/*" element={<SuperAdminApp />} />
        <Route path="/reselleradmin/*" element={<ResellerAdminApp />} />
        <Route path="/clientadmin/*" element={<ClientAdminApp />} />
        <Route path="/associationadmin/*" element={<AssociationAdminApp />} />
        <Route path="/log/*" element={<Log />} />
        <Route path="/ocppconfig/*" element={<OcppConfig />} />
        <Route path="/sessionlog/*" element={<SessionLog />} />
        <Route path="/" element={<Navigate to="/superadmin" />} />
      </Routes>
    </Router>
  );
};

export default App;
