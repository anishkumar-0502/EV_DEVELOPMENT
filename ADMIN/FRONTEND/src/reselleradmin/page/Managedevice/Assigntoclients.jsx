import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import Swal from 'sweetalert2';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../../components/Sidebar';
import Header from '../../components/Header';
import Footer from '../../components/Footer';

const Assigntoclients = ({ userInfo, handleLogout }) => {
    const [selectedClientId, setSelectedClientId] = useState('');
    const [selectedChargers, setSelectedChargers] = useState([]);
    const [commission, setCommission] = useState('0');
    const [reloadPage, setReloadPage] = useState(false); // State to trigger page reload
    const [chargersLoading, setChargersLoading] = useState(true); // State to manage loading state
    const [unallocatedChargers, setUnallocatedChargers] = useState([]);
    const [clientsList, setClientsList] = useState([]);
    const navigate = useNavigate();

    const fetchClientsCalled = useRef(false); 
    const fetchUnallocatedChargersCalled = useRef(false); 

    // fetch clientuser to assgin charger
    useEffect(() => {
        const fetchClients = async () => {
            try {
                const response = await axios.post('/reselleradmin/FetchClientUserToAssginCharger', {
                    reseller_id: userInfo.data.reseller_id
                });
                setClientsList(response.data.data || []);
            } catch (error) {
                console.error('Error fetching clients:', error);
                setClientsList([]);
            }
        };

        // fetch unallocated chargers
        const fetchUnallocatedChargers = async () => {
            try {
                const response = await axios.post('/reselleradmin/FetchUnAllocatedChargerToAssgin', {
                    reseller_id: userInfo.data.reseller_id,
                });
                setUnallocatedChargers(response.data.data || []);
            } catch (error) {
                console.error('Error fetching unallocated charger details:', error);
                setUnallocatedChargers([]);
            } finally {
                setChargersLoading(false);
            }
        };

        if (!fetchClientsCalled.current) {
            fetchClients();
            fetchClientsCalled.current = true;
        }

        if (!fetchUnallocatedChargersCalled.current) {
            fetchUnallocatedChargers();
            fetchUnallocatedChargersCalled.current = true;
        }
    }, [userInfo.data.reseller_id]); // Use userInfo.data.reseller_id as the dependency

    // client changes state
    const handleClientChange = (e) => {
        const selectedClientId = e.target.value;
        setSelectedClientId(selectedClientId);
    };

    const handleChargerChange = (chargerId, checked) => {
        if (checked) {
            setSelectedChargers(prevState => [...prevState, chargerId]);
        } else {
            setSelectedChargers(prevState => prevState.filter(id => id !== chargerId));
        }
    };

    // handle commission
    const [errorMessage, setErrorMessage] = useState('');

    const handleCommissionChange = (e, field) => {
        let value = e.target.value;
    
        // Allow only numbers and a single decimal point
        value = value.replace(/[^0-9.]/g, '');
    
        // Ensure there's only one decimal point and limit to two decimal places
        const parts = value.split('.');
        if (parts.length > 2) {
            value = parts[0] + '.' + parts[1];
        } else if (parts.length === 2 && parts[1].length > 2) {
            value = parts[0] + '.' + parts[1].slice(0, 2);
        }
    
        // Convert to float and validate range
        const numericValue = parseFloat(value);
        let errorMessage = '';
        if (numericValue < 0 || numericValue > 25) {
            errorMessage = 'Please enter a value between 0.00% and 25.00%.';
        }
    
        // Limit the length to 6 characters and apply validation
        if (value.length > 5) {
            value = value.slice(0, 5);
        }
    
        // Update the state based on validation
        if (!errorMessage) {
            setCommission(value);
        }
        setErrorMessage(errorMessage);
    };
    
    // submit data
    const handleSubmit = async (e) => {
        e.preventDefault();

        if (selectedChargers.length === 0) {
            Swal.fire({
                icon: 'warning',
                title: 'No Chargers Selected',
                text: 'Please select at least one charger.',
                timer: 2000,
                timerProgressBar: true
            });
            return;
        }

        // Confirm selected chargers
        Swal.fire({
            title: 'Confirm Selection',
            text: `You have selected chargers: ${selectedChargers.join(', ')}`,
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Confirm',
            cancelButtonText: 'Cancel'
        }).then((result) => {
            if (result.isConfirmed) {
                submitAssign();
            }
        });
    };

    // assign data submit
    const submitAssign = async () => {
        try {
            const response = await axios.post('/reselleradmin/AssginChargerToClient', {
                client_id: parseInt(selectedClientId),
                charger_id: selectedChargers,
                reseller_commission: commission,
                modified_by: userInfo.data.email_id,
            });

            if (response.data.status === 'Success') {
                Swal.fire({
                    icon: 'success',
                    title: 'Charger Assigned Successfully',
                    timer: 2000,
                    timerProgressBar: true,
                    onClose: () => {
                        setReloadPage(true); // Set reloadPage state to trigger page reload
                    }
                });
                navigate('/reselleradmin/Allocateddevice')
            } else {
                const responseData = await response.json();
                Swal.fire({
                    icon: 'error',
                    title: 'Charger Not Assigned, ' + responseData.messages,
                    text: 'Please try again.',
                    timer: 2000,
                    timerProgressBar: true
                });
            }
        } catch (error) {
            // Handle network errors or unexpected server responses
            if (error.response && error.response.data) {
                // Error response from server
                const errorMessage = error.response.data.message || 'An unknown error occurred.';
                Swal.fire({
                    icon: 'error',
                    title: 'Error assigning charger',
                    text: errorMessage,
                    timer: 2000,
                    timerProgressBar: true
                });
            } else {
                // Network or unexpected error
                Swal.fire({
                    icon: 'error',
                    title: 'Error assigning charger',
                    text: 'Please try again later.',
                    timer: 2000,
                    timerProgressBar: true
                });
            }
        }
    };

    useEffect(() => {
        if (reloadPage) {
            setReloadPage(false); // Reset reloadPage state
            window.location.reload(); // Reload the page after success
        }
    }, [reloadPage]);

    // back allocated device 
    const goBack = () => {
        navigate('/reselleradmin/Allocateddevice');
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
                                        <h3 className="font-weight-bold">Assign Chargers to Clients</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex"> 
                                            <button type="button" className="btn btn-success" onClick={goBack}style={{ marginRight: '10px' }}>Back</button>
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
                                                    <h2 className="card-title">Enter Details</h2>
                                                    <form onSubmit={handleSubmit} className="form-sample">
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Select Client</label>
                                                                    <div className="col-sm-9">
                                                                        <select
                                                                            className="form-control"
                                                                            value={selectedClientId}
                                                                            style={{color:'black'}}
                                                                            onChange={handleClientChange}
                                                                            required
                                                                        >
                                                                            <option value="">Select Client</option>
                                                                            {clientsList.length === 0 ? (
                                                                                <option disabled>No data found</option>
                                                                            ) : (
                                                                                clientsList.map((clientObj) => (
                                                                                    <option key={clientObj.client_id} value={clientObj.client_id}>
                                                                                        {clientObj.client_name}
                                                                                    </option>
                                                                                ))
                                                                            )}
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Commission</label>
                                                                    <div className="col-sm-9">
                                                                        <div className="input-group">
                                                                            <div className="input-group-prepend">
                                                                                <span className="input-group-text">%</span>
                                                                            </div>
                                                                            <input
                                                                                type="text"
                                                                                className="form-control"
                                                                                maxLength={5}
                                                                                value={commission}
                                                                                name="commission" // Add name attribute
                                                                                onChange={handleCommissionChange}
                                                                                required
                                                                            />
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Select Chargers</label>
                                                                    <div className="col-sm-9">
                                                                        {chargersLoading ? (
                                                                            <p>Loading chargers...</p>
                                                                        ) : (
                                                                            <div className="dropdown">
                                                                                <button
                                                                                    className="btn btn-secondary dropdown-toggle"
                                                                                    type="button"
                                                                                    id="dropdownMenuButton"
                                                                                    data-toggle="dropdown"
                                                                                    aria-haspopup="true"
                                                                                    aria-expanded="false"
                                                                                    style={{ backgroundColor: 'white', color: 'black' }}
                                                                                >
                                                                                    {unallocatedChargers.length > 0 ? (
                                                                                        selectedChargers.length > 0 ? `${selectedChargers.length} Chargers Selected` : 'Select Chargers'
                                                                                    ) : (
                                                                                        <span className="text-danger">No Chargers Available</span>
                                                                                    )}
                                                                                </button>
                                                                                <div className="dropdown-menu" aria-labelledby="dropdownMenuButton" style={{ maxHeight: '200px', overflowY: 'auto' }}>
                                                                                    {unallocatedChargers.length > 0 ? (
                                                                                        unallocatedChargers.map((chargerObj) => (
                                                                                            <div key={chargerObj.charger_id} className="dropdown-item">
                                                                                                <div className="form-check">
                                                                                                    <input
                                                                                                        className="form-check-input"
                                                                                                        type="checkbox"
                                                                                                        id={`charger-${chargerObj.charger_id}`}
                                                                                                        checked={selectedChargers.includes(chargerObj.charger_id)}
                                                                                                        onChange={(e) => handleChargerChange(chargerObj.charger_id, e.target.checked)}
                                                                                                        name={`charger_${chargerObj.charger_id}`} // Add name attribute

                                                                                                    />
                                                                                                    <label className="form-check-label" htmlFor={`charger-${chargerObj.charger_id}`}>
                                                                                                        {chargerObj.charger_id}
                                                                                                    </label>
                                                                                                </div>
                                                                                            </div>
                                                                                        ))
                                                                                    ) : (
                                                                                        <div className="dropdown-item">No Chargers Found</div>
                                                                                    )}
                                                                                </div>
                                                                            </div>
                                                                        )}
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Selected Chargers</label>
                                                                    <div className="col-sm-9">
                                                                        <textarea
                                                                            className="form-control"
                                                                            value={selectedChargers.join(', ')}
                                                                            readOnly
                                                                            rows={4}
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}
                                                        <div className="text-center">
                                                            <button type="submit" className="btn btn-primary mr-2">Submit</button>
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

export default Assigntoclients;
