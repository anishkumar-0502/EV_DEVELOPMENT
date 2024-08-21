import React, { useState, useEffect, useRef } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate } from 'react-router-dom';
import { useLocation } from 'react-router-dom';

const AssignClient = ({ userInfo, handleLogout }) => {
    const location = useLocation();
    const dataItem = location.state?.dataItem || JSON.parse(localStorage.getItem('dataItem'));

    const navigate = useNavigate();

    // Back manage reseller
    const backManageReseller = () => {
        navigate('/superadmin/ManageReseller');
    };

    const [data, setData] = useState([]);
    const [filteredData, setFilteredData] = useState([]);
    const FetchAssignedClientsCalled = useRef(false);

    // Fetch assign clients data
    useEffect(() => {
        const fetchAssignedClients = async () => {
            try {
                const response = await fetch('/superadmin/FetchAssignedClients', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ reseller_id: dataItem.reseller_id }),
                });
                if (response.ok) {
                    const responseData = await response.json();
                    setData(responseData.data);
                    setFilteredData(responseData.data); // Initialize filtered data with all data
                } else {
                    console.error('Failed to fetch assigned clients');
                    console.log('Response status:', response.status);
                }
            } catch (error) {
                console.error('An error occurred while fetching the clients');
                console.error('Error:', error);
            }
        };

        if (!FetchAssignedClientsCalled.current && dataItem && dataItem.reseller_id) {
            fetchAssignedClients();
            FetchAssignedClientsCalled.current = true;
        }
    }, [dataItem]);

    useEffect(() => {
        if (dataItem) {
            localStorage.setItem('dataItem', JSON.stringify(dataItem));
        }
    }, [dataItem]);

    // Search input
    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        const filteredData = data.filter((item) =>
            item.client_name.toUpperCase().includes(inputValue)
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
                                        <h3 className="font-weight-bold">Assign Client's</h3>
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
                                                        <h4 className="card-title" style={{ paddingTop: '10px' }}>List Of Client's</h4>
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
                                                        <th>Client Name</th>
                                                        <th>Phone Number</th>
                                                        <th>Email ID</th>
                                                        <th>Address</th>
                                                        <th>Status</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{ textAlign: 'center' }}>
                                                    {filteredData.length > 0 ? (
                                                        filteredData.map((post, index) => (
                                                            <tr key={index}>
                                                                <td>{index + 1}</td>
                                                                <td>{post.client_name ? post.client_name : '-'}</td>
                                                                <td>{post.client_phone_no ? post.client_phone_no : '-'}</td>
                                                                <td>{post.client_email_id ? post.client_email_id : '-'}</td>
                                                                <td>{post.client_address ? post.client_address : '-'}</td>
                                                                <td>{post.status === true ? <span className="text-success">Active</span> : <span className="text-danger">DeActive</span>}</td>
                                                            </tr>
                                                        ))
                                                    ) : (
                                                        <tr>
                                                            <td colSpan="6" style={{ marginTop: '50px', textAlign: 'center' }}>No Assigned clients found</td>
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

export default AssignClient;
