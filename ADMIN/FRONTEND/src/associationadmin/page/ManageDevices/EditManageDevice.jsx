import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import Swal from 'sweetalert2';

const EditManageDevice = ({ userInfo, handleLogout }) => {
    const location = useLocation();
    const dataItem = location.state?.deviceData || JSON.parse(localStorage.getItem('editDeviceData'));
    localStorage.setItem('editDeviceData', JSON.stringify(dataItem));
    const navigate = useNavigate();
    
    const [latitude, setLatitude] = useState(dataItem?.lat || '');
    const [longitude, setLongitude] = useState(dataItem.long || '');
    const [landmark, setlandmark] = useState(dataItem?.landmark || '');
    const [wifiUsername, setWifiUsername] = useState(dataItem.wifi_username || '');
    const [wifiPassword, setWifiPassword] = useState(dataItem.wifi_password || '');
    const [selectStatus, setSelectedStatus] = useState(dataItem?.charger_accessibility || '');

    // Store initial values
    const [initialValues, setInitialValues] = useState({
        lat: dataItem?.lat || '',
        long: dataItem.long || '',
        landmark: dataItem.landmark || '',
        wifi_username: dataItem.wifi_username || '',
        wifi_password: dataItem.wifi_password || '',
        charger_accessibility: dataItem?.charger_accessibility || ''
    });

    // Check if any field has been modified
    const isModified = (
        latitude !== initialValues.lat ||
        longitude !== initialValues.long ||
        landmark !== initialValues.landmark ||
        wifiUsername !== initialValues.wifi_username ||
        wifiPassword !== initialValues.wifi_password ||
        selectStatus !== initialValues.charger_accessibility
    );

    // Selected status
    const handleStatusChange = (e) => {
        setSelectedStatus(e.target.value);
    };

    // Back view manage device
    const backManageDevice = () => {
        navigate('/associationadmin/ViewManageDevice');
    };

    // Back manage device
    const editBackManageDevice = () => {
        navigate('/associationadmin/ManageDevice');
    };

    // Update manage device
    const editManageDevice = async (e) => {
        e.preventDefault();
        try {
            const Status = parseInt(selectStatus);
            const response = await fetch('/associationadmin/UpdateDevice', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    charger_id: dataItem.charger_id,
                    charger_accessibility: Status,
                    lat: latitude,
                    long: longitude,
                    landmark,
                    wifi_username: wifiUsername,
                    wifi_password: wifiPassword,
                    modified_by: userInfo.data.email_id
                }),
            });

            if (response.ok) {
                Swal.fire({
                    title: "Device updated successfully",
                    icon: "success"
                });
                setLatitude('');
                setLongitude('');
                setWifiUsername('');
                setWifiPassword('');
                editBackManageDevice();
                setlandmark('');
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to update device, " + responseData.message,
                    icon: "error"
                });
            }
        } catch (error) {
            Swal.fire({
                title: "Error",
                text: "An error occurred while updating the device",
                icon: "error"
            });
        }
    };

    useEffect(() => {
        // Update initial values if dataItem changes
        setInitialValues({
            lat: dataItem?.lat || '',
            long: dataItem.long || '',
            landmark: dataItem.landmark || '',
            wifi_username: dataItem.wifi_username || '',
            wifi_password: dataItem.wifi_password || '',
            charger_accessibility: dataItem?.charger_accessibility || ''
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
                                        <h3 className="font-weight-bold">Edit Manage Device</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={backManageDevice}>Back</button>
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
                                                    <h4 className="card-title">Manage Device</h4>
                                                    <form className="form-sample" onSubmit={editManageDevice}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Charger Accessibility</label>
                                                                    <div className="col-sm-12">
                                                                        <select className="form-control" value={selectStatus} onChange={handleStatusChange} required>
                                                                            <option value="1">Public</option>
                                                                            <option value="2">Private</option>
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Latitude</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="text" className="form-control" value={latitude} maxLength={10} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^0-9.-]/g, ''); setLatitude(sanitizedValue); }} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Longitude</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="text" className="form-control" value={longitude} maxLength={11} onChange={(e) => { const value = e.target.value; const sanitizedValue = value.replace(/[^0-9.-]/g, ''); setLongitude(sanitizedValue); }} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Land Mark</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="text" className="form-control" value={landmark} maxLength={12} onChange={(e) => setlandmark(e.target.value)} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Wifi Username</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="text" className="form-control" value={wifiUsername} maxLength={25} onChange={(e) => setWifiUsername(e.target.value)} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-12 col-form-label labelInput">Wifi Password</label>
                                                                    <div className="col-sm-12">
                                                                        <input type="text" className="form-control" value={wifiPassword} maxLength={15} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/\s/g, ''); setWifiPassword(sanitizedValue); }} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div style={{ textAlign: 'center', padding:'15px'}}>
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

export default EditManageDevice;
