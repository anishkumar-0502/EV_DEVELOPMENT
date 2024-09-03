import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import axios from 'axios';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Sidebar from '../../components/Sidebar';
import Swal from 'sweetalert2';

const Editass = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const dataItems = location.state?.newass || JSON.parse(localStorage.getItem('editDeviceData'));
    localStorage.setItem('editDeviceData', JSON.stringify(dataItems));
    const [association_name, setAssociationName] = useState(dataItems?.association_name || '');
    const [association_phone_no, setAssociationPhoneNo] = useState(dataItems?.association_phone_no || '');
    const [association_wallet, setAssociationWallet] = useState(dataItems?.association_wallet || '0');
    const [association_address, setAssociationAddress] = useState(dataItems?.association_address || '');
    const [status, setStatus] = useState(dataItems?.status ? 'true' : 'false');
    const [errorMessage, setErrorMessage] = useState('');

    // Store initial values
    const [initialValues, setInitialValues] = useState({
        association_phone_no: dataItems?.association_phone_no || '',
        association_wallet: dataItems?.association_wallet || '0',
        association_address: dataItems?.association_address || '',
        status: dataItems?.status ? 'true' : 'false'
    });

    // Check if any field has been modified
    const isModified = (
        association_phone_no !== initialValues.association_phone_no ||
        association_wallet !== initialValues.association_wallet ||
        association_address !== initialValues.association_address ||
        status !== initialValues.status
    );

    // Select status
    const handleStatusChange = (e) => {
        setStatus(e.target.value);
    };

    // update association details
    const updateAssociationDetails = async (e) => {
        e.preventDefault();
        // Phone number validation
        const phoneRegex = /^\d{10}$/;
        if (!association_phone_no || !phoneRegex.test(association_phone_no)) {
            setErrorMessage('Phone number must be a 10-digit number.');
            return;
        }
        try {
            const formattedAssData = {
                association_address: association_address,
                association_email_id: dataItems.association_email_id,
                association_wallet,
                association_id: dataItems.association_id,
                association_name: association_name,
                association_phone_no: parseInt(association_phone_no),
                modified_by:userInfo.data.email_id,
                status: status === 'true',
            };

            const response = await axios.post(`/clientadmin/UpdateAssociationUser`, formattedAssData);
            if (response.data.status === 'Success') {
                Swal.fire({
                    position: "center",
                    icon: "success",
                    title: "Association details updated successfully",
                    showConfirmButton: false,
                    timer: 1500
                });
                editBack();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    icon: 'error',
                    title: 'Error updating association details',
                    text: 'Please try again later. ' +responseData.message,
                    timer: 2000,
                    timerProgressBar: true
                });
            }
        } catch (error) {
            console.error('Error updating association details:', error);
            Swal.fire({
                icon: 'error',
                title: 'Error updating association details',
                text: 'Please try again later.',
                timer: 2000,
                timerProgressBar: true
            });
        }
    };

    // back page
    const goBack = () => {
        navigate(-1);
    };

    // view manage association details 
    const editBack = () => {
        navigate('/clientadmin/ManageAssociation')  
    };

    useEffect(() => {
        // Update initial values if dataItems changes
        setInitialValues({
            association_phone_no: dataItems?.association_phone_no || '',
            association_wallet: dataItems?.association_wallet || '0',
            association_address: dataItems?.association_address || '',
            status: dataItems?.status ? 'true' : 'false'
        });
    }, [dataItems]);

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
                                        <h3 className="font-weight-bold">Edit Association Details</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button
                                                type="button"
                                                className="btn btn-success"
                                                onClick={goBack}
                                                style={{ marginRight: '10px' }}
                                            >
                                                Back
                                            </button>
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
                                                    <h4 className="card-title">Update Association Details</h4>
                                                    <form className="form-sample" onSubmit={updateAssociationDetails}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Association  Name</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            value={association_name}
                                                                            maxLength={25}
                                                                            onChange={(e) => {
                                                                                const sanitizedValue = e.target.value.replace(/[^a-zA-Z0-9 ]/g, '');
                                                                                setAssociationName(sanitizedValue.slice(0, 25));
                                                                            }}
                                                                            readOnly
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            {/* <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Association ID</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            value={dataItems.association_id}
                                                                            readOnly
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div> */}
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Association Phone</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            value={association_phone_no}
                                                                            maxLength={10}
                                                                            onChange={(e) => {
                                                                                const sanitizedValue = e.target.value.replace(/[^0-9]/g, '');
                                                                                setAssociationPhoneNo(sanitizedValue.slice(0, 10));
                                                                            }}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Association Email</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="email"
                                                                            className="form-control"
                                                                            value={dataItems.association_email_id}
                                                                            readOnly
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Association Wallet</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            value={association_wallet}
                                                                            onChange={(e) => {
                                                                                let value = e.target.value;
                                                                                
                                                                                // Allow only numbers and a single decimal point
                                                                                value = value.replace(/[^0-9.]/g, '');
                                                                                
                                                                                const parts = value.split('.');
                                                                                
                                                                                // Ensure there's only one decimal point and limit to two decimal places
                                                                                if (parts.length > 2) {
                                                                                    value = parts[0] + '.' + parts[1];
                                                                                } else if (parts.length === 2 && parts[1].length > 2) {
                                                                                    value = parts[0] + '.' + parts[1].slice(0, 2);
                                                                                }
                                                                                
                                                                                // Limit the length to 8 characters
                                                                                if (value.length > 8) {
                                                                                    value = value.slice(0, 8);
                                                                                }
                                                                                
                                                                                // Convert to float and validate range
                                                                                const numericValue = parseFloat(value);
                                                                                if (numericValue < 1 || numericValue > 99999) {
                                                                                    setErrorMessage('Please enter a wallet between 1.00 ₹ and 99999.00 ₹.');
                                                                                } else {
                                                                                    setErrorMessage(''); // Clear error if within range
                                                                                }
                                                                                
                                                                                setAssociationWallet(value);
                                                                            }}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Association  Address</label>
                                                                    <div className="col-sm-9">
                                                                        <textarea
                                                                            type="text"
                                                                            className="form-control"
                                                                            maxLength={150}
                                                                            value={association_address}
                                                                            onChange={(e) => setAssociationAddress(e.target.value)}
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
                                                                            required>
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

export default Editass;
