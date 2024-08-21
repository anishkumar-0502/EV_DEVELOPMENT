import React, { useState, useEffect, useRef} from 'react';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Footer from '../components/Footer';

const Wallet = ({ userInfo, handleLogout }) => {
    const [data, setPosts] = useState({});
    const fetchWalletCalled = useRef(false); // Ref to track if fetchProfile has been called

    // get profile data
    useEffect(() => {
        const fetchProfile = async () => {
            try {
                const response = await fetch('/associationadmin/FetchCommissionAmtAssociation', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ user_id: userInfo.data.user_id }),
                });

                if (response.ok) {
                    const data = await response.json()
                    // console.log("Wallet res " , data)
                    setPosts(data);
                } else {
                    console.error('Failed to fetch wallet:', response.statusText);
                }
            } catch (error) {
                console.error('Error: An error occurred while fetching the wallet,', error);
            }
        };

        if (!fetchWalletCalled.current && userInfo && userInfo.data && userInfo.data.user_id) {
            fetchProfile();
            fetchWalletCalled.current = true; // Mark fetchProfile as called
        }
    }, [userInfo]);

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper">
                {/* Sidebar */}
                <Sidebar/>
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
                                                        <h3 className="fs-30 mb-2"> <b>Rs: {data ? data.data : 'Loading...'}</b></h3>
                                                    </div>
                                                </div>
                                            </div>
                                            <div className="col-md-6 mb-4 stretch-card transparent">
                                                <div className="card card-dark-blue">
                                                    <div className="card-body">
                                                        <p className="mb-4 fs-30">Withdraw</p>
                                                        <button>click here</button>
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
                 
export default Wallet