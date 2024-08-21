import React, { useEffect, useState } from 'react';
import Sidebar from '../../components/Sidebar';
import Header from '../../components/Header';
import Footer from '../../components/Footer';
import { useLocation, useNavigate } from 'react-router-dom';

const ViewAss = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    
    const [newass, setnewass] = useState({
        association_address: '', association_email_id: '', association_id: '', association_name: '', association_phone_no: '',
        client_id: '', created_by: '', created_date: '', modified_by: '', modified_date: '', reseller_id: '', status: '', client_name: '', reseller_name: '',
        association_wallet: '',
    });

    useEffect(() => {
        const { association } = location.state || {};
        if (association) {
          
            setnewass({
                association_address: association.association_address || '', association_email_id: association.association_email_id || '',
                association_id: association.association_id || '', association_name: association.association_name || '',
                association_phone_no: association.association_phone_no || '', client_id: association.client_id || '',
                created_by: association.created_by || '', created_date: association.created_date || '',
                modified_by: association.modified_by || '', modified_date: association.modified_date || '',
                reseller_id: association.reseller_id || '', status: association.status || '', 
                reseller_name: association.reseller_name || '',  client_name: association.client_name || '', association_wallet: association.association_wallet || '',
            });
        // Save to localStorage
        localStorage.setItem('userData', JSON.stringify(association));
        } else {
            // Load from localStorage if available
            const savedData = JSON.parse(localStorage.getItem('userData'));
            if (savedData) {
                setnewass(savedData);
            }
        }
    }, [location]);

    // back page
    const goBack = () => {
        navigate(-1);
    };

    // edit page view
    const handleEdit = (newass) =>{
        navigate('/clientadmin/Editass',{ state: { newass } })
    }

    // Timestamp
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
        hours = hours ? hours : 12;
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
                <Sidebar />
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">View Details</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-outline-primary btn-icon-text" onClick={() => handleEdit(newass)} style={{ marginRight: '10px' }}><i className="mdi mdi-pencil btn-icon-prepend"></i>Edit</button>
                                            <button
                                                type="button"
                                                className="btn btn-success"
                                                onClick={goBack}
                                                style={{ marginRight: '10px' }}
                                            >
                                               Back
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
                                            <div className="col-md-12 grid-margin">
                                                <div className="row">
                                                    <div className="col-12 col-xl-12">
                                                        <div style={{textAlign:'center'}}>
                                                            <h4 className="card-title" style={{paddingTop:'10px'}}>Association Details</h4>
                                                            <hr></hr>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Association Name:  <span style={{ fontWeight: 'normal' }}>{newass.association_name ? newass.association_name : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Association Phone: <span style={{ fontWeight: 'normal' }}>{newass.association_phone_no ? newass.association_phone_no : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Association Email: <span style={{ fontWeight: 'normal' }}>{newass.association_email_id ? newass.association_email_id : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Reseller Name:  <span style={{ fontWeight: 'normal' }}>{newass.reseller_name ? newass.reseller_name : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Client Name: <span style={{ fontWeight: 'normal' }}>{newass.client_name ? newass.client_name : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Association Wallet: <span style={{ fontWeight: 'normal' }}>{newass.association_wallet ? newass.association_wallet : '0'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Association Address: <span style={{ fontWeight: 'normal' }}>{newass.association_address ? newass.association_address : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Created By: <span style={{ fontWeight: 'normal' }}>{newass.created_by ? newass.created_by : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Created Date: <span style={{ fontWeight: 'normal' }}>{newass.created_date ? formatTimestamp(newass.created_date) : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Modified By: <span style={{ fontWeight: 'normal' }}>{newass.modified_by ? newass.modified_by : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Modified Date: <span style={{ fontWeight: 'normal' }}>{newass.modified_date ? formatTimestamp(newass.modified_date) : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Status: <span style={{fontWeight:'normal'}}>{newass.status===true ? <span className="text-success">Active</span> : <span className="text-danger">DeActive</span>}</span></div>
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

export default ViewAss;
