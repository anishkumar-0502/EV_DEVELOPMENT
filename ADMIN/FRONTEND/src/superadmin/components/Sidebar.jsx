import React from 'react';
import { useLocation } from 'react-router-dom';
import { Link } from 'react-router-dom';

const Sidebar = () => {
  const location = useLocation();
  return (
    <nav className="sidebar sidebar-offcanvas" id="sidebar">
      <ul className="nav">
        <li className={location.pathname === '/superadmin/Dashboard' ? 'nav-item active' : 'nav-item'}>
          <Link className="nav-link" to="/superadmin/Dashboard">
            <i className="icon-grid menu-icon"></i>
            <span className="menu-title">Dashboard</span>
          </Link>
        </li>
        <li className={location.pathname === '/superadmin/ManageDevice' || location.pathname === '/superadmin/AddManageDevice' || location.pathname === '/superadmin/ViewManageDevice'  || location.pathname === '/superadmin/EditManageDevice' || location.pathname === '/superadmin/AssignReseller'  ? 'nav-item active' : 'nav-item'}>
          <Link className="nav-link" to="/superadmin/ManageDevice">
            <i className="icon-head menu-icon mdi mdi-cellphone-link"></i>
            <span className="menu-title">Manage Device</span>
          </Link>
        </li>
        <li className={location.pathname === '/superadmin/ManageReseller' || location.pathname === '/superadmin/AddManageReseller' || location.pathname === '/superadmin/ViewManageReseller'  || location.pathname === '/superadmin/EditManageReseller' || location.pathname === '/superadmin/AssignClient' || location.pathname === '/superadmin/AssignCharger' || location.pathname === '/superadmin/SessignHistory' ? 'nav-item active' : 'nav-item'}>
          <Link className="nav-link" to="/superadmin/ManageReseller">
            <i className="icon-head menu-icon mdi mdi-account-group"></i>
            <span className="menu-title">Manage Reseller</span>
          </Link>
        </li>
        <li className={location.pathname === '/superadmin/ManageUserRole' ? 'nav-item active' : 'nav-item'}>
          <Link className="nav-link" to="/superadmin/ManageUserRole">
            <i className="icon-head menu-icon mdi mdi-account"></i>
            <span className="menu-title">Manage User Roles</span>
          </Link>
        </li>
        <li className={location.pathname === '/superadmin/ManageUsers' || location.pathname === '/superadmin/ViewUserList'  || location.pathname === '/superadmin/EditUserList' ? 'nav-item active' : 'nav-item'}>
          <Link className="nav-link" to="/superadmin/ManageUsers">
            <i className="icon-head menu-icon mdi mdi-account-multiple"></i>
            <span className="menu-title">Manage Users</span>
          </Link>
        </li>
        <li className={location.pathname === '/superadmin/Profile' ? 'nav-item active' : 'nav-item'}>
          <Link className="nav-link" to="/superadmin/Profile">
            <i className="icon-head menu-icon mdi mdi-account-circle"></i>
            <span className="menu-title">Profile</span>
          </Link>
        </li>
      </ul>
    </nav>
  );
};

export default Sidebar;
