import React, { useState } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';

const CreateClients = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const [newUser, setNewUser] = useState({ "client_name": '', "client_phone_no": '', "client_email_id": '', "client_address": '' });
    const [errorMessage, setErrorMessage] = useState('');
   
    // back manage cllient
    const Goback = () => {
        navigate('/reselleradmin/ManageClient');
    };

    // Add client user
    const addClientUser = async (e) => {
        e.preventDefault();

        // Phone number validation regex
        const phoneRegex = /^\d{10}$/;
        if (!newUser.client_phone_no || !phoneRegex.test(newUser.client_phone_no)) {
            setErrorMessage('Phone number must be a 10-digit number.');
            return;
        }
        
        try {
            // Ensure that keys are explicitly set as strings
            const userData = {
                "reseller_id": userInfo.data.reseller_id, // Explicitly setting the empty key
                "client_name": newUser["client_name"],
                "client_phone_no": newUser["client_phone_no"],
                "client_email_id": newUser["client_email_id"],
                "client_address": newUser["client_address"],
                "created_by": userInfo.data.email_id
            };

            const response = await axios.post('/reselleradmin/addNewClient', userData);

            if (response.status === 200) {
                Swal.fire({
                    title: "Success!",
                    text: "User created successfully",
                    icon: "success"
                });
                setNewUser({ "client_name": '', "client_phone_no": '', "client_email_id": '', "client_address": '' });
                navigate('/reselleradmin/ManageClient');
            } else {
                const responseData = await response.json();
                setErrorMessage('Failed to add user, ' + responseData.message);
            }
        } catch (error) {
            if (error.response && error.response.data && error.response.data.message) {
                setErrorMessage('Failed to create user, ' + error.response.data.message);
            } else {
                console.error('Error creating user:', error);
                setErrorMessage('Failed to create user. Please try again.');
            }
        }
    };

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
                                        <h3 className="font-weight-bold">Manage Clients</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={Goback}>Back</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div className="col-12 grid-margin">
                                            <div className="card">
                                                <div className="card-body">
                                                    <h4 className="card-title">Create Client Users</h4>
                                                    <form className="form-sample" onSubmit={addClientUser}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Name</label>
                                                                    <div className="col-sm-9">
                                                                    <input type="text" className="form-control" placeholder="Name" value={newUser.client_name} maxLength={25}
    onChange={(e) => {
        const sanitizedValue = e.target.value.replace(/[^a-zA-Z0-9\s]/g, '');
        setNewUser({ ...newUser, client_name: sanitizedValue }); }} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Phone No</label>
                                                                    <div className="col-sm-9">
                                                                    <input type="text" className="form-control" placeholder="Phone No" value={newUser.client_phone_no} maxLength={10}
    onChange={(e) => {
        const sanitizedValue = e.target.value.replace(/[^0-9]/g, '');
        setNewUser({ ...newUser, client_phone_no: sanitizedValue });
    }} 
    required 
/>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Email ID</label>
                                                                    <div className="col-sm-9">
                                                                    <input 
    type="email" 
    className="form-control" 
    placeholder="Email ID" 
    value={newUser.client_email_id} 
    onChange={(e) => {
        const inputValue = e.target.value;
        const sanitizedEmail = inputValue
            .replace(/\s/g, '') // Remove whitespace
            .replace(/[^a-zA-Z0-9@.]/g, '') // Remove non-alphanumeric characters except @ and .
            .replace(/@.*@/, '@'); // Ensure there's at most one @ character
        setNewUser({ ...newUser, client_email_id: sanitizedEmail });
    }} 
    required 
/>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Address</label>
                                                                    <div className="col-sm-9">
                                                                        <textarea type="text" className="form-control" placeholder="Address" maxLength={150} value={newUser.client_address} onChange={(e) => setNewUser({ ...newUser, "client_address": e.target.value })} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}
                                                        <div style={{ textAlign: 'center' }}>
                                                            <button type="submit" className="btn btn-primary mr-2">Create</button>
                                                        </div>
                                                    </form>
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

export default CreateClients;
