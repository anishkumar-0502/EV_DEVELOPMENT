import React, { useState, useEffect } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate } from 'react-router-dom';
import { useLocation } from 'react-router-dom';

const ViewUserList = ({ userInfo, handleLogout }) => {
    const location = useLocation();
    const navigate = useNavigate();
    const [newUser, setNewUser] = useState({
        username: '', email_id: '', password: '', phone_no: '', wallet_bal: '', role_id: '', role_name: '',
        client_name: '', reseller_name: '', association_name: '', user_id: '', status: '',
        client_id: '', reseller_id: '', created_by:'', created_date:'', modified_by:'', modified_date:'', _id: '',
    });

    useEffect(() => {
        const { dataItem } = location.state || {};
        if (dataItem) {
            setNewUser({
                username: dataItem.username || '',
                email_id: dataItem.email_id || '',
                password: dataItem.password || '',
                phone_no: dataItem.phone_no || '',
                wallet_bal: dataItem.wallet_bal || '',
                role_id: dataItem.role_id || '',
                role_name: dataItem.role_name || '',
                client_name: dataItem.client_name || '',
                reseller_name: dataItem.reseller_name || '',
                user_id: dataItem.user_id || '',
                status: dataItem.status || '',
                client_id: dataItem.client_id || '',
                reseller_id: dataItem.reseller_id || '',
                created_by: dataItem.created_by || '',
                created_date: dataItem.created_date || '',
                modified_by: dataItem.modified_by || '',
                modified_date: dataItem.modified_date || '',
                _id: dataItem._id || '',
            });
        // Save to localStorage
        localStorage.setItem('userData', JSON.stringify(dataItem));
        } else {
            // Load from localStorage if available
            const savedData = JSON.parse(localStorage.getItem('userData'));
            if (savedData) {
                setNewUser(savedData);
            }
        }
    }, [location]);

    // Back manage users
    const handleBack = () => {
        navigate('/superadmin/ManageUsers');
    };

    // View edit user liat
    const handleEditUser = (newUser) => {
        navigate('/superadmin/EditUserList', { state: { newUser } });
    };

    // Timestamp data 
    function formatTimestamp(originalTimestamp) {
        const date = new Date(originalTimestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        
        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const seconds = String(date.getSeconds()).padStart(2, '0');
        const ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        hours = String(hours).padStart(2, '0');
    
        const formattedDate = `${day}/${month}/${year} ${hours}:${minutes}:${seconds} ${ampm}`;
        return formattedDate;
    } 

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
                                        <h3 className="font-weight-bold">Manage User's</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-outline-primary btn-icon-text"  onClick={() => handleEditUser(newUser)} style={{marginRight:'10px'}}><i className="mdi mdi-pencil btn-icon-prepend"></i>Edit</button>
                                            <button type="button" className="btn btn-success" onClick={handleBack}>Back</button>
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
                                                    <div className="col-12 col-xl-12">
                                                        <div style={{textAlign:'center'}}>
                                                            <h4 className="card-title" style={{paddingTop:'10px'}}>User Details</h4>  
                                                            <hr></hr>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">User Name: <span style={{fontWeight:'normal'}}>{newUser.username ? newUser.username : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Email Id: <span style={{fontWeight:'normal'}}>{newUser.email_id ? newUser.email_id : '-'}</span></div>  
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Phone Number: <span style={{fontWeight:'normal'}}>{newUser.phone_no ? newUser.phone_no : '-'}</span></div> 
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Password: <span style={{fontWeight:'normal'}}>{newUser.password ? newUser.password : '-'}</span></div>   
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Wallet Balance: <span style={{fontWeight:'normal'}}>{newUser.wallet_bal ? newUser.wallet_bal : '0'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Role Name: <span style={{fontWeight:'normal'}}>{newUser.role_name ? newUser.role_name : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Assigned Reseller Name: <span style={{fontWeight:'normal'}}>{newUser.reseller_name ? newUser.reseller_name : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Assigned Client Name: <span style={{fontWeight:'normal'}}>{newUser.client_name ? newUser.client_name : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Assigned Association Name: <span style={{fontWeight:'normal'}}>{newUser.association_name ? newUser.association_name :'-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Created By: <span style={{fontWeight:'normal'}}>{newUser.created_by ? newUser.created_by : '-'}</span></div> 
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Created Date: <span style={{fontWeight:'normal'}}>{newUser.created_date ? formatTimestamp(newUser.created_date) : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Modified By: <span style={{fontWeight:'normal'}}>{newUser.modified_by ? newUser.modified_by : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Modified Date: <span style={{fontWeight:'normal'}}>{newUser.modified_date ? formatTimestamp(newUser.modified_date) : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Status: <span style={{fontWeight:'normal'}}>{newUser.status===true ? <span className="text-success">Active</span> : <span className="text-danger">DeActive</span>}</span></div>
                                                            </div>
                                                        </div>
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
                 
export default ViewUserList