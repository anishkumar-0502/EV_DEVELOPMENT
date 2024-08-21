import React, { useState } from 'react';
import { Route, Routes, Navigate, useNavigate } from 'react-router-dom';
import Login from '../superadmin/page/Login';
import Dashboard from '../superadmin/page/Dashboard';
import ManageDevice from '../superadmin/page/ManageDevices/ManageDevice';
import AddManageDevice from '../superadmin/page/ManageDevices/AddManageDevice';
import ViewManageDevice from '../superadmin/page/ManageDevices/ViewManageDevice';
import EditManageDevice from '../superadmin/page/ManageDevices/EditManageDevice';
import AssignReseller from '../superadmin/page/ManageDevices/AssignReseller';
import ManageReseller from '../superadmin/page/ManageResellers/ManageReseller';
import AddManageReseller from '../superadmin/page/ManageResellers/AddManageReseller';
import ViewManageReseller from '../superadmin/page/ManageResellers/ViewManageReseller';
import EditManageReseller from '../superadmin/page/ManageResellers/EditManageReseller';
import AssignClient from '../superadmin/page/ManageResellers/AssignClient';
import AssignCharger from '../superadmin/page/ManageResellers/AssignCharger';
import SessignHistory from '../superadmin/page/ManageResellers/SessignHistory';
import ManageUserRole from '../superadmin/page/ManageUserRole';
import ManageUsers from '../superadmin/page/ManageUsers/ManageUsers';
import ViewUserList from '../superadmin/page/ManageUsers/ViewUserList';
import EditUserList from '../superadmin/page/ManageUsers/EditUserList';
import Profile from '../superadmin/page/Profile';
import Header from '../superadmin/components/Header';

const SuperAdminApp = () => {
  const storedUser = JSON.parse(sessionStorage.getItem('superAdminUser'));
  const [loggedIn, setLoggedIn] = useState(!!storedUser);
  const [userInfo, setUserInfo] = useState(storedUser || {});
  const navigate = useNavigate();

  // Handl login
  const handleLogin = (data) => {
    setUserInfo(data);
    setLoggedIn(true);
    sessionStorage.setItem('superAdminUser', JSON.stringify(data));
    navigate('/superadmin/Dashboard');
  };

  // Handle logout
  const handleLogout = () => {
    setLoggedIn(false);
    setUserInfo({});
    sessionStorage.removeItem('superAdminUser');
    navigate('/superadmin');
  };

  return (
    <>
      {loggedIn && <Header userInfo={userInfo} handleLogout={handleLogout} />}
      <Routes>
        <Route
          path="/"
          element={loggedIn ? <Navigate to="/superadmin/Dashboard" /> : <Login handleLogin={handleLogin} />}
        />
        <Route
          path="Dashboard"
          element={loggedIn ? (
            <Dashboard userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="ManageDevice"
          element={loggedIn ? (
            <ManageDevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="AddManageDevice"
          element={loggedIn ? (
            <AddManageDevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="ViewManageDevice"
          element={loggedIn ? (
            <ViewManageDevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="EditManageDevice"
          element={loggedIn ? (
            <EditManageDevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="AssignReseller"
          element={loggedIn ? (
            <AssignReseller userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="ManageReseller"
          element={loggedIn ? (
            <ManageReseller userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="AddManageReseller"
          element={loggedIn ? (
            <AddManageReseller userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="ViewManageReseller"
          element={loggedIn ? (
            <ViewManageReseller userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="EditManageReseller"
          element={loggedIn ? (
            <EditManageReseller userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="AssignClient"
          element={loggedIn ? (
            <AssignClient userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="AssignCharger"
          element={loggedIn ? (
            <AssignCharger userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="SessignHistory"
          element={loggedIn ? (
            <SessignHistory userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="ManageUsers"
          element={loggedIn ? (
            <ManageUsers userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="ViewUserList"
          element={loggedIn ? (
            <ViewUserList userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="EditUserList"
          element={loggedIn ? (
            <EditUserList userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="ManageUserRole"
          element={loggedIn ? (
            <ManageUserRole userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
        <Route
          path="Profile"
          element={loggedIn ? (
            <Profile userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/superadmin" />
          )}
        />
      </Routes>
    </>
  );
};

export default SuperAdminApp;
