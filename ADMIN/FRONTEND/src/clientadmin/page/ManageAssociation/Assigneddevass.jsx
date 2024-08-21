import React, { useEffect, useState, useRef } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useLocation, useNavigate } from 'react-router-dom';

const Assigneddevass = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const [searchQuery, setSearchQuery] = useState('');
    const [filteredData, setFilteredData] = useState([]);
    const [originalData, setOriginalData] = useState([]);
    const association_id = location.state?.association_id || JSON.parse(localStorage.getItem('client_id'));

    const fetchChargerDetailsCalled = useRef(false);

    // fetch charger details
    useEffect(() => {
        const fetchChargerDetails = async () => {
            try {
                const response = await fetch('/clientadmin/FetchChargerDetailsWithSession', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ association_id }),
                });
                if (response.ok) {
                    const responseData = await response.json();
                    setOriginalData(responseData.data);
                    setFilteredData(responseData.data); // Initialize filtered data with all data
                } else {
                    console.error('Failed to fetch assigned chargers');
                }
            } catch (error) {
                console.error('An error occurred while fetching assigned chargers');
                console.error('Error:', error);
            }
        };

        if (!fetchChargerDetailsCalled.current && association_id) {
            fetchChargerDetails();
            fetchChargerDetailsCalled.current = true; // Mark fetchChargerDetails as called
        }
    }, [association_id]);

    useEffect(() => {
        if (association_id) {
            localStorage.setItem('association_id', association_id);
        }
    }, [association_id]);

    // search
    const handleSearch = (e) => {
        const query = e.target.value.toLowerCase();
        setSearchQuery(query);

        if (query.trim() === '') {
            // If search query is empty, show all original data
            setFilteredData(originalData);
        } else {
            // Filter data based on search query
            const filtered = originalData.filter(item =>
                item.charger_id.toLowerCase().includes(query)
            );
            setFilteredData(filtered);
        }
    };

    // back page
    const goBack = () => {
        navigate(-1);
    };

    // view session history page
    const navsessionhistory = (item) => {
        const sessiondata = item.sessiondata[0];
        navigate('/clientadmin/Sessionhistoryass', { state: { sessiondata } });
    };

    // view assign finance page
    const navtoassignfinance = (charger_id, finance_id) => {
        navigate('/clientadmin/assignfinance', { state: { charger_id, finance_id} }); // Navigate to assignfinance page with charger_id
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
                                        <h3 className="font-weight-bold">Assigned Devices</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button
                                                type="button"
                                                className="btn btn-success"
                                                onClick={goBack}
                                                style={{ marginRight: '10px' }}
                                            >Back
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
                                        <div className="col-md-12 grid-margin">
                                            <div className="row">
                                                <div className="col-4 col-xl-8">
                                                    {/* <h4 className="card-title" style={{ paddingTop: '10px' }}></h4> */}
                                                </div>
                                                <div className="col-12 col-xl-4">
                                                    <div className="input-group">
                                                        <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                            <span className="input-group-text" id="search">
                                                                <i className="icon-search"></i>
                                                            </span>
                                                        </div>
                                                        <input
                                                            type="text"
                                                            className="form-control"
                                                            placeholder="Search now"
                                                            value={searchQuery}
                                                            onChange={handleSearch}
                                                        />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                    <tr> 
                                                        <th>Sl.No</th>
                                                        <th>Charger Id</th>
                                                        <th>Unit Cost</th>
                                                        <th>Client Commission</th>
                                                        <th>Assign Finance</th>
                                                        <th>Session History</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    {filteredData.length > 0 ? (
                                                        filteredData.map((item, index) => (
                                                            <tr key={index} style={{ textAlign: 'center' }}>
                                                                <td>{index + 1}</td>
                                                                <td>{item.charger_id ? item.charger_id : '-'}</td>
                                                                <td>{item.total_price ? '₹'+item.total_price : '-'}</td>
                                                                <td>{item.client_commission ? `${item.client_commission}%` : '-'}</td>
                                                                <td>
                                                                    <button
                                                                        type="button"
                                                                        className='btn btn-outline-primary btn-icon-text'
                                                                        onClick={() => navtoassignfinance(item.charger_id,item.finance_id )}
                                                                        style={{ marginBottom: '10px', marginRight: '10px' }}
                                                                    >
                                                                        <i className="mdi mdi-pencil btn-icon-prepend"></i>Edit
                                                                    </button>
                                                                    {/* <button
                                                                        type="button"
                                                                        className={`btn btn-outline-warning btn-icon-text ${item.finance_id ? 'disabled' : ''}`}
                                                                        // className='btn btn-outline-warning btn-icon-text'
                                                                        onClick={() => navtoassignfinance(item.charger_id)}
                                                                        style={{ marginBottom: '10px', marginRight: '10px' }}
                                                                        disabled={item.finance_id}
                                                                    >
                                                                        <i className="mdi mdi-check btn-icon-prepend"></i>Assign
                                                                    </button> */}
                                                                </td>
                                                                <td>
                                                                    <button
                                                                        type="button"
                                                                        className="btn btn-outline-success btn-icon-text"
                                                                        onClick={() => navsessionhistory(item)}
                                                                        style={{ marginBottom: '10px', marginLeft: '10px' }}
                                                                    >
                                                                        <i className="mdi mdi-history btn-icon-prepend"></i>Session History
                                                                    </button>
                                                                </td>
                                                            </tr>
                                                        ))
                                                    ) : (
                                                        <tr>
                                                            <td colSpan="6" className="text-center">No associations found.</td>
                                                        </tr>
                                                    )}
                                                </tbody>
                                            </table>
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

export default Assigneddevass;
