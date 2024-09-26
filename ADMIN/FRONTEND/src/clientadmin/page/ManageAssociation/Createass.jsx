import React, { useState } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';

const Createass = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const [newUser, setNewUser] = useState({ "association_name": '', "association_phone_no": '', "association_email_id": '', "association_address": '' });
    const [errorMessage, setErrorMessage] = useState('');
  
    // back manage association page
    const Goback = () => {
        navigate('/clientadmin/ManageAssociation');
    };

    // add client user
    const addClientUser = async (e) => {
        e.preventDefault();

        // Phone number validation regex
        const phoneRegex = /^\d{10}$/;
        if (!newUser.association_phone_no || !phoneRegex.test(newUser.association_phone_no)) {
            setErrorMessage('Phone number must be a 10-digit number.');
            return;
        }
        
        try {
            // Ensure that keys are explicitly set as strings
            const newAssociation = {
                "reseller_id": userInfo.data.reseller_id, // Explicitly setting the empty key
                "client_id": userInfo.data.client_id,
                "association_name": newUser["association_name"],
                "association_phone_no": newUser["association_phone_no"],
                "association_email_id": newUser["association_email_id"],
                "association_address": newUser["association_address"],
                "created_by": userInfo.data.email_id,
            };

            const response = await axios.post('/clientadmin/CreateAssociationUser', newAssociation);

            if (response.status === 200) {
                Swal.fire({
                    title: "Success!",
                    text: "User created successfully",
                    icon: "success"
                });
                setNewUser({ "client_name": '', "client_phone_no": '', "client_email_id": '', "client_address": '' });
                navigate('/clientadmin/ManageAssociation');
            } else {
                const responseData = await response.json();
                setErrorMessage('Failed to create user, ' + responseData.message);
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
                                        <h3 className="font-weight-bold">Create Association</h3>
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
                                                    <h4 className="card-title">Association Details</h4>
                                                    <form className="form-sample" onSubmit={addClientUser}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Association Name</label>
                                                                    <div className="col-sm-12">
                                                                    <input 
                                                                        type="text" 
                                                                        className="form-control" 
                                                                        placeholder="Association Name" 
                                                                        value={newUser.association_name} 
                                                                        maxLength={25}
                                                                        onChange={(e) => {
                                                                            const sanitizedValue = e.target.value.replace(/[^a-zA-Z0-9\s]/g, '');
                                                                            setNewUser({ ...newUser, association_name: sanitizedValue });
                                                                        }} 
                                                                        required 
                                                                    />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Phone No</label>
                                                                    <div className="col-sm-12">
                                                                    <input 
                                                                        type="text" 
                                                                        className="form-control" 
                                                                        placeholder="Phone No" 
                                                                        value={newUser.association_phone_no} 
                                                                        maxLength={10}
                                                                        onChange={(e) => {
                                                                            const sanitizedValue = e.target.value.replace(/[^0-9]/g, '');
                                                                            setNewUser({ ...newUser, association_phone_no: sanitizedValue });
                                                                        }} 
                                                                        required 
                                                                    />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Email ID</label>
                                                                    <div className="col-sm-12">
                                                                    <input 
                                                                        type="email" 
                                                                        className="form-control" 
                                                                        placeholder="Email ID" 
                                                                        value={newUser.association_email_id} 
                                                                        onChange={(e) => {
                                                                            const value = e.target.value;
                                                                            // Remove spaces and invalid characters
                                                                            const noSpaces = value.replace(/\s/g, '');
                                                                            const validChars = noSpaces.replace(/[^a-zA-Z0-9@.]/g, '');
                                                                            // Convert to lowercase
                                                                            const lowerCaseEmail = validChars.toLowerCase();
                                                                            // Handle multiple @ symbols
                                                                            const atCount = (lowerCaseEmail.match(/@/g) || []).length;
                                                                            const sanitizedEmail = atCount <= 1 ? lowerCaseEmail : lowerCaseEmail.replace(/@.*@/, '@');
                                                                            // Set the sanitized and lowercase email
                                                                            setNewUser({ ...newUser, association_email_id: sanitizedEmail });
                                                                        }} 
                                                                        required 
                                                                    />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Address</label>
                                                                    <div className="col-sm-12">
                                                                        <textarea type="text" className="form-control" placeholder="Address" maxLength={150} value={newUser.association_address} onChange={(e) => setNewUser({ ...newUser, "association_address": e.target.value })} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}
                                                        <div style={{ textAlign: 'center', padding:'15px' }}>
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

export default Createass;
