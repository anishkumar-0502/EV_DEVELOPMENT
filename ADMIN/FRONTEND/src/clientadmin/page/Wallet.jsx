import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Footer from '../components/Footer';

const Wallet = ({ userInfo, handleLogout }) => {
    const [commissionAmount, setCommissionAmount] = useState('');
    const fetchCommissionAmountCalled = useRef(false); // Ref to track if fetchCommissionAmount has been called

    // fetch the commissiom amount
    useEffect(() => {
        const fetchCommissionAmount = async () => {
            try {
                const response = await axios.post('/clientadmin/FetchCommissionAmtClient', {
                    user_id: userInfo.data.user_id,
                });
                if (response.status === 200) {
                    setCommissionAmount(response.data.data);
                } else {
                    console.log('Failed to fetch commission amount');
                }
            } catch (error) {
                console.error('Error fetching commission amount:', error);
            }
        };

        if (!fetchCommissionAmountCalled.current && userInfo.data.user_id) {
            fetchCommissionAmount();
            fetchCommissionAmountCalled.current = true; // Mark fetchCommissionAmount as called
        }
    }, [userInfo.data.user_id]); // Include userInfo.data.user_id in the dependency array

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
                                        <h3 className="font-weight-bold">Wallet</h3>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div className="row">
                                            <div className="col-md-6 mb-4 stretch-card transparent">
                                                <div className="card card-tale">
                                                    <div className="card-body">
                                                        <h3 className="mb-4">Wallet Balance</h3>
                                                        <h3 className="fs-30 mb-2"> <b>Rs: {commissionAmount}</b></h3>
                                                    </div>
                                                </div>
                                            </div>
                                            <div className="col-md-6 mb-4 stretch-card transparent">
                                                <div className="card card-dark-blue">
                                                    <div className="card-body">
                                                        <p className="mb-4 fs-30">Withdraw</p>
                                                        <button>Click here</button>
                                                    </div>
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

export default Wallet;
