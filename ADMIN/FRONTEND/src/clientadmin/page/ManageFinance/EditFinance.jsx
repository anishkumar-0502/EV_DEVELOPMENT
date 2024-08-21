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
    const [errorMessage, setErrorMessage] = useState('');

    // Select status
    const handleStatusChange = (e) => {
        setStatus(e.target.value);
    };

    // update finance details
    const updateFinanceDetails = async (e) => {
        e.preventDefault();

        // Eb Charges validation
        const ebChargesRegex = /^\d+$/;
        if (!ebChargesRegex.test(eb_charges.trim())) {
            setErrorMessage('Eb charges must be a number.');
            return;
        }

        try {
            const formattedFinanceData = {
                finance_id: dataItems.finance_id,
                association_id: dataItems.association_id,
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
                navigate('/clientadmin/ViewFinance');
            } else {
                const responseData = await response.json();
                Swal.fire({
                    icon: 'error',
                    title: 'Error updating finance details, ' + responseData.message,
                    text: 'Please try again later.',
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
    
    // back page
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
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            name="eb_charges"
                                                                            value={eb_charges}
                                                                            onChange={(e) => setEbCharges(e.target.value)}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">App Charges</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            name="app_charges"
                                                                            value={app_charges}
                                                                            onChange={(e) => setAppCharges(e.target.value)}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Other Charges</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            name="other_charges"
                                                                            value={other_charges}
                                                                            onChange={(e) => setOtherCharges(e.target.value)}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Parking Charges</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            name="parking_charges"
                                                                            value={parking_charges}
                                                                            onChange={(e) => setParkingCharges(e.target.value)}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Rent Charges</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            name="rent_charges"
                                                                            value={rent_charges}
                                                                            onChange={(e) => setRentCharges(e.target.value)}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Open A EB Charges</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            name="open_a_eb_charges"
                                                                            value={open_a_eb_charges}
                                                                            onChange={(e) => setOpenAebCharges(e.target.value)}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Open Other Charges</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            name="open_other_charges"
                                                                            value={open_other_charges}
                                                                            onChange={(e) => setOpenOtherCharges(e.target.value)}
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
                                                            <button type="submit" className="btn btn-primary mr-2">Update</button>
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
