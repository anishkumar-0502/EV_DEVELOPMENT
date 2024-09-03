import React, { useEffect, useState, useRef, useCallback } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useLocation, useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';

const Assigneddevass = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const [searchQuery, setSearchQuery] = useState('');
    const [filteredData, setFilteredData] = useState([]);
    const [originalData, setOriginalData] = useState([]);
    const association_id = location.state?.association_id || JSON.parse(localStorage.getItem('client_id'));
    const [errorMessage, setErrorMessage] = useState('');

    const fetchChargerDetailsCalled = useRef(false);

    const fetchChargerDetails = useCallback(async () => {
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
    }, [association_id]);

    // fetch charger details
    useEffect(() => {
        if (!fetchChargerDetailsCalled.current && association_id) {
            fetchChargerDetails();
            fetchChargerDetailsCalled.current = true; // Mark fetchChargerDetails as called
        }
    }, [association_id, fetchChargerDetails]);

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
        const sessiondata = item.sessiondata;
        navigate('/clientadmin/Sessionhistoryass', { state: { sessiondata } });
    };

    // view assign finance page
    const navtoassignfinance = (charger_id, finance_id) => {
        navigate('/clientadmin/assignfinance', { state: { charger_id, finance_id} }); // Navigate to assignfinance page with charger_id
    };

    // Edit user role start 
    const [initialClientCommission, setInitialClientCommission] = useState('');
    const [showEditForm, setShowEditForm] = useState(false);
    const [dataItem, setEditDataItem] = useState(null);
    
    const handleEditUser = (item) => {
        setEditDataItem(item);
        setEditClientComm(item.client_commission); // Set role name for editing
        setInitialClientCommission(item.client_commission); // Set initial value for comparison
        setShowEditForm(true); // Open the form
    };
 
    const closeEditModal = () => {
        setShowEditForm(false); // Close the form
        setErrorMessage('');
        setTheadsticky('sticky');
        setTheadfixed('fixed');
        setTheadBackgroundColor('white');
    };
 
    const modalEditStyle = {
        display: showEditForm ? 'block' : 'none',
    }
     
    const [theadBackgroundColor, setTheadBackgroundColor] = useState('white');
    const [theadsticky, setTheadsticky] = useState('sticky');
    const [theadfixed, setTheadfixed] = useState('fixed');
 
    // Edit button thead bgcolor
    const handleEditCommission = (item) => {
        handleEditUser(item);
        setTheadsticky(theadsticky === 'sticky' ? '' : 'sticky');
        setTheadfixed(theadfixed === 'fixed' ? 'transparent' : 'fixed');
        setTheadBackgroundColor(theadBackgroundColor === 'white' ? 'transparent' : 'white');
    };
 
    // Edit user role
    const [client_commission, setEditClientComm] = useState('');
     
    const editUserRole = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch('/clientadmin/UpdateClientCommission', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ chargerID: dataItem.charger_id,  client_commission, modified_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Update Client commission successfully",
                    icon: "success"
                });
                setEditClientComm(''); 
                setShowEditForm(false);
                closeEditModal();
                setErrorMessage('');
                setTheadsticky('sticky');
                setTheadfixed('fixed');
                setTheadBackgroundColor('white');
                fetchChargerDetails();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to update client commission, " + responseData.message,
                    icon: "error"
                });
            }
        } catch (error) {
            Swal.fire({
                title: "Error:",
                text: "An error occurred while updating client commission",
                icon: "error"
            });
        }
    };
 
    // Determine if the Update button should be enabled
    const isUpdateButtonEnabled = client_commission !== initialClientCommission;

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
                        {/* Edit role start */}
                        <div className="modalStyle" style={modalEditStyle}>
                            <div className="modalContentStyle" style={{ maxHeight: '680px', overflowY: 'auto' }}>
                                <span onClick={closeEditModal} style={{ float: 'right', cursor: 'pointer', fontSize:'30px' }}>&times;</span>
                                <form className="pt-3" onSubmit={editUserRole}>
                                    <div className="card-body">
                                        <div style={{textAlign:'center'}}>
                                            <h4 className="card-title">Edit Client Commission</h4>
                                        </div>
                                        <div className="table-responsive pt-3">
                                            <div className="input-group">
                                                <div className="input-group-prepend">
                                                    <span className="input-group-text" style={{color:'black', width:'185px'}}>Client Commission</span>
                                                </div>
                                                <input type="text" className="form-control" placeholder="Client Commission" value={client_commission} maxLength={5}
                                                    onChange={(e) => {
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
                                                        // Limit the length to 6 characters
                                                        if (value.length > 5) {
                                                            value = value.slice(0, 5);
                                                        }
                                                    
                                                        // Update the state based on validation
                                                        if (!errorMessage) {
                                                            setEditClientComm(value);

                                                        }
                                                        setErrorMessage(errorMessage);
                                                    }}
                                                required/>
                                            </div>
                                        </div>
                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}
                                        <div style={{textAlign:'center'}}>
                                            <button type="submit" className="btn btn-primary mr-2" style={{marginTop:'10px'}} disabled={!isUpdateButtonEnabled}>Update</button>
                                        </div>
                                    </div>
                                </form>
                            </div>
                        </div>
                        {/* Edit role end */}
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
                                                <thead style={{ textAlign: 'center', position: theadsticky, tableLayout: theadfixed, top: 0, zIndex: 1, backgroundColor: theadBackgroundColor}}>
                                                    <tr>  
                                                        <th>Sl.No</th>
                                                        <th>Charger Id</th>
                                                        <th>Unit Cost</th>
                                                        <th>Client Commission %</th>
                                                        <th>Commission %</th>
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
                                                                <th>
                                                                    <button type="button" className="btn btn-outline-primary btn-icon-text"  onClick={() => handleEditCommission(item)} style={{marginBottom:'10px', marginRight:'10px'}}><i className="mdi mdi-pencil btn-icon-prepend"></i>Edit</button><br/>
                                                                </th>
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
                                                            <td colSpan="7" className="text-center">No associations found.</td>
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
