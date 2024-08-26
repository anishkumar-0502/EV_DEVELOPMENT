import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import axios from 'axios';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Sidebar from '../../components/Sidebar';
import Swal from 'sweetalert2';

const EditFinance = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const dataItems = location.state?.newfinance || JSON.parse(localStorage.getItem('editDeviceData'));
    localStorage.setItem('editDeviceData', JSON.stringify(dataItems));
    
    const [eb_charges, setEbCharges] = useState(dataItems?.eb_charges || '');
    const [app_charges, setAppCharges] = useState(dataItems?.app_charges || '');
    const [other_charges, setOtherCharges] = useState(dataItems?.other_charges || '');
    const [parking_charges, setParkingCharges] = useState(dataItems?.parking_charges || '');
    const [rent_charges, setRentCharges] = useState(dataItems?.rent_charges || '');
    const [open_a_eb_charges, setOpenAebCharges] = useState(dataItems?.open_a_eb_charges || '');
    const [open_other_charges, setOpenOtherCharges] = useState(dataItems?.open_other_charges || '');
    const [status, setStatus] = useState(dataItems?.status ? 'true' : 'false');
    const [isEdited, setIsEdited] = useState(false); // Track if any input is edited

    // Input validation function
    const validateInput = (value) => {
        // Allow only numbers and a single decimal point
        value = value.replace(/[^0-9.]/g, '');
        const parts = value.split('.');
        if (parts.length > 2) {
            value = parts[0] + '.' + parts[1];
        }

        // Limit the length to 6 characters
        if (value.length > 6) {
            value = value.slice(0, 6);
        }

        return value;
    };

    // Handle change and validation for all fields
    const handleInputChange = (setter) => (e) => {
        let value = validateInput(e.target.value);
        setter(value);
        setIsEdited(true); // Mark as edited
    };

    // Select status
    const handleStatusChange = (e) => {
        setStatus(e.target.value);
        setIsEdited(true); // Mark as edited
    };

    // Update finance details
    const updateFinanceDetails = async (e) => {
        e.preventDefault();

        try {
            const formattedFinanceData = {
                finance_id: dataItems.finance_id,
                client_id: dataItems.client_id,
                eb_charges: eb_charges,
                app_charges: app_charges,
                other_charges: other_charges,
                parking_charges: parking_charges,
                rent_charges: rent_charges,
                open_a_eb_charges: open_a_eb_charges,
                open_other_charges: open_other_charges,
                modified_by: userInfo.data.email_id,
                status: status === 'true',
            };
    
            const response = await axios.post(`/clientadmin/UpdateFinanceDetails`, formattedFinanceData);
            if (response.data.status === 'Success') {
                Swal.fire({
                    position: "center",
                    icon: "success",
                    title: "Finance details updated successfully",
                    showConfirmButton: false,
                    timer: 1500
                });
                navigate('/clientadmin/ManageFinance');
            } else {
                Swal.fire({
                    icon: 'error',
                    title: 'Error updating finance details',
                    text: response.data.message,
                    timer: 2000,
                    timerProgressBar: true
                });
            }
        } catch (error) {
            console.error('Error updating finance details:', error);
            Swal.fire({
                icon: 'error',
                title: 'Error updating finance details',
                text: 'Please try again later.',
                timer: 2000,
                timerProgressBar: true
            });
        }
    };
    
    // Back page
    const goBack = () => {
        navigate(-1);
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
                                        <h3 className="font-weight-bold">Edit Finance Details</h3>
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
                                                    <h4 className="card-title">Update Finance Details</h4>
                                                    <form className="form-sample" onSubmit={updateFinanceDetails}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">EB Charges</label>
                                                                    <div className="col-sm-5">
                                                                        <div className="input-group">
                                                                            <div className="input-group-prepend">
                                                                                <span className="input-group-text">₹</span>
                                                                            </div>
                                                                            <input
                                                                                type="text"
                                                                                className="form-control"
                                                                                name="eb_charges"
                                                                                maxLength={6}
                                                                                value={eb_charges}
                                                                                onChange={handleInputChange(setEbCharges)}
                                                                                required
                                                                            />
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">App Charges</label>
                                                                    <div className="col-sm-5">
                                                                        <div className="input-group">
                                                                            <div className="input-group-prepend">
                                                                                <span className="input-group-text">%</span>
                                                                            </div>
                                                                            <input
                                                                                type="text"
                                                                                className="form-control"
                                                                                name="app_charges"
                                                                                maxLength={6}
                                                                                value={app_charges}
                                                                                onChange={handleInputChange(setAppCharges)}
                                                                                required
                                                                            />
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Other Charges</label>
                                                                    <div className="col-sm-5">
                                                                        <div className="input-group">
                                                                            <div className="input-group-prepend">
                                                                                <span className="input-group-text">%</span>
                                                                            </div>
                                                                            <input
                                                                                type="text"
                                                                                className="form-control"
                                                                                name="other_charges"
                                                                                maxLength={6}
                                                                                value={other_charges}
                                                                                onChange={handleInputChange(setOtherCharges)}
                                                                                required
                                                                            />
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Parking Charges</label>
                                                                    <div className="col-sm-5">
                                                                        <div className="input-group">
                                                                            <div className="input-group-prepend">
                                                                                <span className="input-group-text">%</span>
                                                                            </div>
                                                                            <input
                                                                                type="text"
                                                                                className="form-control"
                                                                                name="parking_charges"
                                                                                maxLength={6}
                                                                                value={parking_charges}
                                                                                onChange={handleInputChange(setParkingCharges)}
                                                                                required
                                                                            />
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Rent Charges</label>
                                                                    <div className="col-sm-5">
                                                                        <div className="input-group">
                                                                            <div className="input-group-prepend">
                                                                                <span className="input-group-text">%</span>
                                                                            </div>
                                                                            <input
                                                                                type="text"
                                                                                className="form-control"
                                                                                name="rent_charges"
                                                                                maxLength={6}
                                                                                value={rent_charges}
                                                                                onChange={handleInputChange(setRentCharges)}
                                                                                required
                                                                            />
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Open A EB Charges</label>
                                                                    <div className="col-sm-5">
                                                                        <div className="input-group">
                                                                            <div className="input-group-prepend">
                                                                                <span className="input-group-text">%</span>
                                                                            </div>
                                                                            <input
                                                                                type="text"
                                                                                className="form-control"
                                                                                name="open_a_eb_charges"
                                                                                maxLength={6}
                                                                                value={open_a_eb_charges}
                                                                                onChange={handleInputChange(setOpenAebCharges)}
                                                                                required
                                                                            />
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Open Other Charges</label>
                                                                    <div className="col-sm-5">
                                                                        <div className="input-group">
                                                                            <div className="input-group-prepend">
                                                                                <span className="input-group-text">%</span>
                                                                            </div>
                                                                            <input
                                                                                type="text"
                                                                                className="form-control"
                                                                                name="open_other_charges"
                                                                                maxLength={6}
                                                                                value={open_other_charges}
                                                                                onChange={handleInputChange(setOpenOtherCharges)}
                                                                                required
                                                                            />
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Status</label>
                                                                    <div className="col-sm-5">
                                                                        <select className="form-control" value={status} onChange={handleStatusChange} required>
                                                                            <option value="true">Active</option>
                                                                            <option value="false">DeActive</option>
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div style={{ textAlign: 'center' }}>
                                                            <button type="submit" className="btn btn-primary mr-2" disabled={!isEdited}>Update</button>
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

export default EditFinance;
