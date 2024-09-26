import React, { useEffect, useState, useCallback, useRef } from 'react';
import axios from 'axios';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Footer from '../components/Footer';
import Swal from 'sweetalert2';

const Profile = ({ userInfo, handleLogout }) => {
    const [data, setPosts] = useState({});
    const [username, setUserUname] = useState('');
    const [email_id, setUserEmail] = useState('');
    const [phone_no, setUserPhone] = useState('');
    const [password, setUserPassword] = useState('');
    const [errorMessage, setErrorMessage] = useState('');
    const [errorMessages, setErrorMessages] = useState('');
    const [dataAss, setPostsAss] = useState({});
    const [reseller_name, setUpdateUname] = useState('');
    const [reseller_email_id, setUpdateEmail] = useState('');
    const [reseller_phone_no, setUpdatePhone] = useState('');
    const [reseller_address, setUpdateAddress] = useState('');
    const fetchProfileCalled = useRef(false); // Ref to track if fetchProfile has been called

    // Store initial values
    const [initialResellerData, setInitialResellerData] = useState({});
    const [initialUserData, setInitialUserData] = useState({});
 
    // Store whether any changes have been made
    const [reselllerModified, setReselllerModified] = useState(false);
    const [userModified, setUserModified] = useState(false);

    // Define fetchResellerUserDetails using useCallback to memoize it
    const fetchResellerUserDetails = useCallback(async () => {
        try {
            const response = await axios.post('/reselleradmin/FetchUserProfile', {
                user_id: userInfo.data.user_id,
            });

            if (response.status === 200) {
                const data = response.data.data;
                setPosts(data);
                const resellerDetails = data.reseller_details[0] || {};
                setPostsAss(resellerDetails);
                // Set initial values
                setInitialResellerData(resellerDetails);
                setInitialUserData(data);
            } else {
                setErrorMessage('Failed to fetch profile');
                console.error('Failed to fetch profile:', response.statusText);
            }
        } catch (error) {
            setErrorMessage('An error occurred while fetching the profile');
            console.error('Error:', error);
        }
    }, [userInfo.data.user_id]);

    useEffect(() => {
        if (!fetchProfileCalled.current && userInfo && userInfo.data && userInfo.data.user_id) {
            fetchResellerUserDetails();
            fetchProfileCalled.current = true; // Mark fetchResellerUserDetails as called
        }
    }, [fetchResellerUserDetails, userInfo]);

    // Reseller profile
    useEffect(() => {
        if (dataAss) {
            setUpdateUname(dataAss.reseller_name || '');
            setUpdateEmail(dataAss.reseller_email_id || '');
            setUpdatePhone(dataAss.reseller_phone_no || '');
            setUpdateAddress(dataAss.reseller_address || '');
        }
    }, [dataAss]);

    // Set timeout
    useEffect(() => {
        if (errorMessage) {
            const timeout = setTimeout(() => setErrorMessage(''), 5000); // Clear error message after 5 seconds
            return () => clearTimeout(timeout);
        }
        if (errorMessages) {
            const timeout = setTimeout(() => setErrorMessages(''), 5000); // Clear error message after 5 seconds
            return () => clearTimeout(timeout);
        }
    }, [errorMessage, errorMessages]);

    // update reseller profile
    const addResellerProfileUpdate = async (e) => {
        e.preventDefault();

        // Validate phone number
        const phoneRegex = /^\d{10}$/;
        if (!reseller_phone_no) {
            setErrorMessages("Phone can't be empty.");
            return;
        }
        if (!phoneRegex.test(reseller_phone_no)) {
            setErrorMessages('Oops! Phone must be a 10-digit number.');
            return;
        }

        try {
            const phoneNos = parseInt(reseller_phone_no);
            const response = await fetch('/reselleradmin/UpdateResellerProfile', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    reseller_id: userInfo.data.reseller_id,
                    reseller_name,
                    reseller_address,
                    reseller_phone_no: phoneNos,
                    modified_by: userInfo.data.email_id,
                }),
            });

            if (response.ok) {
                Swal.fire({
                    title: "Reseller profile updated successfully",
                    icon: "success",
                });
                fetchResellerUserDetails();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to update reseller profile, " +responseData.message,
                    icon: "error",
                });
            }
        } catch (error) {
            Swal.fire({
                title: "Error",
                text: "An error occurred while updating the reseller profile",
                icon: "error",
            });
        }
    };

    // User profile update
    useEffect(() => {
        if (data) {
            setUserUname(data.username || '');
            setUserEmail(data.email_id || '');
            setUserPhone(data.phone_no || '');
            setUserPassword(data.password || '');
        }
    }, [data]);

    // update user profile
    const addUserProfileUpdate = async (e) => {
        e.preventDefault();

        // Validate phone number
        const phoneRegex = /^\d{10}$/;
        if (!phone_no) {
            setErrorMessage("Phone can't be empty.");
            return;
        }
        if (!phoneRegex.test(phone_no)) {
            setErrorMessage('Oops! Phone must be a 10-digit number.');
            return;
        }

        // Validate password
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
            const response = await fetch('/reselleradmin/UpdateUserProfile', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    user_id: userInfo.data.user_id,
                    username,
                    phone_no: phoneNo,
                    password: Password,
                }),
            });

            if (response.ok) {
                Swal.fire({
                    title: "User profile updated successfully",
                    icon: "success",
                });
                fetchResellerUserDetails();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to update user profile, " + responseData.message,
                    icon: "error",
                });
            }
        } catch (error) {
            Swal.fire({
                title: "Error",
                text: "An error occurred while updating the user profile",
                icon: "error",
            });
        }
    };

    useEffect(() => {
        // Check if client profile data has been modified
        setReselllerModified(
            reseller_name !== initialResellerData.reseller_name ||
            reseller_email_id !== initialResellerData.reseller_email_id ||
            reseller_phone_no !== initialResellerData.reseller_phone_no ||
            reseller_address !== initialResellerData.reseller_address
        );

        // Check if user profile data has been modified
        setUserModified(
            username !== initialUserData.username ||
            phone_no !== initialUserData.phone_no ||
            password !== initialUserData.password
        );
    }, [reseller_name, reseller_phone_no, reseller_email_id, reseller_address, username, phone_no, password, initialResellerData, initialUserData]);

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
                                        <h3 className="font-weight-bold">Profile</h3>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-md-6 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div style={{ textAlign: 'center' }}>
                                            <h4 className="card-title">Reseller Profile</h4>
                                        </div>
                                        <form className="forms-sample" onSubmit={addResellerProfileUpdate}>
                                            <div className="form-group profileINputCss">
                                                <label htmlFor="exampleInputUsername1">Username</label>
                                                <input type="text" className="form-control" placeholder="Username" value={reseller_name} maxLength={25} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^a-zA-Z0-9 ]/g, ''); setUpdateUname(sanitizedValue); }} readOnly required/>
                                            </div>
                                            <div className="form-group profileINputCss">
                                                <label htmlFor="exampleInputEmail1">Email address</label>
                                                <input type="email" className="form-control" placeholder="Email" value={reseller_email_id} onChange={(e) => setUpdateEmail(e.target.value)} readOnly required/>
                                            </div>
                                            <div className="form-group profileINputCss">
                                                <label htmlFor="exampleInputPassword1">Phone Number</label>
                                                <input type="text" className="form-control" placeholder="Phone Number" value={reseller_phone_no} maxLength={10} onChange={(e) => { const value = e.target.value; const sanitizedValue = value.replace(/[^0-9]/g, ''); setUpdatePhone(sanitizedValue); }} required/>
                                            </div>
                                            <div className="form-group profileINputCss">
                                                <label htmlFor="exampleInputConfirmPassword1">Address</label>
                                                <textarea className="form-control" placeholder="Address" value={reseller_address} maxLength={150} onChange={(e) => setUpdateAddress(e.target.value)} required/>
                                            </div>
                                            {errorMessages && <div className="text-danger">{errorMessages}</div>}<br/>
                                            <div style={{textAlign:'center'}}>
                                                <button type="submit" className="btn btn-primary mr-2" disabled={!reselllerModified}>Submit</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                            <div className="col-md-6 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div style={{ textAlign: 'center' }}>
                                            <h4 className="card-title">User Profile</h4>
                                        </div>
                                        <form className="forms-sample" onSubmit={addUserProfileUpdate}>
                                            <div className="form-group profileINputCss">
                                                <label htmlFor="exampleInputUsername1">Username</label>
                                                <input type="text" className="form-control" placeholder="Username" value={username} maxLength={25} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^a-zA-Z0-9 ]/g, ''); setUserUname(sanitizedValue); }} readOnly required/>
                                            </div>
                                            <div className="form-group profileINputCss">
                                                <label htmlFor="exampleInputEmail1">Email address</label>
                                                <input type="email" className="form-control" placeholder="Email" value={email_id} onChange={(e) => setUserEmail(e.target.value)} readOnly required/>
                                            </div>
                                            <div className="form-group profileINputCss">
                                                <label htmlFor="exampleInputPassword1">Phone Number</label>
                                                <input type="text" className="form-control" placeholder="Phone Number" value={phone_no} maxLength={10} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^0-9]/g, ''); setUserPhone(sanitizedValue); }} required/>
                                            </div>
                                            <div className="form-group profileINputCss">
                                                <label htmlFor="exampleInputConfirmPassword1">Password</label>
                                                <input type="text" className="form-control" placeholder="Password" value={password} maxLength={4} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^0-9]/g, ''); setUserPassword(sanitizedValue); }} required/>
                                            </div>
                                            {errorMessage && <div className="text-danger">{errorMessage}</div>}<br/>
                                            <div style={{textAlign:'center'}}>
                                                <button type="submit" className="btn btn-primary mr-2" disabled={!userModified}>Submit</button>
                                            </div>
                                        </form>
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
