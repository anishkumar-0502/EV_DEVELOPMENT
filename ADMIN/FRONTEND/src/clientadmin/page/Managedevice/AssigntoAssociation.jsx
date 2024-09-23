import React, { useState, useEffect, useRef, useCallback } from 'react';
import axios from 'axios';
import Swal from 'sweetalert2';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../../components/Sidebar';
import Header from '../../components/Header';
import Footer from '../../components/Footer';

const AssigntoAssociation = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const [selectedAssociationId, setSelectedAssociationId] = useState('');
    const [selectedChargers, setSelectedChargers] = useState([]);
    const [commission, setCommission] = useState('0');
    const [selectedFinanceId, setSelectedFinanceId] = useState('');
    const [financeOptions, setFinanceOptions] = useState([]);
    const [reloadPage, setReloadPage] = useState(false); // State to trigger page reload
    const [chargersLoading, setChargersLoading] = useState(true); // State to manage loading state
    const [unallocatedChargers, setUnallocatedChargers] = useState([]);
    const [clientsList, setClientsList] = useState([]);
    const fetchClientsCalled = useRef(false);
    const fetchUnallocatedChargersCalled = useRef(false);
    const fetchFinanceIdCalled = useRef(false); 

    // fetch associated users
    useEffect(() => {
        const fetchClients = async () => {
            try {
                const response = await axios.post('/clientadmin/FetchAssociationUserToAssginCharger', {
                    client_id: userInfo.data.client_id
                });
                setClientsList(response.data.data || []);
            } catch (error) {
                console.error('Error fetching clients:', error);
                setClientsList([]);
            }
        };

        // fetch unallocated charger
        const fetchUnallocatedChargers = async () => {
            try {
                const response = await axios.post('/clientadmin/FetchUnAllocatedChargerToAssgin', {
                    client_id: userInfo.data.client_id,
                });
                // console.log(response.data);
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
    }, [userInfo.data.client_id]); // Use userInfo.data.reseller_id as the dependency

    // Fetch finance details
    const fetchFinanceId = useCallback(async () => {
        try {
            const response = await axios.post('/clientadmin/FetchFinanceDetailsForSelection', {
                client_id: userInfo.data.client_id,
            });
            if (response.data && Array.isArray(response.data.data)) {
                const financeIds = response.data.data.map(item => ({
                    finance_id: item.finance_id,
                    totalprice: item.totalprice
                }));
                setFinanceOptions(financeIds);
            } else {
                console.error('Expected an array from API response, received:', response.data);
            }
        } catch (error) {
            console.error('Error fetching finance details:', error);
        }
    }, [userInfo.data.client_id]);

    useEffect(() => {
        if (!fetchFinanceIdCalled.current) {
            fetchFinanceId();
            fetchFinanceIdCalled.current = true;
        }
    }, [fetchFinanceId]);

    // select associated changes
    const handleAssociationChange = (e) => {
        const selectedAssociationId = e.target.value;
        setSelectedAssociationId(selectedAssociationId);
    };

    const handleChargerChange = (chargerId, checked) => {
        if (checked) {
            setSelectedChargers(prevState => [...prevState, chargerId]);
        } else {
            setSelectedChargers(prevState => prevState.filter(id => id !== chargerId));
        }
    };

    // set commission
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
    

    // Handle unit price selection
    const handleFinanceChange = (e) => {
        setSelectedFinanceId(e.target.value);
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

    // submit assigng
    const submitAssign = async () => {
        try {
            const response = await axios.post('/clientadmin/AssginChargerToAssociation', {
                association_id: parseInt(selectedAssociationId),
                charger_id: selectedChargers,
                client_commission: commission,
                finance_id: selectedFinanceId,
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
                navigate('/clientadmin/Allocateddevice')
            } else {
                const responseData = await response.json();
                Swal.fire({
                    icon: 'error',
                    title: 'Charger Not Assigned, ' + responseData.message,
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
                    title: "Error",
                    text: "An error occurred while assign the charger",
                    icon: "error",
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

    const goBack = () => {
        navigate('/clientadmin/Allocateddevice');
    };


    return (
        <div className='container-scroller'>
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper">
                <Sidebar />
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Assign Chargers to Association</h3>
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
                                                    <h2 className="card-title">Enter Details</h2>
                                                    <form onSubmit={handleSubmit} className="form-sample">
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Select Association</label>
                                                                    <div className="col-sm-9">
                                                                        <select
                                                                            className="form-control"
                                                                            value={selectedAssociationId}
                                                                            style={{color:'black'}}
                                                                            onChange={handleAssociationChange}
                                                                            required
                                                                        >
                                                                            <option value="">Select Association</option>
                                                                            {clientsList.length === 0 ? (
                                                                                <option disabled>No data found</option>
                                                                            ) : (
                                                                                clientsList.map((clientObj) => (
                                                                                    <option key={clientObj.association_id} value={clientObj.association_id}>
                                                                                        {clientObj.association_name}
                                                                                    </option>
                                                                                ))
                                                                            )}
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Commission </label>
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
                                                                                                      //  required
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
                                                                    <label className="col-sm-3 col-form-label">Select Unit Price</label>
                                                                    <div className="col-sm-9">
                                                                        <select
                                                                            className="form-control"
                                                                            value={selectedFinanceId}
                                                                            onChange={handleFinanceChange}
                                                                            style={{ color: 'black' }}
                                                                            required
                                                                        >
                                                                            <option value="">Select Unit Price</option>
                                                                            {financeOptions.length === 0 ? (
                                                                                <option disabled>No data found</option>
                                                                            ) : (
                                                                                financeOptions.map((finance) => (
                                                                                    <option key={finance.finance_id} value={finance.finance_id}>
                                                                                        {`₹${finance.totalprice}`}
                                                                                    </option>
                                                                                ))
                                                                            )}
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="row">
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
                    <Footer />
                </div>
            </div>
        </div>
    );
};

export default AssigntoAssociation;
