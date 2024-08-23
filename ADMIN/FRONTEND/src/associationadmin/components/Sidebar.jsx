import React from 'react';
import { useLocation } from 'react-router-dom';
import { Link } from 'react-router-dom';
const Sidebar = () => {
    const location = useLocation();

    return (
        <nav className="sidebar sidebar-offcanvas" id="sidebar">
            <ul className="nav">
                <li className={location.pathname === '/associationadmin/Dashboard' ? 'nav-item active' : 'nav-item'} key="dashboard">
                    <Link className="nav-link" to={{ pathname: "/associationadmin/Dashboard" }}>
                        <i className="icon-grid menu-icon"></i>
                        <span className="menu-title">Dashboard</span>
                    </Link>
                </li>
                <li className={location.pathname === '/associationadmin/ManageDevice' || location.pathname === '/associationadmin/ViewManageDevice' || location.pathname === '/associationadmin/EditManageDevice' ? 'nav-item active' : 'nav-item'} key="ManageDevice">
                    <Link className="nav-link" to={{ pathname: "/associationadmin/ManageDevice" }}>
                        <i className="icon-head menu-icon mdi mdi-cellphone-link"></i>
                        <span className="menu-title">Manage Device</span>
                    </Link>
                </li>
                <li className={location.pathname === '/associationadmin/ManageUsers' || location.pathname === '/associationadmin/EditManageUsers' || location.pathname === '/associationadmin/ViewManageUser' ? 'nav-item active' : 'nav-item'} key="ManageUsers">
                    <Link className="nav-link" to={{ pathname: "/associationadmin/ManageUsers" }}>
                        <i className="icon-head menu-icon mdi mdi-account-multiple"></i>
                        <span className="menu-title">Manage Users</span>
                    </Link>
                </li> 
                <li className={location.pathname === '/associationadmin/ManageTagID' ? 'nav-item active' : 'nav-item'} key="ManageTagID">
                    <Link className="nav-link" to={{ pathname: "/associationadmin/ManageTagID" }}>
                        <i className="icon-head menu-icon mdi mdi-tag"></i>
                        <span className="menu-title">Manage Tag ID</span>
                    </Link>
                </li>      
                <li className={location.pathname === '/associationadmin/Assignuser' || location.pathname === '/associationadmin/AssignTagID' ? 'nav-item active' : 'nav-item'} key="Assignuser">
                    <Link className="nav-link" to={{ pathname: "/associationadmin/Assignuser" }}>
                        <i className="icon-head menu-icon mdi mdi-account"></i>
                        <span className="menu-title">Assign User </span>
                    </Link>
                </li>          
                <li className={location.pathname === '/associationadmin/Wallet' ? 'nav-item active' : 'nav-item'} key="Wallet">
                    <Link className="nav-link" to={{ pathname: "/associationadmin/Wallet" }}>
                        <i className="icon-head menu-icon mdi mdi-wallet"></i>
                        <span className="menu-title">Wallet</span>
                    </Link>
                </li>
                <li className={location.pathname === '/associationadmin/Profile' ? 'nav-item active' : 'nav-item'} key="Profile">
                    <Link className="nav-link" to={{ pathname: "/associationadmin/Profile" }}>
                        <i className="icon-head menu-icon mdi mdi-account-circle"></i>
                        <span className="menu-title">Profile</span>
                    </Link>
                </li>
            </ul>
        </nav>
    );
};

export default Sidebar;
