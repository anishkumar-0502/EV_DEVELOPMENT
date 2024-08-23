import React, { useState, useEffect, useRef} from 'react';
import axios from 'axios';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';

const AssignReseller = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    
    // Back manage device
    const backManageDevice = () => {
        navigate('/superadmin/ManageDevice');
    };

    const [chargers, setChargers] = useState([]);
    const [resellers, setResellers] = useState([]);
    const [reseller_id, setSelectedReseller] = useState('');
    const [charger_ids, setSelectedChargers] = useState([]);
    const [selectedModel, setSelectedModel] = useState('');
    const FetchSpecificUserRoleForSelectionCalled = useRef(false);
    const FetchUnAllocatedChargerToAssginCalled = useRef(false);

    // Fetch Reseller
    useEffect(() => {
        if (!FetchSpecificUserRoleForSelectionCalled.current) {
            const url = '/superadmin/FetchResellersToAssgin';
            axios.get(url)
                .then((res) => {
                    setResellers(res.data.data);
                })
                .catch((err) => {
                    console.error('Error fetching data:', err);
                });
                FetchSpecificUserRoleForSelectionCalled.current = true;
        }
    }, []);
    
    // Fetch Unallocated charger
    useEffect(() => {
        if (!FetchUnAllocatedChargerToAssginCalled.current) {
            const url = '/superadmin/FetchUnAllocatedChargerToAssgin';
            axios.get(url)
                .then((res) => {
                    setChargers(res.data.data);
                })
                .catch((err) => {
                    console.error('Error fetching data:', err);
                });
            FetchUnAllocatedChargerToAssginCalled.current = true;
        }
    }, []);

    // Selected status
    const handleResellerChange = (e) => {
        setSelectedReseller(e.target.value);
    };

    // charger select
    const handleChargerChange = (e) => {
        const value = e.target.value;
        setSelectedChargers(prevState =>
            prevState.includes(value)
                ? prevState.filter(charger => charger !== value)
                : [...prevState, value]
        );
    };

    // Select model
    const handleModelChange = (model) => {
        setSelectedModel(model);
    };

    // Charger list filter
    const filteredChargers = selectedModel ? chargers.filter(charger => charger.charger_model === selectedModel) : chargers;

    // Assgin charger update
    const handleSubmit = async (e) => {
        e.preventDefault();
        const resellerID = parseInt(reseller_id);
        try {
            const response = await axios.post('/superadmin/AssginChargerToReseller', {
                reseller_id: resellerID,
                charger_ids,
                modified_by: userInfo.data.email_id
            });
            if (response.status === 200) {
                Swal.fire({
                    title: "Charger assigned successfully",
                    icon: "success"
                });
                backManageDevice();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to assign charger, " + responseData.message,
                    icon: "error"
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
                                        <h3 className="font-weight-bold">Assign to Reseller</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <div className="dropdown">
                                                <button className="btn btn-outline-warning btn-icon-text dropdown-toggle" type="button" style={{marginRight:'10px'}} id="dropdownMenuIconButton1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                                    <i className="ti-file btn-icon-prepend"></i>Select Charger Model
                                                </button>
                                                <div className="dropdown-menu" aria-labelledby="dropdownMenuIconButton1">
                                                    <h6 className="dropdown-header">Select Charger Model</h6>
                                                    {Array.from(new Set(chargers.map(item => item.charger_model))).map((uniqueModel, index) => (
                                                        <p key={index} className="dropdown-item" onClick={() => handleModelChange(uniqueModel)}>{uniqueModel} KW</p>
                                                    ))}
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
                                                <form className="form-sample" style={{ textAlign: 'center' }} onSubmit={handleSubmit}>
                                                    <div className="row">
                                                        <div className="col-md-6">
                                                            <div className="card-body">
                                                                <h4 className="card-title">Reseller List</h4>
                                                                <div className="template-demo">
                                                                    <div className="form-group row">
                                                                        <div className="col-sm-9" style={{ margin: '0 auto' }}>
                                                                            <select className="form-control" value={reseller_id} onChange={handleResellerChange} required>
                                                                                <option value="">Select Reseller</option>
                                                                                {resellers.map((roles, index) => (
                                                                                    <option key={index} value={roles.reseller_id}>{roles.reseller_name}</option>
                                                                                ))}
                                                                            </select>     
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-6">
                                                            <div className="card-body">
                                                                <h4 className="card-title">Charger List</h4>
                                                                <div className="template-demo"  style={{paddingLeft:'50px'}}>
                                                                    <div className="form-group" style={{ maxHeight: '300px', overflowY: 'auto' }}>
                                                                        {filteredChargers.map((charger) => (
                                                                            <div className="form-check form-check-success" key={charger.charger_id}>
                                                                                <label className="form-check-label">
                                                                                    <input style={{ textAlign: 'center' }} type="checkbox" className="form-check-input" value={charger.charger_id} onChange={handleChargerChange} required/>
                                                                                    {charger.charger_id}
                                                                                    <i className="input-helper"></i>
                                                                                </label>
                                                                                <hr />
                                                                            </div>
                                                                        ))}
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div style={{ textAlign: 'center' }}>
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
                    {/* Footer */}
                    <Footer />
                </div>         
            </div>    
        </div>
    );
};   
                 
export default AssignReseller