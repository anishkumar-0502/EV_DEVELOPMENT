import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Sidebar from '../../components/Sidebar';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
// import Swal from 'sweetalert2';

const ManageUsers = ({ userInfo, handleLogout, children }) => {
    const navigate = useNavigate();
    const [users, setUsers] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');
    const fetchUsersCalled = useRef(false); 

    // fetch users
    const fetchUsers = useCallback(async () => {
        try {
            const response = await axios.post('/clientadmin/FetchUsers', {
                client_id: userInfo.data.client_id,
            });

            if (response.status === 200) {
                const data = response.data.data;
                setUsers(data || []);
            } else {
                const data = response.data.data;
                console.error('Error fetching users: ', data);
                setUsers([]);
            }
        } catch (error) {
            console.error('Error fetching users:', error);
            setUsers([]);
        }
    }, [userInfo.data.client_id]);

    useEffect(() => {
        if (!fetchUsersCalled.current) {
            fetchUsers();
            fetchUsersCalled.current = true;
        }
    }, [fetchUsers]); // Add fetchUsers to the dependency array

  
    // view createuser
    const navigateToCreateUser = () => {
        navigate('/clientadmin/Createuser');
    };

    // view user page
    const navigateToViewSession = (user) => {
        navigate('/clientadmin/Viewuser', { state: { user } });
    };

    // search
    const handleSearch = (e) => {
        setSearchQuery(e.target.value);
    };
    const filteredUsers = users.filter((user) => {
        const searchFields = ['username'];
        return searchFields.some((field) =>
            user[field]?.toString().toLowerCase().includes(searchQuery.toLowerCase())
        );
    });

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
                                        <h3 className="font-weight-bold">Manage Users</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={navigateToCreateUser} style={{ marginRight: '10px' }}>Create User's</button>
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
                                                        <h4 className="card-title" style={{ paddingTop: '10px' }}>List Of Users</h4>
                                                    </div>
                                                    <div className="col-8 col-xl-4">
                                                        <div className="input-group">
                                                            <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                                <span className="input-group-text" id="search">
                                                                    <i className="icon-search"></i>
                                                                </span>
                                                            </div>
                                                            <input type="text" className="form-control" placeholder="Search now" value={searchQuery} onChange={handleSearch}/>
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
                                                        <th>Role Name</th>
                                                        <th>User Name</th>
                                                        <th>Email ID</th>
                                                        <th>Status</th>
                                                        <th>Actions</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{ textAlign: 'center' }}>
                                                    {filteredUsers.length > 0 ? (
                                                        filteredUsers.map((user, index) => (
                                                            <tr key={user.user_id}>
                                                                <td>{index + 1}</td>
                                                                <td>{user.role_name ? user.role_name : '-'}</td>
                                                                <td>{user.username ? user.username : '-'}</td>
                                                                <td>{user.email_id ? user.email_id : '-'}</td>
                                                                <td style={{ color: user.status ? 'green' : 'red' }}>
                                                                    {user.status ? 'Active' : 'DeActive'}
                                                                </td>
                                                                <td>
                                                                    <button type="button" className="btn btn-outline-success btn-icon-text" onClick={() => navigateToViewSession(user)} style={{ marginBottom: '10px', marginRight: '10px' }}><i className="mdi mdi-eye btn-icon-prepend"></i>View</button>
                                                                </td>
                                                            </tr>
                                                        ))
                                                    ) : (
                                                        <tr className="text-center">
                                                            <td colSpan="6">No Record Found</td>
                                                        </tr>
                                                    )}
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        {children}
                    </div>
                    {/* Footer */}
                    <Footer />
                </div>
            </div>
        </div>
    );
};

export default ManageUsers;
