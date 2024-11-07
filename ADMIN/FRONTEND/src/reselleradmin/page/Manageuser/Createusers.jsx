import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import Sidebar from '../../components/Sidebar';
import Swal from 'sweetalert2';

const CreateUsers = ({ userInfo, handleLogout }) => {
    const [newUser, setNewUser] = useState({
        username: '', phone_no: '', email_id: '', role_id: '', password: '', role_name: '', client_name: '', 
    });

    const [errorMessage, setErrorMessage] = useState('');
    const [userRoles, setUserRoles] = useState([]);
    const [clientNames, setClientNames] = useState([]);
    const navigate = useNavigate();
    const fetchUsersRoleClientNameCalled = useRef(false); 

    // fetch user roles
    const fetchUserRoles = useCallback(async () => {
        try {
            const response = await axios.get('/reselleradmin/FetchSpecificUserRoleForSelection');
            if (response.data.status === 'Success') {
                setUserRoles(response.data.data);
            } else {
                console.error('Failed to fetch user roles:', response.data.message);
            }
        } catch (error) {
            console.error('Error fetching user roles:', error);
        }
    }, []);

    // fetch client names
    const fetchClientNames = useCallback(async () => {
        try {
            const response = await axios.post('/reselleradmin/FetchClientForSelection', {
                reseller_id: userInfo.data.reseller_id,
            });

            if (response.data.status === 'Success') {
                setClientNames(response.data.data);
            } else {
                console.error('Failed to fetch client names:', response.data.message);
            }
        } catch (error) {
            console.error('Error fetching client names:', error);
        }
    }, [userInfo.data.reseller_id]);

   
    useEffect(() => {
        if (!fetchUsersRoleClientNameCalled.current) {
            fetchUserRoles();
            fetchClientNames();
            fetchUsersRoleClientNameCalled.current = true;
        }
    }, [fetchUserRoles, fetchClientNames]);
   
    // create users
    const createUser = async (e) => {
        e.preventDefault();

        // Validate phone number
        const phoneRegex = /^\d{10}$/;
        if (!newUser.phone_no) {
            setErrorMessage("Phone can't be empty.");
            return;
        }
        if (!phoneRegex.test(newUser.phone_no)) {
            setErrorMessage('Oops! Phone must be a 10-digit number.');
            return;
        }
 
        // Validate password
        const passwordRegex = /^\d{4}$/;
        if (!newUser.password) {
            setErrorMessage("Password can't be empty.");
            return;
        }
        if (!passwordRegex.test(newUser.password)) {
            setErrorMessage('Oops! Password must be a 4-digit number.');
            return;
        }
        
        try {
            // Find the role_id based on selected role_name
            const selectedRole = userRoles.find(role => role.role_name === newUser.role_name);
            // Find the client_id based on selected client_name
            const selectedClient = clientNames.find(client => client.client_name === newUser.client_name);

            const formattedUserData = {
                username: newUser.username,
                phone_no: parseInt(newUser.phone_no),
                email_id: newUser.email_id,
                password: parseInt(newUser.password),
                role_id: selectedRole ? selectedRole.role_id : '',
                client_id: selectedClient ? selectedClient.client_id : '',
                
                created_by: userInfo.data.email_id,
                reseller_id: userInfo.data.reseller_id,
            };

            // Perform axios POST request to create user
        const response = await axios.post(`/reselleradmin/CreateUser`, formattedUserData);

        if (response.status === 200) {
            // Handle success
            Swal.fire({
                position: "center",
                icon: "success",
                title: "User created successfully",
                showConfirmButton: false,
                timer: 1500
            });
            navigate('/reselleradmin/ManageUsers');
        } else {
            const responseData = await response.json();
                // Handle other status codes
                Swal.fire({
                    position: "center",
                    icon: "Error",
                    title: "Failed to create user. Please try again, " + responseData.message,
                    showConfirmButton: false,
                    timer: 1500
                });
            }
        } catch (error) {
            if (error.response && error.response.data && error.response.data.message) {
                setErrorMessage('Failed to create user, ' + error.response.data.message);
            } else {
                console.error('Error creating user:', error);
                setErrorMessage('Failed to create user. Please try again.');
            }
        }
    };

    // back manage users
    const goBack = () => {
        navigate('/reselleradmin/ManageUsers');
    };

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper" style={{paddingTop:'40px'}}>
                {/* Sidebar */}
                <Sidebar />
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Create User</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={goBack} style={{ marginRight: '10px' }}>Back</button>
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
                                                    <h4 className="card-title">Create Users</h4>
                                                    <form className="form-sample" onSubmit={createUser}>
                                                        <div className="row">
                                                        <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Role Name</label>
                                                                    <div className="col-sm-9">
                                                                        <select
                                                                            className="form-control"
                                                                            value={newUser.role_name}
                                                                            onChange={(e) => setNewUser({ ...newUser, role_name: e.target.value })}
                                                                            required
                                                                        >
                                                                            <option value="">Select Role</option>
                                                                            {userRoles.map(role => (
                                                                                <option key={role.role_id} value={role.role_name}>{role.role_name}</option>
                                                                            ))}
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Client Name</label>
                                                                    <div className="col-sm-9">
                                                                        <select
                                                                            className="form-control"
                                                                            value={newUser.client_name}
                                                                            onChange={(e) => setNewUser({ ...newUser, client_name: e.target.value })}
                                                                            required
                                                                        >
                                                                            <option value="">Select Client</option>
                                                                            {clientNames.map(client => (
                                                                                <option key={client.client_id} value={client.client_name}>{client.client_name}</option>
                                                                            ))}
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">User Name</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control" placeholder="User Name"
                                                                            value={newUser.username}
                                                                            maxLength={25}
                                                                            onChange={(e) => {
                                                                                const sanitizedValue = e.target.value.replace(/[^a-zA-Z0-9 ]/g, '');
                                                                                setNewUser({ ...newUser, username: sanitizedValue.slice(0, 25) });
                                                                            }}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Phone No</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control" placeholder="Phone No"
                                                                            value={newUser.phone_no}
                                                                            maxLength={10}
                                                                            onChange={(e) => {
                                                                                const sanitizedValue = e.target.value.replace(/[^0-9]/g, ''); // Remove non-numeric characters
                                                                                setNewUser({ ...newUser, phone_no: sanitizedValue.slice(0, 10) }); // Update state with sanitized value limited to 10 characters
                                                                            }}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Email ID</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="email"
                                                                            className="form-control" placeholder="Email ID"
                                                                            value={newUser.email_id}
                                                                            onChange={(e) => {
                                                                                const value = e.target.value;
                                                                                // Remove spaces and invalid characters
                                                                                const noSpaces = value.replace(/\s/g, '');
                                                                                const validChars = noSpaces.replace(/[^a-zA-Z0-9@.]/g, '');
                                                                                // Convert to lowercase
                                                                                const lowerCaseEmail = validChars.toLowerCase();
                                                                                // Handle multiple @ symbols
                                                                                const atCount = (lowerCaseEmail.match(/@/g) || []).length;
                                                                                const sanitizedEmail = atCount <= 1 ? lowerCaseEmail : lowerCaseEmail.replace(/@.*@/, '@');
                                                                                // Set the sanitized and lowercase email
                                                                                setNewUser({ ...newUser, email_id: sanitizedEmail });
                                                                            }}
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Password</label>
                                                                    <div className="col-sm-9">
                                                                        <input
                                                                            type="text"
                                                                            className="form-control" placeholder="Password"
                                                                            value={newUser.password}
                                                                            maxLength={4}
                                                                            onChange={(e) => {
                                                                                const sanitizedValue = e.target.value.replace(/[^0-9]/g, ''); // Remove non-numeric characters
                                                                                setNewUser({ ...newUser, password: sanitizedValue.slice(0, 4) }); // Update state with sanitized value limited to 10 characters
                                                                            }}
                                                                            
                                                                            required
                                                                        />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}
                                                        <div style={{ textAlign: 'center' }}>
                                                            <button type="submit" className="btn btn-primary mr-2">Create</button>
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

export default CreateUsers;
