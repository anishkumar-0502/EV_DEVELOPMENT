import React, { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';

const Header = ({ handleLogout }) => {
  const toggleButtonRef = useRef(null);
  const mobileToggleButtonRef = useRef(null);

  useEffect(() => {
    const handleToggleSidebar = () => {
      document.body.classList.toggle('sidebar-icon-only');
    };

    const handleMobileToggleSidebar = () => {
      document.querySelector('.sidebar-offcanvas').classList.toggle('active');
    };

    const button = toggleButtonRef.current;
    const mobileButton = mobileToggleButtonRef.current;

    if (button) {
      button.addEventListener('click', handleToggleSidebar);
    }

    if (mobileButton) {
      mobileButton.addEventListener('click', handleMobileToggleSidebar);
    }

    return () => {
      if (button) {
        button.removeEventListener('click', handleToggleSidebar);
      }
      if (mobileButton) {
        mobileButton.removeEventListener('click', handleMobileToggleSidebar);
      }
    };
  }, []);

  return (
    <nav className="navbar col-lg-12 col-12 p-0 fixed-top d-flex flex-row" style={{backgroundColor:'white'}}>
      <div className="text-center navbar-brand-wrapper d-flex align-items-center justify-content-center">
        <Link className="navbar-brand brand-logo mr-5" to="/associationadmin/Dashboard"><img src="../../images/dashboard/EV-ASSOCIATION-ADMIN.png" className="mr-2" alt="logo" style={{ paddingLeft: 10 }}/></Link>
        <Link className="navbar-brand brand-logo-mini" to="/associationadmin/Dashboard"><img src="../../images/dashboard/EV_Logo_16-12-2023.png" alt="logo"/></Link>
      </div>
      <div className="navbar-menu-wrapper d-flex align-items-center justify-content-end">
        <button className="navbar-toggler navbar-toggler align-self-center" type="button" ref={toggleButtonRef}>
          <span className="icon-menu"></span>
        </button>
        <ul className="navbar-nav navbar-nav-right">
          <li className="nav-item dropdown">
            <Link className="nav-link count-indicator dropdown-toggle" id="notificationDropdown" to="#" data-toggle="dropdown">
              <i className="icon-ellipsis"></i>
            </Link>
            <div className="dropdown-menu dropdown-menu-right navbar-dropdown preview-list" aria-labelledby="notificationDropdown">
              <button className="dropdown-item" onClick={handleLogout}>
                <i className="ti-power-off text-primary"></i>
                Logout
              </button>
            </div>
          </li>
        </ul>
        <button className="navbar-toggler navbar-toggler-right d-lg-none align-self-center" type="button" ref={mobileToggleButtonRef}>
          <span className="icon-menu"></span>
        </button>
      </div>
    </nav>
  );
};

export default Header;
