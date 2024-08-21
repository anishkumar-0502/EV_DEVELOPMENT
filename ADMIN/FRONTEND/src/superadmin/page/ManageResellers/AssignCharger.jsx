import React, { useState, useEffect, useRef } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate, useLocation } from 'react-router-dom';

const AssignCharger = ({ userInfo, handleLogout }) => {
    const location = useLocation();
    const navigate = useNavigate();
    const dataItem = location.state?.dataItem || JSON.parse(localStorage.getItem('dataItem'));

    const [data, setData] = useState([]);
    const [filteredData, setFilteredData] = useState([]);
    const FetchChargerDetailsWithSessionCalled = useRef(false);

    useEffect(() => {
        const fetchAssignedClients = async () => {
            try {
                const response = await fetch('/superadmin/FetchChargerDetailsWithSession', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ reseller_id: dataItem.reseller_id }),
                });
                if (response.ok) {
                    const responseData = await response.json();
                    setData(responseData.data);
                    console.log(responseData.data);
                    
                    setFilteredData(responseData.data); // Initialize filtered data with all data
                } else {
                    console.error('Failed to fetch assigned chargers');
                }
            } catch (error) {
                console.error('An error occurred while fetching assigned chargers');
                console.error('Error:', error);
            }
        };

        if (!FetchChargerDetailsWithSessionCalled.current && dataItem && dataItem.reseller_id) {
            fetchAssignedClients();
            FetchChargerDetailsWithSessionCalled.current = true; // Mark fetchProfile as called
        }
    }, [dataItem]);

    useEffect(() => {
        if (dataItem) {
            localStorage.setItem('dataItem', JSON.stringify(dataItem));
        }
    }, [dataItem]);

    // Back manage reseller
    const backManageReseller = () => {
        navigate('/superadmin/ManageReseller');
    };

    // View session history page
    const handleSessionHistory = (dataItem, sessiondata) => {
        if (dataItem && sessiondata && sessiondata.length > 0) {
            navigate('/superadmin/SessignHistory', { state: { dataItem, sessiondata } });
        } else {
            console.error('Data item or session data is undefined or empty.');
            // Handle the case where dataItem or sessiondata is not properly set
        }
    };

    // Search input
    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        const filteredData = data.filter((item) =>
            item.chargerID.toUpperCase().includes(inputValue)
        );
        setFilteredData(filteredData);
    };

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper">
                {/* Sidebar */}
                <Sidebar />
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Assign Chargers</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={backManageReseller}>Back</button>
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
                                                        <h4 className="card-title" style={{ paddingTop: '10px' }}>List Of Chargers</h4>
                                                    </div>
                                                    <div className="col-8 col-xl-4">
                                                        <div className="input-group">
                                                            <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                                <span className="input-group-text" id="search">
                                                                    <i className="icon-search"></i>
                                                                </span>
                                                            </div>
                                                            <input type="text" className="form-control" placeholder="Search now" aria-label="search" aria-describedby="search" autoComplete="off" onChange={handleSearchInputChange} />
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                    <tr> 
                                                        <th>Sl.No</th>
                                                        <th>Charger ID</th>
                                                        <th>Status</th>
                                                        <th>Option</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{ textAlign: 'center' }}>
                                                    {filteredData.length > 0 ? (
                                                        filteredData.map((post, index) => (
                                                            <tr key={index}>
                                                                <td>{index + 1}</td>
                                                                <td>{post.chargerID ? post.chargerID : '-'}</td>
                                                                <td>{post.status === true ? <span className="text-success">Active</span> : <span className="text-danger">DeActive</span>}</td>
                                                                <td>
                                                                    <button type="button" className="btn btn-outline-success btn-icon-text" onClick={() => handleSessionHistory(dataItem, post.sessiondata)} style={{ marginBottom: '10px', marginRight: '10px' }}>
                                                                        <i className="mdi mdi-eye"></i> Session History
                                                                    </button>
                                                                </td>
                                                            </tr>
                                                        ))
                                                    ) : (
                                                        <tr>
                                                            <td colSpan="4" style={{ marginTop: '50px', textAlign: 'center' }}>No assigned chargers found</td>
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

export default AssignCharger;
