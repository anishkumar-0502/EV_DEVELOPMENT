import React, { useState } from 'react';
import { Route, Routes, Navigate, useNavigate } from 'react-router-dom';
import Login from '../clientadmin/page/Login';
import Dashboard from '../clientadmin/page/Dashboard';
// managedevice
import Allocateddevice from '../clientadmin/page/Managedevice/Allocateddevice';
import Unallocateddevice from '../clientadmin/page/Managedevice/Unallocateddevice';
import ViewAlloc from '../clientadmin/page/Managedevice/ViewAlloc';
import ViewUnalloc from '../clientadmin/page/Managedevice/ViewUnalloc';
import AssigntoAssociation from  '../clientadmin/page/Managedevice/AssigntoAssociation';

// manageuser
import ManageUsers from '../clientadmin/page/Manageuser/ManageUsers';
import Viewuser from '../clientadmin/page/Manageuser/Viewuser';
import Edituser from '../clientadmin/page/Manageuser/Edituser';
import Createuser from '../clientadmin/page/Manageuser/Createuser';

// managefinance
import Managefinance from '../clientadmin/page/ManageFinance/Managefinance';
import ViewFinance from '../clientadmin/page/ManageFinance/ViewFinance';
import EditFinance from '../clientadmin/page/ManageFinance/EditFinance'
import CreateFinance from '../clientadmin/page/ManageFinance/CreateFinance'

// manageassociation
import ManageAssociation from '../clientadmin/page/ManageAssociation/ManageAssociation';
import ViewAss from '../clientadmin/page/ManageAssociation/ViewAss';
import Editass from '../clientadmin/page/ManageAssociation/Editass';
import Createass from '../clientadmin/page/ManageAssociation/Createass';
import Assigneddevass from '../clientadmin/page/ManageAssociation/Assigneddevass';
import Assignfinance from '../clientadmin/page/ManageAssociation/Assignfinance';
import Sessionhistoryass from '../clientadmin/page/ManageAssociation/Sessionhistoryass';


import Wallet from '../clientadmin/page/Wallet';
import Profile from '../clientadmin/page/Profile';
import Header from '../clientadmin/components/Header';

const ClientAdminApp = () => {
  const storedUser = JSON.parse(sessionStorage.getItem('clientAdminUser'));
  const [loggedIn, setLoggedIn] = useState(!!storedUser);
  const [userInfo, setUserInfo] = useState(storedUser || {});
  const navigate = useNavigate();

  // Handle login
  const handleLogin = (data) => {
    const { email, ...rest } = data;
    setUserInfo({ email, ...rest });
    setLoggedIn(true);
    sessionStorage.setItem('clientAdminUser', JSON.stringify({ email, ...rest }));
    navigate('/clientadmin/Dashboard');
  };

  // Handle logout
  const handleLogout = () => {
    setLoggedIn(false);
    setUserInfo({});
    sessionStorage.removeItem('clientAdminUser');
    navigate('/clientadmin');
  };

  return (
    <>
      {loggedIn && <Header userInfo={userInfo} handleLogout={handleLogout} />}
      <Routes>
        <Route
          path="/"
          element={loggedIn ? <Navigate to="/clientadmin/Dashboard" /> : <Login handleLogin={handleLogin} />}
        />
        <Route
          path="/Dashboard"
          element={loggedIn ? (
            <Dashboard userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
          <Navigate to="/clientadmin" />
          )}
        />
        {/* manage device */}
        <Route
          path="/Allocateddevice"
          element={loggedIn ? (
            <Allocateddevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Unallocateddevice"
          element={loggedIn ? (
            <Unallocateddevice userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/ViewAlloc"
          element={loggedIn ? (
            <ViewAlloc userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/ViewUnalloc"
          element={loggedIn ? (
            <ViewUnalloc userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/AssigntoAssociation"
          element={loggedIn ? (
            <AssigntoAssociation userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        {/*  */}

        {/* Manageuser */}
        <Route
          path="/ManageUsers"
          element={loggedIn ? (
            <ManageUsers userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Viewuser"
          element={loggedIn ? (
            <Viewuser userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Edituser"
          element={loggedIn ? (
            <Edituser userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Createuser"
          element={loggedIn ? (
            <Createuser userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        {/*  */}

        {/* Manage Finance */}
        <Route
          path="/Managefinance"
          element={loggedIn ? (
            <Managefinance userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/CreateFinance"
          element={loggedIn ? (
            <CreateFinance userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
              <Route
          path="/ViewFinance"
          element={loggedIn ? (
            <ViewFinance userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/EditFinance"
          element={loggedIn ? (
            <EditFinance userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        
        {/*  */}

        {/* Manage Association */}
        <Route
          path="/ManageAssociation"
          element={loggedIn ? (
            <ManageAssociation userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/ViewAss"
          element={loggedIn ? (
            <ViewAss userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Editass"
          element={loggedIn ? (
            <Editass userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Createass"
          element={loggedIn ? (
            <Createass userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Assigneddevass"
          element={loggedIn ? (
            <Assigneddevass userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Assignfinance"
          element={loggedIn ? (
            <Assignfinance userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Sessionhistoryass"
          element={loggedIn ? (
            <Sessionhistoryass userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        {/*  */}



        
        <Route
          path="/Wallet"
          element={loggedIn ? (
            <Wallet userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
        <Route
          path="/Profile"
          element={loggedIn ? (
            <Profile userInfo={userInfo} handleLogout={handleLogout} />
          ) : (
            <Navigate to="/clientadmin" />
          )}
        />
      </Routes>
    </>
  );
};

export default ClientAdminApp;
