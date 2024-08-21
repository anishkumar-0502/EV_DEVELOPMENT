import React, { useState } from 'react';
import { Route, Routes, Navigate, useNavigate } from 'react-router-dom';
import Login from '../associationadmin/page/Login';
import Dashboard from '../associationadmin/page/Dashboard';
import ManageDevice from '../associationadmin/page/ManageDevices/ManageDevice';
import ViewManageDevice from '../associationadmin/page/ManageDevices/ViewManageDevice';
import EditManageDevice from '../associationadmin/page/ManageDevices/EditManageDevice';
import ManageUsers from '../associationadmin/page/ManageUser/ManageUsers';
import ViewManageUser from '../associationadmin/page/ManageUser/ViewManageUser';
import EditManageUsers from '../associationadmin/page/ManageUser/EditManageUsers';
import AssignTagID from '../associationadmin/page/ManageUser/AssignTagID';
import ManageTagID from '../associationadmin/page/ManageTagID/ManageTagID';
import Wallet from '../associationadmin/page/Wallet';
import Profile from '../associationadmin/page/Profile';
import Assignuser from '../associationadmin/page/Assignuser';
import Header from '../associationadmin/components/Header';

const AssociationAdminApp = () => {
  const storedUser = JSON.parse(sessionStorage.getItem('associationAdminUser'));
  const [loggedIn, setLoggedIn] = useState(!!storedUser);
  const [userInfo, setUserInfo] = useState(storedUser || {});
  const navigate = useNavigate();

  // Handle login
  const handleLogin = (data) => {
    setUserInfo(data);
    setLoggedIn(true);
    sessionStorage.setItem('associationAdminUser', JSON.stringify(data));
    navigate('/associationadmin/Dashboard');
  };

  // Handle logout
  const handleLogout = () => {
    setLoggedIn(false);
    setUserInfo({});
    sessionStorage.removeItem('associationAdminUser');
    navigate('/associationadmin');
  };

  return (
    <>
      {loggedIn && <Header userInfo={userInfo} handleLogout={handleLogout} />}
      <Routes>
        <Route
          path="/"
          element={loggedIn ? <Navigate to="/associationadmin/Dashboard" /> : <Login handleLogin={handleLogin} />}
        />
        <Route
          path="/Dashboard"
          element={loggedIn ? (
              <Dashboard userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
              <Navigate to="/associationadmin" />
          )}
        />
        <Route
          path="/ManageDevice"
          element={loggedIn ? (
            <ManageDevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
        <Route
          path="/ViewManageDevice"
          element={loggedIn ? (
            <ViewManageDevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
        <Route
          path="/EditManageDevice"
          element={loggedIn ? (
            <EditManageDevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
        <Route
          path="/ManageUsers"
          element={loggedIn ? (
            <ManageUsers userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
        <Route
          path="/ViewManageUser"
          element={loggedIn ? (
            <ViewManageUser userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
         <Route
          path="/EditManageUsers"
          element={loggedIn ? (
            <EditManageUsers userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
        <Route
          path="/AssignTagID"
          element={loggedIn ? (
            <AssignTagID userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
         <Route
          path="/ManageTagID"
          element={loggedIn ? (
            <ManageTagID userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
        <Route
          path="/Assignuser"
          element={loggedIn ? (
            <Assignuser userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
         <Route
          path="/Wallet"
          element={loggedIn ? (
            <Wallet userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
        <Route
          path="/Profile"
          element={loggedIn ? (
            <Profile userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/associationadmin" />
          )}
        />
      </Routes>
    </>
  );
};

export default AssociationAdminApp;
