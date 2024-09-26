import React, { useState, useEffect, useRef, useCallback } from 'react';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Footer from '../components/Footer';
import Swal from 'sweetalert2';

const Profile = ({ userInfo, handleLogout }) => {
    const [data, setPosts] = useState({});
    const [username, setUpdateUname] = useState('');
    const [email_id, setUpdateEmail] = useState('');
    const [phone_no, setUpdatePhone] = useState('');
    const [password, setUpdatePassword] = useState('');
    const [errorMessage, setErrorMessage] = useState('');

    const fetchProfileCalled = useRef(false); // Ref to track if fetchProfile has been called

    // Fetch profile
    const fetchProfile = useCallback(async () => {
        try {
            const response = await fetch('/superadmin/FetchUserProfile', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ user_id: userInfo.data.user_id }),
            });

            if (response.ok) {
                const data = await response.json();
                setPosts(data.data);
                setInitialUserData(data.data); // Set initial data
            } else {
                setErrorMessage('Failed to fetch profile');
                console.error('Failed to fetch profile:', response.statusText);
            }
        } catch (error) {
            setErrorMessage('An error occurred while fetching the profile');
            console.error('Error:', error);
        }
    }, [userInfo]);

    useEffect(() => {
        if (!fetchProfileCalled.current && userInfo && userInfo.data && userInfo.data.user_id) {
            fetchProfile();
            fetchProfileCalled.current = true; // Mark fetchProfile as called
        }
    }, [fetchProfile, userInfo]);

    useEffect(() => {
        if (data) {
            setUpdateUname(data.username || '');
            setUpdateEmail(data.email_id || '');
            setUpdatePhone(data.phone_no || '');
            setUpdatePassword(data.password || '');
        }
    }, [data]);

    // Store initial values
    const [initialUserData, setInitialUserData] = useState({});

    // Store whether any changes have been made
    const [userModified, setUserModified] = useState(false);

    useEffect(() => {
        // Check if user profile data has been modified
        setUserModified(
            username !== initialUserData.username ||
            phone_no !== initialUserData.phone_no ||
            password !== initialUserData.password
        );
    }, [username, phone_no, password, initialUserData]);

    // Clear error message after 5 seconds
    useEffect(() => {
        if (errorMessage) {
            const timeout = setTimeout(() => setErrorMessage(''), 5000); // Clear error message after 5 seconds
            return () => clearTimeout(timeout);
        }
    }, [errorMessage]);

    // Update profile
    const addProfileUpdate = async (e) => {
        e.preventDefault();

        // Phone no validation
        const phoneRegex = /^\d{10}$/;
        if (!phone_no) {
            setErrorMessage("Phone can't be empty.");
            return;
        }
        if (!phoneRegex.test(phone_no)) {
            setErrorMessage('Oops! Phone must be a 10-digit number.');
            return;
        }

        // Password validation
        const passwordRegex = /^\d{4}$/;
        if (!password) {
            setErrorMessage("Password can't be empty.");
            return;
        }
        if (!passwordRegex.test(password)) {
            setErrorMessage('Oops! Password must be a 4-digit number.');
            return;
        }

        try {
            const phoneNo = parseInt(phone_no);
            const Password = parseInt(password);
            const response = await fetch('/superadmin/UpdateUserProfile', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ user_id: userInfo.data.user_id, username, phone_no: phoneNo, password: Password, status: true, modified_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Profile updated successfully",
                    icon: "success"
                });
                fetchProfile(); // Refresh profile data
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to update profile, " + responseData.message,
                    icon: "error"
                });
            }
        } catch (error) {
            Swal.fire({
                title: "Error:",
                text: "An error occurred while updating the profile",
                icon: "error"
            });
        }
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
                                        <h3 className="font-weight-bold">Profile</h3>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div className="col-md-12 grid-margin stretch-card">
                                            <div className="card">
                                                <div className="card-body">
                                                    <form className="forms-sample" onSubmit={addProfileUpdate}>
                                                        <div className="form-group row">
                                                            <label htmlFor="exampleInputUsername2" className="col-sm-12 col-form-label labelInput">User Name</label>
                                                            <div className="col-sm-10">
                                                                <input
                                                                    type="text"
                                                                    className="form-control"
                                                                    placeholder="Username"
                                                                    value={username}
                                                                    maxLength={25}
                                                                    onChange={(e) => {
                                                                        const value = e.target.value;
                                                                        const sanitizedValue = value.replace(/[^a-zA-Z0-9 ]/g, '');
                                                                        setUpdateUname(sanitizedValue);
                                                                    }}
                                                                    readOnly
                                                                    required
                                                                />
                                                            </div>
                                                        </div>
                                                        <div className="form-group row">
                                                            <label htmlFor="exampleInputEmail2" className="col-sm-2 col-form-label labelInput">Email</label>
                                                            <div className="col-sm-10">
                                                                <input
                                                                    type="email"
                                                                    className="form-control"
                                                                    placeholder="Email"
                                                                    value={email_id}
                                                                    onChange={(e) => setUpdateEmail(e.target.value)}
                                                                    readOnly
                                                                    required
                                                                />
                                                            </div>
                                                        </div>
                                                        <div className="form-group row">
                                                            <label htmlFor="exampleInputMobile" className="col-sm-2 col-form-label labelInput">Phone</label>
                                                            <div className="col-sm-10">
                                                                <input
                                                                    type="text"
                                                                    className="form-control"
                                                                    placeholder="Phone number"
                                                                    value={phone_no}
                                                                    maxLength={10}
                                                                    onChange={(e) => {
                                                                        const value = e.target.value;
                                                                        const sanitizedValue = value.replace(/[^0-9]/g, '');
                                                                        setUpdatePhone(sanitizedValue);
                                                                    }}
                                                                    required
                                                                />
                                                            </div>
                                                        </div>
                                                        <div className="form-group row">
                                                            <label htmlFor="exampleInputPassword2" className="col-sm-2 col-form-label labelInput">Password</label>
                                                            <div className="col-sm-10">
                                                                <input
                                                                    type="text"
                                                                    className="form-control"
                                                                    placeholder="Password"
                                                                    value={password}
                                                                    maxLength={4}
                                                                    onChange={(e) => {
                                                                        const value = e.target.value;
                                                                        const sanitizedValue = value.replace(/[^0-9]/g, '');
                                                                        setUpdatePassword(sanitizedValue);
                                                                    }}
                                                                    required
                                                                />
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}<br/>
                                                        <div style={{ textAlign: 'center' }}>
                                                            <button type="submit" className="btn btn-primary mr-2" disabled={!userModified}>Update</button>
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

export default Profile;
