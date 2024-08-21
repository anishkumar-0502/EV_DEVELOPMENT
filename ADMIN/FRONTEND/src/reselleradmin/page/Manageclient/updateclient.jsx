import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import axios from 'axios';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Sidebar from '../../components/Sidebar';
import Swal from 'sweetalert2';

const UpdateClient = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const dataItems = location.state?.newUser || JSON.parse(localStorage.getItem('editDeviceData'));
    localStorage.setItem('editDeviceData', JSON.stringify(dataItems));
    const [client_name, setClientName] = useState(dataItems?.client_name || '');
    const [client_phone_no, setClientPhoneNo] = useState(dataItems?.client_phone_no || '');
    const [client_address, setClientAddress] = useState(dataItems?.client_address || '');
    const [client_wallet, setClientWallet] = useState(dataItems?.client_wallet || '0');
    const [status, setStatus] = useState(dataItems?.status ? 'true' : 'false');
    const [errorMessage, setErrorMessage] = useState('');

    // Store initial values
    const [initialValues, setInitialValues] = useState({
        client_name: dataItems?.client_name || '',
        client_phone_no: dataItems?.client_phone_no || '',
        client_wallet: dataItems?.client_wallet || '',
        client_address: dataItems?.client_address || '',
        status: dataItems?.status ? 'true' : 'false',
    });

    // Check if any field has been modified
    const isModified = (
        client_name !== initialValues.client_name ||
        client_phone_no !== initialValues.client_phone_no ||
        client_wallet !== initialValues.client_wallet ||
        client_address !== initialValues.client_address ||
        status !== initialValues.status
    );

    // Select status
    const handleStatusChange = (e) => {
        setStatus(e.target.value);
    };

    // update client
    const updateClientUser = async (e) => {
        e.preventDefault();

        // Phone number validation
        const phoneRegex = /^\d{10}$/;
        if (!client_phone_no || !phoneRegex.test(client_phone_no)) {
            setErrorMessage('Phone number must be a 10-digit number.');
            return;
        }

        try {
            const formattedUserData = {
                client_id: dataItems?.client_id,
                client_name: client_name,
                client_wallet,
                client_phone_no: parseInt(client_phone_no),
                client_address: client_address,
                modified_by: userInfo.data.email_id,
                status: status === 'true',
            };

            // Send POST request to update client
        const response = await axios.post(`/reselleradmin/updateClient/`, formattedUserData);

        // Check response status and handle accordingly
        if (response.status === 200) {
            Swal.fire({
                position: "center",
                icon: "success",
                title: "Client updated successfully",
                showConfirmButton: false,
                timer: 1500
            });
            navigate('/reselleradmin/ManageClient');
        } else {
            const responseData = await response.json();
                // Handle other status codes
                Swal.fire({
                    position: "center",
                    icon: "Error",
                    title: "Failed to update client. Please try again, " + responseData.message,
                    showConfirmButton: false,
                    timer: 1500
                });
            }
        } catch (error) {
            console.error('Error updating client:', error);
            if (error.response && error.response.data && error.response.data.message) {
                setErrorMessage('Error updating client: ' + error.response.data.message);
            } else {
                setErrorMessage('Failed to update client. Please try again.');
            }
        }
    };

    // back manageclient page 
    const goBack = () => {
        navigate('/reselleradmin/ManageClient');
    };

    useEffect(() => {
        // Update initial values if dataItems changes
        setInitialValues({
            client_name: dataItems?.client_name || '',
            client_phone_no: dataItems?.client_phone_no || '',
            client_address: dataItems?.client_address || '',
            status: dataItems?.status ? 'true' : 'false',
        });
    }, [dataItems]);

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
                                        <h3 className="font-weight-bold">Edit Client</h3>
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
                                        <div className="col-12 grid-margin">
                                            <div className="card">
                                                <div className="card-body">
                                                    <h4 className="card-title">Update Client</h4>
                                                    <form className="form-sample" onSubmit={updateClientUser}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Client Name</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            value={client_name}
                                                                            maxLength={25}
                                                                            onChange={(e) => {
                                                                                const sanitizedValue = e.target.value.replace(/[^a-zA-Z0-9 ]/g, '');
                                                                                setClientName(sanitizedValue.slice(0, 25));
                                                                            }}
                                                                            readOnly
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Phone No</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            value={client_phone_no}
                                                                            maxLength={10}
                                                                            onChange={(e) => {
                                                                                const sanitizedValue = e.target.value.replace(/[^0-9]/g, '');
                                                                                setClientPhoneNo(sanitizedValue.slice(0, 10));
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
                                                                            value={dataItems.client_email_id}
                                                                            readOnly
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Wallet</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            value={client_wallet}
                                                                            onChange={(e) => {
                                                                                const value = e.target.value;
                                                                                const sanitizedValue = value.replace(/[^0-9]/g, '');
                                                                                setClientWallet(sanitizedValue);}} required  />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Address</label>
                                                                    <div className="col-sm-9">
                                                                        <textarea
                                                                            type="text"
                                                                            className="form-control"
                                                                            maxLength={150}
                                                                            value={client_address}
                                                                            onChange={(e) => setClientAddress(e.target.value)}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Status</label>
                                                                    <div className="col-sm-9">
                                                                    <select
                                                                            className="form-control"
                                                                            value={status}
                                                                            onChange={handleStatusChange}
                                                                            required
                                                                            style={{ color: "black" }}
                                                                        >
                                                                            <option value="true">Active</option>
                                                                            <option value="false">DeActive</option>
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}
                                                        <div style={{ textAlign: 'center' }}>
                                                            <button type="submit" className="btn btn-primary mr-2" disabled={!isModified}>Update</button>
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

export default UpdateClient;
