import React, { useState, useEffect, useRef, useCallback} from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';
import axios from 'axios';

const AddManageDevice = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();

    const [charger_id, setChargerID] = useState('');
    const [charger_model, setModel] = useState('');
    const [vendor, setVendor] = useState('');
    const [maxCurrent, setMaxCurrent] = useState('');
    const [maxPower, setMaxPower] = useState('');
    const [errorMessage, setErrorMessage] = useState('');
    const [selectChargerType, setSelectedChargerType] = useState('');
    const [connectors, setConnectors] = useState([{ connector_id: 1, connector_type: '', type_name: '', typeOptions: [] }]);
    const [data, setData] = useState([]);
    const fetchDataCalled = useRef(false);
    const [errorMessageCurrent, setErrorMessageCurrent] = useState('');
    const [errorMessagePower, setErrorMessagePower] = useState('');

     // Set timeout
     useEffect(() => {
        if (errorMessageCurrent) {
            const timeout = setTimeout(() => setErrorMessageCurrent(''), 5000); // Clear error message after 5 seconds
            return () => clearTimeout(timeout);
        }
        if (errorMessagePower) {
            const timeout = setTimeout(() => setErrorMessagePower(''), 5000); // Clear error message after 5 seconds
            return () => clearTimeout(timeout);
        }
        if (errorMessage) {
            const timeout = setTimeout(() => setErrorMessage(''), 5000); // Clear error message after 5 seconds
            return () => clearTimeout(timeout);
        }
    }, [errorMessageCurrent, errorMessagePower, errorMessage]); 
    
    // Clone data
    const handleClone = (cloneModel) => {
        const selectedModelData = data.find(item => item.charger_model === cloneModel);
        if (selectedModelData) {
            setModel(selectedModelData.charger_model);
            setVendor(selectedModelData.vendor);
            setMaxCurrent(selectedModelData.max_current);
            setMaxPower(selectedModelData.max_power);
            setSelectedChargerType(selectedModelData.charger_type);
        }
    };

    // Back manage device
    const backManageDevice = () => {
        navigate('/superadmin/ManageDevice');
    };

    // Select model 
    const handleModel = (e) => {
        setModel(e.target.value);
    };

    // Select charger type
    const handleChargerType = (e) => {
        setSelectedChargerType(e.target.value);
    };

    // Function to add a new connector
    const addConnector = () => {
        setConnectors([...connectors, { connector_id: connectors.length + 1, connector_type: '', type_name: '', typeOptions: [] }]);
    };

    // Function to remove a connector
    const removeConnector = (index) => {
        const updatedConnectors = connectors.filter((_, idx) => idx !== index);
        setConnectors(updatedConnectors);
    };

    // Function to update the connector data dynamically
    const handleConnectorChange = (index, field, value) => {
        const updatedConnectors = connectors.map((connector, idx) =>
            idx === index ? { ...connector, [field]: value } : connector
        );
        setConnectors(updatedConnectors);
    };

    // Function to fetch the type name options from the backend and update the connectors
    const updateConnectors = useCallback(async (updatedConnector) => {
        try {
            const res = await axios.post('/superadmin/fetchConnectorTypeName', {
                connector_type: updatedConnector.connector_type
            });

            if (res.data && res.data.status === 'Success') {
                if (typeof res.data.data === 'string' && res.data.data === 'No details were found') {
                    setErrorMessage('No details were found');
                    setConnectors([]); // Clear connectors if no details found
                } else if (Array.isArray(res.data.data)) {
                    // Assuming the API returns an array of objects with the `output_type_name`
                    const newConnectors = [...connectors];
                    newConnectors[updatedConnector.index].typeOptions = res.data.data.map(option => option.output_type_name);
                    setConnectors(newConnectors);
                    setErrorMessage(null); // Clear any previous error message
                }
            } else {
                setErrorMessage('Error fetching data. Please try again.');
            }
        } catch (err) {
            console.error('Error updating connectors:', err);
            setErrorMessage('No details were found');
            setConnectors([]); // Clear connectors if an error occurs
        }
    }, [connectors]);

    // Handle connector type change and trigger backend fetch for type names
    const handleConnectorType = (index, field, value) => {
        const updatedConnectors = [...connectors];
        updatedConnectors[index][field] = value;
        setConnectors(updatedConnectors);

        // Fetch type names based on connector type
        updateConnectors({ ...updatedConnectors[index], index });
    };

    // Add manage device
    const addManageDevice = async (e) => {
        e.preventDefault();

        // Validate chargerid
        const chargerIDRegex = /^[a-zA-Z0-9]{1,14}$/;
        if (!charger_id) {
            setErrorMessage("Charger ID can't be empty.");
            return;
        }
        if (!chargerIDRegex.test(charger_id)) {
            setErrorMessage('Oops! Charger ID must be a maximum of 14 characters.');
            return;
        }

        // Validate vendor
        const vendorRegex = /^[a-zA-Z0-9 ]{1,20}$/;
        if (!vendor) {
            setErrorMessage("Vendor name can't be empty.");
            return;
        }
        if (!vendorRegex.test(vendor)) {
            setErrorMessage('Oops! Vendor name must be 1 to 20 characters and contain alphanumeric and number.');
            return;
        }

        try {
            const max_current = parseInt(maxCurrent);
            const max_power = parseInt(maxPower);

            const response = await fetch('/superadmin/CreateCharger', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ charger_id, charger_model, charger_type: selectChargerType, connectors, vendor, max_current, max_power, created_by: userInfo.data.email_id }),
            });

            if (response.ok) {
                Swal.fire({
                    title: "Charger added successfully",
                    icon: "success"
                });
                setChargerID('');
                setModel('');
                setSelectedChargerType('');
                setVendor('');
                setMaxCurrent('');
                setMaxPower('');
                backManageDevice();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to add charger, " + responseData.message,
                    icon: "error"
                });
            }
        } catch (error) {
            Swal.fire({
                title: "Error:",
                text: "An error occurred while adding the charger" + error,
                icon: "error"
            });
        }
    };

    useEffect(() => {
        if (!fetchDataCalled.current) {
        const url = `/superadmin/FetchCharger`;
        axios.get(url)
            .then((res) => {
                setData(res.data.data);
            })
            .catch((err) => {
                console.error('Error fetching data:', err);
                setErrorMessage('Error fetching data. Please try again.');
            });
            fetchDataCalled.current = true;
        }
    }, []);

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout}/>
            <div className="container-fluid page-body-wrapper">
                {/* Sidebar */}
                <Sidebar/>
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Add Manage Device</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <div className="dropdown">
                                                <button className="btn btn-outline-warning btn-icon-text dropdown-toggle" type="button" style={{marginRight:'10px'}} id="dropdownMenuIconButton1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                                    <i className="ti-file btn-icon-prepend"></i>Select Clone
                                                </button>
                                                <div className="dropdown-menu" aria-labelledby="dropdownMenuIconButton1">
                                                    <h6 className="dropdown-header">Select clone model</h6>
                                                    {data.length === 0 ? (
                                                         <option disabled style={{paddingLeft:'50px'}}>No data found</option>
                                                    ) : (
                                                        Array.from(new Set(data.map(item => item.charger_model))).map((uniqueModel, index) => (
                                                            <p key={index} className="dropdown-item" onClick={() => handleClone(uniqueModel)}>{uniqueModel} KW</p>
                                                        ))
                                                    )}
                                                </div>
                                            </div>
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
                                                    <form className="form-sample" onSubmit={addManageDevice}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group">
                                                                    <label className="col-form-label labelInput">Charger ID</label>
                                                                    <input type="text" className="form-control" placeholder="Charger ID" value={charger_id} maxLength={14} onChange={(e) => {
                                                                        const value = e.target.value;
                                                                        const sanitizedValue = value.replace(/[^a-zA-Z0-9]/g, '');
                                                                        setChargerID(sanitizedValue);
                                                                    }} required/>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group">
                                                                    <label className="col-form-label labelInput">Vendor</label>
                                                                    <input type="text" className="form-control" placeholder="Vendor" value={vendor} maxLength={20} onChange={(e) => {
                                                                        const value = e.target.value;
                                                                        let sanitizedValue = value.replace(/[^a-zA-Z0-9 ]/g, '');
                                                                        setVendor(sanitizedValue);
                                                                    }} required/>
                                                                </div>
                                                            </div>
                                                        </div>

                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group">
                                                                    <label className="col-form-label labelInput">Charger Model</label>
                                                                    <select className="form-control" value={charger_model} onChange={handleModel} required>
                                                                        <option value="">Select model</option>
                                                                        <option value="3.5">3.5 KW</option>
                                                                        <option value="7.4">7.4 KW</option>
                                                                        <option value="11">11 KW</option>
                                                                        <option value="22">22 KW</option>
                                                                    </select>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group">
                                                                    <label className="col-form-label labelInput">Charger Type</label>
                                                                    <select className="form-control" value={selectChargerType} onChange={handleChargerType} required>
                                                                        <option value="">Select type</option>
                                                                        <option value="AC">AC</option>
                                                                        <option value="DC">DC</option>
                                                                    </select>
                                                                </div>
                                                            </div>
                                                        </div>

                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group">
                                                                    <label className="col-form-label labelInput">Max Current</label>
                                                                    <input type="tel" className="form-control" placeholder="Max Current" value={maxCurrent} 
                                                                    onChange={(e) => {
                                                                        let value = e.target.value;
                                                                        value = value.replace(/\D/g, ''); // Remove non-numeric
                                                                        if (value < 1) {
                                                                            value = '';
                                                                        } else if (value > 32) {
                                                                            setErrorMessageCurrent('Max Current must be between 1 and 32');
                                                                            value = '32';
                                                                        }
                                                                        setMaxCurrent(value);
                                                                    }} required/>
                                                                    {errorMessageCurrent && <div className="text-danger">{errorMessageCurrent}</div>}
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group">
                                                                    <label className="col-form-label labelInput">Max Power</label>
                                                                    <input type="tel" className="form-control" placeholder="Max Power" value={maxPower}
                                                                    onChange={(e) => {
                                                                        let value = e.target.value;
                                                                        value = value.replace(/\D/g, '');
                                                                        if (value < 1) {
                                                                            value = '';
                                                                        } else if (value > 22000) {
                                                                            setErrorMessagePower('Max Power must be between 1 and 22,000');
                                                                            value = '22000';
                                                                        }
                                                                        setMaxPower(value);
                                                                    }} required/>
                                                                    {errorMessagePower && <div className="text-danger">{errorMessagePower}</div>}
                                                                </div>
                                                            </div>
                                                        </div>

                                                        {/* Connectors section start */}
                                                        <h4 className="card-title" style={{ paddingTop: '25px', marginBottom:'0px'}}>Connectors</h4>
                                                        {connectors.map((connector, index) => (
                                                            <div className="row" key={index}>
                                                                <div className="col-md-4">
                                                                    <div className="form-group">
                                                                        <label className="col-form-label labelInput">Connector Type</label>
                                                                        <select className="form-control" value={connector.connector_type} 
                                                                            onChange={(e) => handleConnectorType(index, 'connector_type', e.target.value)} required>
                                                                            <option value="" disabled>Select type</option>
                                                                            <option value="Gun">Gun</option>
                                                                            <option value="Socket">Socket</option>
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                                <div className="col-md-4">
                                                                    <div className="form-group">
                                                                        <label className="col-form-label labelInput">Type Name</label>
                                                                        <select
                                                                            className="form-control"
                                                                            value={connector.type_name}
                                                                            onChange={(e) => handleConnectorChange(index, 'type_name', e.target.value)}
                                                                            required
                                                                            disabled={!connector.connector_type} // Disable if no connector type is selected
                                                                        >
                                                                            <option value="">Select type name</option>
                                                                            {connector.typeOptions.length > 0 ? (
                                                                                connector.typeOptions.map((option, idx) => (
                                                                                    <option key={idx} value={option}>
                                                                                        {option}
                                                                                    </option>
                                                                                ))
                                                                            ) : (
                                                                                <option disabled>No options available</option>
                                                                            )}
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                                <div className="col-md-2" style={{paddingTop:'40px'}}>
                                                                    <div className="form-group">
                                                                        <div style={{ textAlign: 'center' }}>
                                                                            <button type="submit" className="btn btn-outline-danger" onClick={() => removeConnector(index)} disabled={connectors.length === 1}> <i className="mdi mdi-delete"></i></button>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                                {/* Only show the "Add Connector" button in the last row */}
                                                                {index === connectors.length - 1 && (
                                                                    <div className="col-md-2" style={{ paddingTop: '40px' }}>
                                                                        <div className="form-group">
                                                                            <div style={{ textAlign: 'center' }}>
                                                                                <button
                                                                                    type="submit"
                                                                                    className="btn btn-outline-primary"
                                                                                    onClick={addConnector}
                                                                                >
                                                                                    <i className="mdi mdi-plus"></i>
                                                                                </button>
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                )}
                                                            </div>
                                                        ))}
                                                        {/* Connectors section end */}
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}
                                                        <br></br>
                                                        <div style={{ textAlign: 'center' }}>
                                                            <button type="submit" className="btn btn-primary mr-2">Add</button>
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

export default AddManageDevice;
