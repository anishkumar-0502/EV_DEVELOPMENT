import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import Swal from 'sweetalert2';

const EditManageReseller = ({ userInfo, handleLogout }) => {
    const location = useLocation();
    const navigate = useNavigate();
    const dataItem = location.state?.newUser || JSON.parse(localStorage.getItem('editDeviceData'));
    localStorage.setItem('editDeviceData', JSON.stringify(dataItem));
    
    const [errorMessage, setErrorMessage] = useState('');
    const [selectStatus, setSelectedStatus] = useState(dataItem?.status ? 'true' : 'false');

    // Edit manage device
    const [reseller_name, setResellerName] = useState(dataItem?.reseller_name || '');
    const [reseller_phone_no, setResellerPhoneNumber] = useState(dataItem?.reseller_phone_no || '');
    const [reseller_email_id, setEmilaID] = useState(dataItem?.reseller_email_id || '');
    const [reseller_address, setResellerAddress] = useState(dataItem?.reseller_address || '');
    const [reseller_wallet, setResellerWallet] = useState(dataItem?.reseller_wallet || '0');
     // Store initial values
     const [initialValues, setInitialValues] = useState({
        reseller_phone_no: dataItem?.reseller_phone_no || '',
        reseller_wallet: dataItem?.reseller_wallet || '0',
        reseller_address: dataItem?.reseller_address || '',
        status: dataItem?.status ? 'true' : 'false',
    });

    // Check if any field has been modified
    const isModified = (
        reseller_phone_no !== initialValues.reseller_phone_no ||
        reseller_wallet !== initialValues.reseller_wallet ||
        reseller_address !== initialValues.reseller_address ||
        selectStatus !== initialValues.status
    );

    // Selected status
    const handleStatusChange = (e) => {
        setSelectedStatus(e.target.value);
    };

    // Back view manage reseller
    const backManageReseller = () => {
        navigate('/superadmin/ViewManageReseller');
    };

    // Edit back manage reseller
    const EditBackManageResellers = () => {
        navigate('/superadmin/ManageReseller');
    };

    // Update manage reseller
    const editManageReseller = async (e) => {
        e.preventDefault();

        // phone number validation
        const phoneRegex = /^\d{10}$/;
        if (!reseller_phone_no || !phoneRegex.test(reseller_phone_no)) {
            setErrorMessage('Phone number must be a 10-digit number.');
            return;
        }

        try {
            const reseller_phone_nos = parseInt(reseller_phone_no);

            const updatedReseller = {
                reseller_id: dataItem?.reseller_id,
                reseller_name:reseller_name,
                reseller_wallet,
                reseller_phone_no: reseller_phone_nos,
                status: selectStatus === 'true',
                reseller_address:reseller_address,
                modified_by: userInfo.data.email_id,
            };
            const response = await fetch('/superadmin/UpdateReseller', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(updatedReseller),
            });

            if (response.ok) {
                Swal.fire({
                    title: 'Reseller updated successfully',
                    icon: 'success',
                });
                EditBackManageResellers();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: 'Error',
                    text: 'Failed to update reseller, ' + responseData.message,
                    icon: 'error',
                });
            }
        } catch (error) {
            Swal.fire({
                title: 'Error',
                text: 'An error occurred while updating the reseller',
                icon: 'error',
            });
        }
    };

    useEffect(() => {
        // Update initial values if dataItem changes
        setInitialValues({
            reseller_phone_no: dataItem?.reseller_phone_no || '',
            reseller_address: dataItem?.reseller_address || '',
            reseller_wallet: dataItem?.reseller_wallet || '0',
            status: dataItem?.status ? 'true' : 'false',
        });
    }, [dataItem]);

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
                                        <h3 className="font-weight-bold">Edit Manage Reseller</h3>
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
                                        <div className="col-12 grid-margin">
                                            <div className="card">
                                                <div className="card-body">
                                                    <h4 className="card-title">Manage Reseller</h4>
                                                    <form className="form-sample" onSubmit={editManageReseller}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Reseller Name</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="text" className="form-control" value={reseller_name} onChange={(e) => setResellerName(e.target.value )}readOnly required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Phone Number</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="text" className="form-control" value={reseller_phone_no} maxLength={10} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^0-9]/g, ''); setResellerPhoneNumber(sanitizedValue);}} required/>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Email ID</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="email" className="form-control" value={reseller_email_id} onChange={(e) => setEmilaID(e.target.value )}readOnly required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Wallet</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="text"
                                                                            className="form-control"
                                                                            value={reseller_wallet}
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

                                                                                // If the value is within the range 1.00 to 99,999.00, set the value
                                                                                if (!isNaN(numericValue) && numericValue >= 1 && numericValue < 100000) {
                                                                                    setResellerWallet(value);
                                                                                    setErrorMessage(''); // Clear error if within range
                                                                                } else {
                                                                                    // If outside range, clear the input field and show an error message
                                                                                    setResellerWallet('');
                                                                                    setErrorMessage('Please enter a wallet amount between 1.00 ₹ and 99999.00 ₹.');
                                                                                }
                                                                            }}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="row">
                                                           <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Address</label>
                                                                    <div className="col-sm-12">
                                                                        <textarea type="text" className="form-control" value={reseller_address} maxLength={150} onChange={(e) => setResellerAddress(e.target.value )}required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Status</label>
                                                                    <div className="col-sm-12">
                                                                        <select className="form-control" value={selectStatus} onChange={handleStatusChange} required >
                                                                            <option value="true">Active</option>
                                                                            <option value="false">Deactive</option>
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}<br/>
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

export default EditManageReseller;
