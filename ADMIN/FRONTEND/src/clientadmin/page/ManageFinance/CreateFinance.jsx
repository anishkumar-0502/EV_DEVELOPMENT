import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Sidebar from '../../components/Sidebar';
import Swal from 'sweetalert2';

const CreateFinance = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const [newFinance, setNewFinance] = useState({
        eb_charges: '', app_charges: '', other_charges: '', parking_charges: '',
        rent_charges: '', open_a_eb_charges: '', open_other_charges: '', created_by: userInfo.data.email_id, // Assuming userInfo has necessary client info
    });

    const [errorMessage, setErrorMessage] = useState('');
   
    // create finance
    const createFinance = async (e) => {
        e.preventDefault();
        try {
            const formattedFinanceData = {
                client_id: userInfo.data.client_id, // Assuming userInfo has necessary client info
                eb_charges: newFinance.eb_charges,
                app_charges: newFinance.app_charges,
                other_charges: newFinance.other_charges,
                parking_charges: newFinance.parking_charges,
                rent_charges: newFinance.rent_charges,
                open_a_eb_charges: newFinance.open_a_eb_charges,
                open_other_charges: newFinance.open_other_charges,
                created_by: newFinance.created_by,
            };

            await axios.post('/clientadmin/CreateFinanceDetails', formattedFinanceData);
            Swal.fire({
                position: 'center',
                icon: 'success',
                title: 'Finance created successfully',
                showConfirmButton: false,
                timer: 1500
            });
            goBack();
        } catch (error) {
            console.error('Error creating finance:', error);
            setErrorMessage('Failed to create finance. Please try again.');
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
                                        <h3 className="font-weight-bold">Create Finance</h3>
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
                                                    <h4 className="card-title">Create Finance</h4>
                                                    <form className="form-sample" onSubmit={createFinance}>
                                                        <div className="row">
                                                            
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">EB Charges</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control" placeholder="EB Chargers"
                                                                            value={newFinance.eb_charges}
                                                                            onChange={(e) => setNewFinance({ ...newFinance, eb_charges: e.target.value })}
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
                                                                            className="form-control" placeholder="App Charges"
                                                                            value={newFinance.app_charges}
                                                                            onChange={(e) => setNewFinance({ ...newFinance, app_charges: e.target.value })}
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
                                                                            className="form-control" placeholder="Other Charges"
                                                                            value={newFinance.other_charges}
                                                                            onChange={(e) => setNewFinance({ ...newFinance, other_charges: e.target.value })}
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
                                                                            className="form-control" placeholder="Parking Charges"
                                                                            value={newFinance.parking_charges}
                                                                            onChange={(e) => setNewFinance({ ...newFinance, parking_charges: e.target.value })}
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
                                                                            className="form-control" placeholder="Rent Charges"
                                                                            value={newFinance.rent_charges}
                                                                            onChange={(e) => setNewFinance({ ...newFinance, rent_charges: e.target.value })}
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
                                                                            className="form-control" placeholder="Open A EB Charges"
                                                                            value={newFinance.open_a_eb_charges}
                                                                            onChange={(e) => setNewFinance({ ...newFinance, open_a_eb_charges: e.target.value })}
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
                                                                            className="form-control" placeholder="Open Other Charges"
                                                                            value={newFinance.open_other_charges}
                                                                            onChange={(e) => setNewFinance({ ...newFinance, open_other_charges: e.target.value })}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}
                                                        <div style={{ textAlign: 'center' }}>
                                                            <button type="submit" className="btn btn-primary mr-2">Create Finance</button>
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

export default CreateFinance;
