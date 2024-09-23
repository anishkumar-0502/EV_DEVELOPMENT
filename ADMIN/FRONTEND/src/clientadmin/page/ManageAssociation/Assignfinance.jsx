import React, { useEffect, useState, useCallback, useRef} from 'react';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Sidebar from '../../components/Sidebar';
import axios from 'axios';
import { useLocation, useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';

const Assignfinance = ({ userInfo, handleLogout }) => {
    const location = useLocation();
    const navigate = useNavigate();
    const [chargerId, setChargerId] = useState('');
    const [financeOptions, setFinanceOptions] = useState([]);
    const [selectedFinanceId, setSelectedFinanceId] = useState('');
    const [isEdited, setIsEdited] = useState(false); // New state to track if the unit price is edited
    const fetchFinanceIdCalled = useRef(false); 

    // Fetch finance details
    const fetchFinanceId = useCallback(async (finance_id) => {
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

                // If finance_id is provided, select the corresponding total price
                if (finance_id) {
                    const selectedFinance = financeIds.find(item => item.finance_id === finance_id);
                    if (selectedFinance) {
                        setSelectedFinanceId(selectedFinance.finance_id);
                    }
                }
            } else {
                console.error('Expected an array from API response, received:', response.data);
            }
        } catch (error) {
            console.error('Error fetching finance details:', error);
        }
    }, [userInfo.data.client_id]);

    useEffect(() => {
        const { charger_id, finance_id } = location.state || {};
        if (charger_id) {
            setChargerId(charger_id);
        }
        if (!fetchFinanceIdCalled.current) {
            fetchFinanceId(finance_id);
            fetchFinanceIdCalled.current = true;
        }
    }, [location, fetchFinanceId]);

    // Handle selection change
    const handleFinanceChange = (e) => {
        const selectedId = e.target.value;
        setSelectedFinanceId(selectedId);
        setIsEdited(true); // Mark as edited when a selection is changed
    };

    // Handle form submission
    const handleSubmit = async (e) => {
        e.preventDefault();

        try {
            const formattedData = {
                charger_id: chargerId,
                finance_id: parseInt(selectedFinanceId),
                modified_by: userInfo.data.email_id,
            };

            const response = await axios.post('/clientadmin/AssignFinanceToCharger', formattedData);

            if (response.status === 200) {
                Swal.fire({
                    icon: 'success',
                    title: 'Success!',
                    text: 'Finance has been assigned successfully.',
                    confirmButtonText: 'OK',
                }).then(() => {
                    navigate(-1);
                });
            } else {
                Swal.fire({
                    icon: 'warning',
                    title: 'Unexpected Response!',
                    text: 'Please check the details and try again.',
                    confirmButtonText: 'OK',
                });
            }
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Error!',
                text: 'Failed to assign finance. Please try again.',
                confirmButtonText: 'OK',
            });
        }
    };

    // Handle navigation back
    const goBack = () => {
        navigate(-1);
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
                                        <h3 className="font-weight-bold">Assign Finance</h3>
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
                                                    <h4 className="card-title">Finance Details</h4>
                                                    <form className="form-sample" onSubmit={handleSubmit}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Charger ID</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control"
                                                                            value={chargerId}
                                                                            readOnly
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Unit Price</label>
                                                                    <div className="col-sm-9">
                                                                        <select
                                                                            className="form-control"
                                                                            value={selectedFinanceId}
                                                                            onChange={handleFinanceChange}
                                                                            required
                                                                        >
                                                                            <option value="" disabled>Select Unit Price</option>
                                                                            {financeOptions.length === 0 ? (
                                                                                <option disabled>No data found</option>
                                                                            ) : (
                                                                                financeOptions.map((financeItem, index) => (
                                                                                    <option key={index} value={financeItem.finance_id}>{`₹${financeItem.totalprice}`}</option>
                                                                                ))
                                                                            )}
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div style={{ textAlign: 'center' }}>
                                                            <button type="submit" className="btn btn-primary mr-2" disabled={!isEdited}>
                                                                Assign
                                                            </button>
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

export default Assignfinance;
