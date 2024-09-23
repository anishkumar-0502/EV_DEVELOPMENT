import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
// import Swal from 'sweetalert2';
import { useNavigate } from 'react-router-dom';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';

const ManageAssociation = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const [associations, setAssociations] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');

    // search
    const handleSearch = (e) => {
        setSearchQuery(e.target.value);
    };
    const filterAssociations = (associations) => {
        return associations.filter((association) =>
            association.association_name.toString().toLowerCase().includes(searchQuery.toLowerCase())
        );
    };

    const fetchUsersCalled = useRef(false); 

    // fetch user
    useEffect(() => {
        const fetchUsers = async () => {
            try {
                const response = await axios.post('/clientadmin/FetchAssociationUser', {
                    client_id: userInfo.data.client_id
                });
                setAssociations(response.data.data || []);
                console.log(response.data.data);
            } catch (error) {
                console.error('Error fetching users:', error);
                setAssociations([]);
            }
        };

        if (!fetchUsersCalled.current && userInfo.data.client_id) {
            fetchUsers();
            fetchUsersCalled.current = true;
        }
    }, [userInfo.data.client_id]);

    // view page 
    const navigateToViewAssociationDetails = (association) => {
        navigate('/clientadmin/ViewAss', { state: { association } });
    };

    // view create page
    const navtocreateass = () =>{
        navigate('/clientadmin/Createass')
    }
    
    // view assign deviece page
    const navigatetochargerdetails = (association_id) =>{
        navigate('/clientadmin/Assigneddevass',{ state: {association_id }})
    }

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
                                        <h3 className="font-weight-bold">Manage Association</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button
                                                type="button"
                                                className="btn btn-success"
                                                onClick={navtocreateass}
                                                style={{ marginRight: '10px' }}
                                            >
                                                Create Association
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
                                        <div className="row">
                                            <div className="col-12 col-xl-8">
                                                <h4 className="card-title" style={{ paddingTop: '10px' }}>List Of Associations</h4>
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
                                        <div className="table-responsive" style={{ maxHeight: '500px', overflowY: 'auto' }}>
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                    <tr> 
                                                        <th>Sl.No</th>
                                                        <th>Association Name</th>
                                                        <th>Email ID</th>
                                                        <th>Phone Number</th>
                                                        <th>Status</th>
                                                        <th>Actions</th>
                                                        <th>Assigned Devices</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{ textAlign: 'center' }}>
                                                    {filterAssociations(associations).length > 0 ? (
                                                        filterAssociations(associations).map((association, index) => (
                                                            <tr key={association._id || index}>
                                                                <td>{index + 1}</td>
                                                                <td>{association.association_name ? association.association_name : '-'}</td>
                                                                <td>{association.association_email_id ? association.association_email_id: '-'}</td>
                                                                <td>{association.association_phone_no ? association.association_phone_no: '-'}</td>
                                                                <td style={{ color: association.status ? 'green' : 'red' }}>{association.status ? 'Active' : 'DeActive'}</td>
                                                                <td>
                                                                    <button type="button" className="btn btn-outline-success btn-icon-text" onClick={() => navigateToViewAssociationDetails(association)} style={{ marginBottom: '10px', marginRight: '10px' }}><i className="mdi mdi-eye btn-icon-prepend"></i>View</button>
                                                                </td>
                                                                <td>
                                                                    <button type="button" className="btn btn-outline-warning btn-icon-text" onClick={() => navigatetochargerdetails(association.association_id)} style={{ marginBottom: '10px', marginRight: '10px' }}><i className="ti-file btn-icon-prepend"></i>Device</button>
                                                                </td>
                                                            </tr>
                                                        ))
                                                    ) : (
                                                        <tr className="text-center">
                                                            <td colSpan="7">No Record Found</td>
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

export default ManageAssociation;
