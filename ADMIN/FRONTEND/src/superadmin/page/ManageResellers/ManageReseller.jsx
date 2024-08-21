import React, {useState, useEffect, useRef} from 'react';
import axios from 'axios';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate } from 'react-router-dom';
// import Swal from 'sweetalert2';

const ManageReseller = ({ userInfo, handleLogout }) => { 
    const navigate = useNavigate();
    
    // View add manage reseller
    const handleAddReseller = () => {
        navigate('/superadmin/AddManageReseller');
    };

    // View manage reseller
    const handleViewReseller = (dataItem) => {
        navigate('/superadmin/ViewManageReseller', { state: { dataItem } });
    };

    // View assign client
    const handleAssignClient = (dataItem) => {
        navigate('/superadmin/AssignClient', { state: { dataItem } });
    };

    // View assign charger
    const handleAssignCharger = (dataItem) => {
        navigate('/superadmin/AssignCharger', { state: { dataItem } });
    };

    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [filteredData] = useState([]);
    const [posts, setPosts] = useState([]);
    const FetchResellersCalled = useRef(false);

    // Get manage reseller data
    useEffect(() => {
        if (!FetchResellersCalled.current) {
            const url = `/superadmin/FetchResellers`;
            axios.get(url).then((res) => {
                setData(res.data.data); 
                setLoading(false);
            })
            .catch((err) => {
                console.error('Error fetching data:', err);
                setError('Error fetching data. Please try again.');
                setLoading(false);
            });
            FetchResellersCalled.current = true;
        }
    },  []);

    // Search data 
    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        if (Array.isArray(data)) {
            const filteredData = data.filter((item) =>
                item.reseller_name.toUpperCase().includes(inputValue)
            );
            setPosts(filteredData);
        }
    };

    // Update table data 'data', and 'filteredData' 
    useEffect(() => {
        switch (data) {
            case 'filteredData':
                setPosts(filteredData);
                break;
            default:
                setPosts(data);
                break;
        }
    }, [data, filteredData]);
  
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
                                        <h3 className="font-weight-bold">Manage Reseller</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={handleAddReseller}>Create</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div className="row">
                                            <div className="col-md-12 grid-margin">
                                                <div className="row">
                                                    <div className="col-4 col-xl-8">
                                                        <h4 className="card-title" style={{paddingTop:'10px'}}>List Of Reseller</h4>  
                                                    </div>
                                                    <div className="col-8 col-xl-4">
                                                        <div className="input-group">
                                                            <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                                <span className="input-group-text" id="search">
                                                                <i className="icon-search"></i>
                                                                </span>
                                                            </div>
                                                            <input type="text" className="form-control" placeholder="Search now" aria-label="search" aria-describedby="search" autoComplete="off" onChange={handleSearchInputChange}/>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                    <tr> 
                                                        <th>Sl.No</th>
                                                        <th>Reseller Name</th>
                                                        <th>Phone Number</th>
                                                        <th>Email ID</th>
                                                        <th>Status</th>
                                                        <th>Option</th>
                                                        <th>Assigned Client</th>
                                                        <th>Assigned Charger</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{textAlign:'center'}}>
                                                    {loading ? (
                                                        <tr>
                                                            <td colSpan="8" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                        </tr>
                                                    ) : error ? (
                                                        <tr>
                                                            <td colSpan="8" style={{ marginTop: '50px', textAlign: 'center' }}>Error: {error}</td>
                                                        </tr>
                                                    ) : (
                                                        Array.isArray(posts) && posts.length > 0 ? (
                                                            posts.map((dataItem, index) => (
                                                            <tr key={index}>
                                                                <td>{index + 1}</td>
                                                                <td>{dataItem.reseller_name ? dataItem.reseller_name : '-'}</td>
                                                                <td>{dataItem.reseller_phone_no ? dataItem.reseller_phone_no : '-'}</td>
                                                                <td>{dataItem.reseller_email_id ? dataItem.reseller_email_id : '-'}</td>
                                                                <td>{dataItem.status===true ? <span className="text-success">Active</span> : <span className="text-danger">DeActive</span>}</td>
                                                                <td>
                                                                    <button type="button" className="btn btn-outline-success btn-icon-text" onClick={() => handleViewReseller(dataItem)} style={{marginBottom:'10px', marginRight:'10px'}}><i className="mdi mdi-eye"></i>View</button> 
                                                                </td>
                                                                <td style={{textAlign:'center'}}>
                                                                    <button type="button" className="btn btn-outline-warning btn-icon-text" onClick={() => handleAssignClient(dataItem)}><i className="ti-file btn-icon-prepend"></i>Client</button><br/>
                                                                </td>
                                                                <td style={{textAlign:'center'}}>
                                                                    <button type="button" className="btn btn-outline-warning btn-icon-text" onClick={() => handleAssignCharger(dataItem)}><i className="ti-file btn-icon-prepend"></i>Charger</button> 
                                                                </td>
                                                            </tr>
                                                        ))
                                                        ) : (
                                                        <tr>
                                                            <td colSpan="8" style={{ marginTop: '50px', textAlign: 'center' }}>No Manage Reseller found</td>
                                                        </tr>
                                                        )
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
                 
export default ManageReseller