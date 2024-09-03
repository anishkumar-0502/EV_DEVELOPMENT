import React, { useState, useEffect } from 'react';
import Sidebar from '../../components/Sidebar';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import { useLocation, useNavigate } from 'react-router-dom';

const Sessionhistoryclient = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    // State to hold session data
    const [sessions, setSessions] = useState([]);

    useEffect(() => {
        let { sessiondata } = location.state || {};
        if (sessiondata) {
            if(sessiondata[0] === 'No session found'){
                sessiondata =[];
                setSessions(sessiondata);
            }else{
                // If sessiondata is provided in location state, set it to state
                setSessions(sessiondata); // Assuming sessiondata is an array, or else convert it to array if single object
            }
            // Save sessiondata to localStorage
            localStorage.setItem('sessiondataClient', JSON.stringify(sessiondata));
        } else {
            // If sessiondata not in location state, try to load from localStorage
            const savedSessionData = JSON.parse(localStorage.getItem('sessiondataClient'));
            if (savedSessionData) {
                setSessions([savedSessionData]);
            }
        }
    }, [location.state]);

    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        if (Array.isArray(sessions)) {
            const filteredData = sessions.filter((item) =>
                item.user.toUpperCase().includes(inputValue)||
                item.charger_id.toUpperCase().includes(inputValue)
            );
            setSessions(filteredData);
        }
    };

    // backwards page navigation
    const goBack = () => {
        navigate(-1);
    };


    // formatTimestamp 
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
        hours = hours ? hours : 12; // the hour '0' should be '12'
        hours = String(hours).padStart(2, '0');

        return `${day}/${month}/${year} ${hours}:${minutes}:${seconds} ${ampm}`;
    };

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper" style={{ paddingTop: '40px' }}>
                {/* Sidebar */}
                <Sidebar />
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">View Session</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={goBack} style={{ marginRight: '10px' }}>Back</button>
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
                                        <div className="table-responsive">
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center' }}>
                                                    <tr>
                                                        <th>Sl.No</th>
                                                        <th>User</th>
                                                        <th>Charger Id</th>
                                                        <th>Session ID</th>
                                                        <th>Created Date</th>
                                                        <th>Price</th>
                                                        <th>Unit Consumed</th>
                                                        <th>Start Time</th>
                                                        <th>Stop Time</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{ textAlign: 'center' }}>
                                                    {sessions.length > 0 ? (
                                                        sessions.map((session, index) => (
                                                            <tr key={index}>
                                                                <td>{index + 1}</td>
                                                                <td>{session.user ? session.user : '-'}</td>
                                                                <td>{session.charger_id ? session.charger_id : '-'}</td>
                                                                <td>{session.session_id ?  session.session_id : '-'}</td>
                                                                <td>{session.created_date ? formatTimestamp(session.created_date) : '-'}</td>
                                                                <td>{session.price ? session.price :'-'}</td>
                                                                <td>{session.unit_consummed ? session.unit_consummed : '-'}</td>
                                                                <td>{session.start_time ? formatTimestamp(session.start_time) : '-'}</td>
                                                                <td>{session.stop_time ? formatTimestamp(session.stop_time) : '-'}</td>
                                                            </tr>
                                                        ))
                                                    ) : (
                                                        <tr className="text-center">
                                                            <td colSpan="9">No sessions found</td>
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
                    {/* Footer */}
                    <Footer />
                </div>
            </div>
        </div>
    );
};

export default Sessionhistoryclient;
