import React, { useState, useEffect, useMemo } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate, useLocation } from 'react-router-dom';

const SessionHistory = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const dataItem = location.state?.dataItem;

    const sessiondatass = useMemo(() => {
        return location.state?.sessiondata || JSON.parse(localStorage.getItem('sessiondata')) || [];
    }, [location.state]);

    const [posts, setPosts] = useState(sessiondatass);

    useEffect(() => {
        if (sessiondatass && sessiondatass.length > 0) {
            if (sessiondatass[0] === "No session found") {
                setPosts([]);
            } else {
                setPosts(sessiondatass);
            }
        }
        // Save sessiondatass to localStorage
        localStorage.setItem('sessiondata', JSON.stringify(sessiondatass));
    }, [sessiondatass]);

    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        if (Array.isArray(sessiondatass)) {
            const filteredData = sessiondatass.filter((item) =>
                item.user.toUpperCase().includes(inputValue) ||
                item.charger_id.toUpperCase().includes(inputValue)
            );
            setPosts(filteredData);
        }
    };

    const backManageReseller = (dataItem) => {
        navigate('/superadmin/AssignCharger', { state: { dataItem } });
    };

    const formatTimestamp = (originalTimestamp) => {
        const date = new Date(originalTimestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();

        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const seconds = String(date.getSeconds()).padStart(2, '0');
        const ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12;
        hours = String(hours).padStart(2, '0');

        return `${day}/${month}/${year} ${hours}:${minutes}:${seconds} ${ampm}`;
    };

    return (
        <div className='container-scroller'>
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper">
                <Sidebar />
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Session History</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={() => backManageReseller(dataItem)}>Back</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div className="row">
                                            <div className="col-md-12 grid-margin">
                                                <div className="row">
                                                    <div className="col-4 col-xl-8">
                                                        <h4 className="card-title" style={{ paddingTop: '10px' }}>List Of History</h4>
                                                    </div>
                                                    <div className="col-8 col-xl-4">
                                                        <div className="input-group">
                                                            <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                                <span className="input-group-text" id="search">
                                                                    <i className="icon-search"></i>
                                                                </span>
                                                            </div>
                                                            <input 
                                                                type="text" 
                                                                className="form-control" 
                                                                placeholder="Search user or charger id" 
                                                                aria-label="search" 
                                                                aria-describedby="search" 
                                                                autoComplete="off" 
                                                                onChange={handleSearchInputChange} 
                                                            />
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center', position: 'sticky', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                    <tr>
                                                        <th>Sl.No</th>
                                                        <th>User</th>
                                                        <th>Charger ID</th>
                                                        <th>Session ID</th>
                                                        <th>Created Date</th>
                                                        <th>Price</th>
                                                        <th>Unit Consumed</th>
                                                        <th>Start Time</th>
                                                        <th>Stop Time</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{ textAlign: 'center' }}>
                                                    {posts.length > 0 ? (
                                                        posts.map((post, index) => (
                                                            <tr key={index}>
                                                                <td>{index + 1}</td>
                                                                <td>{post.user ? post.user : '-'}</td>
                                                                <td>{post.charger_id ? post.charger_id : '-'}</td>
                                                                <td>{post.session_id ? post.session_id : '-'}</td>
                                                                <td>{post.created_date ? formatTimestamp(post.created_date) : '-'}</td>
                                                                <td>{post.price ? post.price : '-'}</td>
                                                                <td>{post.unit_consummed ? post.unit_consummed : '-'}</td>
                                                                <td>{post.start_time ? formatTimestamp(post.start_time) : '-'}</td>
                                                                <td>{post.stop_time ? formatTimestamp(post.stop_time) : '-'}</td>
                                                            </tr>
                                                        ))
                                                    ) : (
                                                        <tr>
                                                            <td colSpan="9" style={{ textAlign: 'center' }}>No sessions found</td>
                                                        </tr>
                                                    )}
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <Footer />
                </div>
            </div>
        </div>
    );
};

export default SessionHistory;
