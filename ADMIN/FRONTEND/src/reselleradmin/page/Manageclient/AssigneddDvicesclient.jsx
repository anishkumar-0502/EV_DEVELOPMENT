import React, { useState, useEffect, useRef , useCallback} from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate, useLocation } from 'react-router-dom';
import Swal from 'sweetalert2';

const Assigneddevicesclient = ({ userInfo, handleLogout }) => {
    const location = useLocation();
    const navigate = useNavigate();
    const client_id = location.state?.client_id || JSON.parse(localStorage.getItem('client_id'));
    const [data, setData] = useState([]);
    const [filteredData, setFilteredData] = useState([]);
    const fetchChargerDetailsCalled = useRef(false);
    const [initialResellerCommission, setInitialResellerCommission] = useState('');

    // Fetch charger details
    const fetchChargerDetails = useCallback(async () => {
        try {
            const response = await fetch('/reselleradmin/FetchChargerDetailsWithSession', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ client_id }),
            });
            if (response.ok) {
                const responseData = await response.json();
                setData(responseData.data);
                setFilteredData(responseData.data); // Initialize filtered data with all data
            } else {
                console.error('Failed to fetch assigned chargers');
            }
        } catch (error) {
            console.error('An error occurred while fetching assigned chargers');
            console.error('Error:', error);
        }
    }, [client_id]);

    useEffect(() => {
        if (!fetchChargerDetailsCalled.current && client_id) {
            fetchChargerDetails();
            fetchChargerDetailsCalled.current = true; // Mark fetchChargerDetails as called
        }
    }, [client_id, fetchChargerDetails]);

    // Data localstorage 
    useEffect(() => {
        if (client_id) {
            localStorage.setItem('client_id', client_id);
        }
    }, [client_id]);

    // Back to manage client
    const backToManageClient = () => {
        navigate('/reselleradmin/ManageClient');
    };
 
    // View session history page
    const navigateToSessionHistory = (data) => {
        const sessiondata = data.sessiondata[0]; // Assuming sessiondata is an array and we take the first element
        navigate('/reselleradmin/Sessionhistoryclient', { state: { sessiondata } });
    };

    // Search input
    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        const filteredData = data.filter((item) =>
            item.chargerID.toUpperCase().includes(inputValue)
        );
        setFilteredData(filteredData);
    };

    // Edit user role start 
    const [showEditForm, setShowEditForm] = useState(false);
    const [dataItem, setEditDataItem] = useState(null);
   
    const handleEditUser = (item) => {
        setEditDataItem(item);
        setEditRellComm(item.reseller_commission); // Set role name for editing
        setInitialResellerCommission(item.reseller_commission); // Set initial value for comparison
        setShowEditForm(true); // Open the form
    };

    const closeEditModal = () => {
        setShowEditForm(false); // Close the form
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
    const handleEditUserAndToggleBackground = (item) => {
        handleEditUser(item);
        setTheadsticky(theadsticky === 'sticky' ? '' : 'sticky');
        setTheadfixed(theadfixed === 'fixed' ? 'transparent' : 'fixed');
        setTheadBackgroundColor(theadBackgroundColor === 'white' ? 'transparent' : 'white');
    };

    // Edit user role
    const [reseller_commission, setEditRellComm] = useState('');
    
    const editUserRole = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch('/reselleradmin/UpdateResellerCommission', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ chargerID: dataItem.chargerID,  reseller_commission, modified_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Update reseller commission successfully",
                    icon: "success"
                });
                await fetchChargerDetails(); // Wait for fetchChargerDetails to complete
                setEditRellComm(''); 
                setShowEditForm(false);
                closeEditModal();
                setTheadsticky('sticky');
                setTheadfixed('fixed');
                setTheadBackgroundColor('white');
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to update reseller commission, " + responseData.message,
                    icon: "error"
                });
            }
        } catch (error) {
            Swal.fire({
                title: "Error:",
                text: "An error occurred while updating reseller commission",
                icon: "error"
            });
        }
    };

    // Determine if the Update button should be enabled
    const isUpdateButtonEnabled = reseller_commission !== initialResellerCommission;
    
    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper" style={{ paddingTop: '40px' }}>
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
                                            <button type="button" className="btn btn-success" onClick={backToManageClient}>Back</button>
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
                                            <h4 className="card-title">Edit Reseller Commission</h4>
                                        </div>
                                        <div className="table-responsive pt-3">
                                            <div className="input-group">
                                                <div className="input-group-prepend">
                                                    <span className="input-group-text" style={{color:'black', width:'185px'}}>Reseller Commission</span>
                                                </div>
                                                <input type="text" className="form-control" placeholder="Client Commission" value={reseller_commission} maxLength={6}
                                                    onChange={(e) => {
                                                        let value = e.target.value; // Define `value` here

                                                        // Remove any non-digit or non-decimal characters
                                                        value = value.replace(/[^0-9.]/g, '');

                                                        // Ensure only one decimal point is allowed
                                                        const parts = value.split('.');
                                                        if (parts.length > 2) {
                                                        value = parts[0] + '.' + parts[1]; // Combine the first two parts if more than one decimal point is present
                                                        }

                                                        setEditRellComm(value); // Update state with sanitized value
                                                    }}
                                                required/>
                                            </div>
                                        </div>
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
                                                    <h4 className="card-title" style={{ paddingTop: '10px' }}>List Of Chargers</h4>
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
                                                            onChange={handleSearchInputChange}
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
                                                        <th>Assigned Reseller Commission %</th>
                                                        <th>Commission %</th>
                                                        <th>Session History</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    {filteredData.length > 0 ? (
                                                        filteredData.map((item, index) => (
                                                            <tr key={index} style={{ textAlign: 'center' }}>
                                                                <td>{index + 1}</td>
                                                                <td>{item.chargerID ? item.chargerID : '-'}</td>
                                                                <td>{item.reseller_commission ? `${item.reseller_commission}%` : '-'}</td>
                                                                <th>
                                                                    <button type="button" className="btn btn-outline-primary btn-icon-text"  onClick={() => handleEditUserAndToggleBackground(item)} style={{marginBottom:'10px', marginRight:'10px'}}><i className="mdi mdi-pencil btn-icon-prepend"></i>Edit</button><br/>
                                                                </th>
                                                                <td>
                                                                    <button
                                                                        type="button"
                                                                        className="btn btn-outline-success btn-icon-text"
                                                                        onClick={() => navigateToSessionHistory(item)}
                                                                        style={{ marginBottom: '10px', marginLeft: '10px' }}
                                                                    >
                                                                        <i className="mdi mdi-history btn-icon-prepend"></i>Session History
                                                                    </button>
                                                                </td>
                                                            </tr>
                                                        ))
                                                    ) : (
                                                        <tr className="text-center">
                                                            <td colSpan="5">No Record Found</td>
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

export default Assigneddevicesclient;
