import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Sidebar from '../../components/Sidebar';

const ViewClient = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const [newUser, setNewUser] = useState({
        client_name: '', client_id: '', client_phone_no: '', client_email_id: '', client_address: '', 
        status: '', created_by: '', created_date: '', modified_by: '', modified_date: '', client_waller: '', });

    useEffect(() => {
        const { user } = location.state || {};
        if (user) {
            setNewUser({
                client_name: user.client_name || '',
                client_id: user.client_id || '',
                client_waller: user.client_waller || '',
                client_phone_no: user.client_phone_no || '',
                client_email_id: user.client_email_id || '',
                client_address: user.client_address || '',
                status: user.status || '',
                created_by: user.created_by || '',
                created_date: user.created_date || '',
                modified_by: user.modified_by || '',
                modified_date: user.modified_date || '',
            });
        // Save to localStorage
        localStorage.setItem('userData', JSON.stringify(user));
        } else {
            // Load from localStorage if available
            const savedData = JSON.parse(localStorage.getItem('userData'));
            if (savedData) {
                setNewUser(savedData);
            }
        }
    }, [location]);

    // back manageclient page
    const goBack = () => {
        navigate('/reselleradmin/ManageClient');
    };

    // back updateclient page
    const navigateToEditUser = (newUser) => {
        navigate('/reselleradmin/updateclient', { state: { newUser } });
    };

    // Timestamp
    function formatTimestamp(originalTimestamp) {
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

        const formattedDate = `${day}/${month}/${year} ${hours}:${minutes}:${seconds} ${ampm}`;
        return formattedDate;
    }

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper" style={{paddingTop:'40px'}}>
                {/* Sidebar */}
                <Sidebar />
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">View Client</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-outline-primary btn-icon-text" onClick={() => navigateToEditUser(newUser)} style={{ marginRight: '10px' }}><i className="mdi mdi-pencil btn-icon-prepend"></i>Edit</button>
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
                                                    <div className="col-12 col-xl-12">
                                                        <div style={{textAlign:'center'}}>
                                                            <h4 className="card-title" style={{paddingTop:'10px'}}>Client User Details</h4>
                                                            <hr></hr>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Client Name: <span style={{ fontWeight: 'normal' }}>{newUser.client_name ? newUser.client_name : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Phone Number:  <span style={{ fontWeight: 'normal' }}>{newUser.client_phone_no ? newUser.client_phone_no : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Email ID: <span style={{ fontWeight: 'normal' }}>{newUser.client_email_id ? newUser.client_email_id : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Client Wallet: <span style={{ fontWeight: 'normal' }}>{newUser.client_waller ? newUser.client_waller : '0'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Address: <span style={{ fontWeight: 'normal' }}>{newUser.client_address ? newUser.client_address : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Created By: <span style={{ fontWeight: 'normal' }}>{newUser.created_by ? newUser.created_by : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Created Date: <span style={{ fontWeight: 'normal' }}>{newUser.created_date ? formatTimestamp(newUser.created_date) : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Modified By: <span style={{ fontWeight: 'normal' }}>{newUser.modified_by ? newUser.modified_by : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Modified Date: <span style={{ fontWeight: 'normal' }}>{newUser.modified_date ? formatTimestamp(newUser.modified_date) : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Status: <span style={{fontWeight:'normal'}}>{newUser.status===true ? <span className="text-success">Active</span> : <span className="text-danger">DeActive</span>}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
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

export default ViewClient;
