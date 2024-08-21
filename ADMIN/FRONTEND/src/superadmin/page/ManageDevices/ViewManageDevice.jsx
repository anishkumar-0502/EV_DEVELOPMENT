import React, { useState, useEffect } from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate } from 'react-router-dom';
import { useLocation } from 'react-router-dom';

const ViewManageDevice = ({ userInfo, handleLogout }) => {
    const location = useLocation();
    const [newUser, setNewUser] = useState({
        charger_id: '', charger_model: '', charger_type: '', model: '', type: '', vendor: '', gun_connector: '', max_current:'', max_power:'', socket_count:'', current_active_user:'',
        superadmin_commission: '', reseller_commission: '', client_commission: '',  ip: '', lat: '', long: '', short_description: '', charger_accessibility: '', unit_price: '', assigned_user: '', wifi_password: '',
        status: '', created_by:'', created_date:'', modified_by:'', modified_date:'', _id: '',
    });

    useEffect(() => {
        const { dataItem } = location.state || {};
        if (dataItem) {
            setNewUser({
                charger_id: dataItem.charger_id || '',
                charger_model: dataItem.charger_model || '',
                charger_type: dataItem.charger_type || '',
                model: dataItem.model || '',
                type: dataItem.type || '',
                vendor: dataItem.vendor || '',
                gun_connector: dataItem.gun_connector || '',
                max_current: dataItem.max_current || '',
                max_power: dataItem.max_power || '',
                socket_count: dataItem.socket_count || '',
                current_active_user: dataItem.current_active_user || '',
                superadmin_commission: dataItem.superadmin_commission || '',
                reseller_commission: dataItem.reseller_commission || '',
                client_commission: dataItem.client_commission || '',
                ip: dataItem.ip || '',
                lat: dataItem.lat || '',
                long: dataItem.long || '',
                short_description: dataItem.short_description || '',
                charger_accessibility: dataItem.charger_accessibility || '',
                unit_price: dataItem.unit_price || '',
                assigned_user: dataItem.assigned_user || '',
                wifi_password: dataItem.wifi_password || '',
                created_by: dataItem.created_by || '',
                created_date: dataItem.created_date || '',
                modified_by: dataItem.modified_by || '',
                modified_date: dataItem.modified_date || '',
                status: dataItem.status || '',
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

    const navigate = useNavigate();
    
    // Back manage device
    const handleBack = () => {
        navigate('/superadmin/ManageDevice');
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

    // View edit manage device page
    const handleEditDeviceList = (newUser) => {
        navigate('/superadmin/EditManageDevice',  { state: { newUser } });
    };

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
                                        <h3 className="font-weight-bold">Manage Device</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-outline-primary btn-icon-text" onClick={() => handleEditDeviceList(newUser)} style={{marginRight:'10px'}}><i className="mdi mdi-pencil btn-icon-prepend"></i>Edit</button>
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
                                                            <h4 className="card-title" style={{paddingTop:'10px'}}>Device Details</h4>  
                                                            <hr></hr>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Charger ID: <span style={{fontWeight:'normal'}}>{newUser.charger_id ? newUser.charger_id : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Charger Model: <span style={{fontWeight:'normal'}}>{newUser.charger_model ? newUser.charger_model +'KW': '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Charger Type: <span style={{fontWeight:'normal'}}>{newUser.charger_type ? newUser.charger_type : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Model: <span style={{fontWeight:'normal'}}>{newUser.model ?  newUser.model : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Type: <span style={{ fontWeight: 'normal' }}>{newUser.type ?  newUser.type : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Vendor: <span style={{fontWeight:'normal'}}>{newUser.vendor ?  newUser.vendor : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Gun Connector: <span style={{ fontWeight: 'normal' }}>{newUser.gun_connector === 1 ? 'Single phase' : newUser.gun_connector === 2 ? 'CSS Type 2' : newUser.gun_connector === 3 ? '3 phase socket' : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Max Current: <span style={{fontWeight:'normal'}}>{newUser.max_current ?  newUser.max_current : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Max Power: <span style={{fontWeight:'normal'}}>{newUser.max_power ? newUser.max_power : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Socket Count: <span style={{fontWeight:'normal'}}>{newUser.socket_count === 1 ? '1 Socket ' : newUser.socket_count === 2 ? '2 Sockets' : newUser.socket_count === 3 ? '3 Sockets' : newUser.socket_count === 4 ? '4 Sockets' : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Current or Active User: <span style={{fontWeight:'normal'}}>{newUser.current_active_user ?  newUser.current_active_user : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Reseller Commission: <span style={{fontWeight:'normal'}}>{newUser.reseller_commission ? newUser.reseller_commission : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        </div>

                                                        <div className="row col-12 col-xl-12">

                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Client Commission: <span style={{fontWeight:'normal'}}>{newUser.client_commission ? newUser.client_commission : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">IP: <span style={{fontWeight:'normal'}}>{newUser.ip ? newUser.ip : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Latitude: <span style={{fontWeight:'normal'}}>{newUser.lat ? newUser.lat : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        </div>

                                                        <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Longitude: <span style={{fontWeight:'normal'}}>{newUser.long ? newUser.long : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Short Description: <span style={{fontWeight:'normal'}}>{newUser.short_description ? newUser.short_description : '-'}</span></div>   
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Wifi Username: <span style={{fontWeight:'normal'}}>{newUser.wifi_username ? newUser.wifi_username : '-'}</span></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="row col-12 col-xl-12">
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Charger Accessibility: <span style={{fontWeight:'normal'}}>{newUser.charger_accessibility ? newUser.charger_accessibility : '-'}</span></div>  
                                                            </div>
                                                        </div>
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Unit Price: <span style={{fontWeight:'normal'}}>{newUser.unit_price ? newUser.unit_price : '-'}</span></div> 
                                                            </div>
                                                        </div>
                                                       {/* <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Assigned User: <span style={{fontWeight:'normal'}}>{newUser.assigned_user ? newUser.assigned_user : '-'}</span></div>
                                                            </div>
                                                        </div> */}
                                                        <div className="col-md-4">
                                                            <div className="form-group row">
                                                                <div className="col-sm-12">Wifi Password: <span style={{fontWeight:'normal'}}>{newUser.wifi_password ? newUser.wifi_password : '-'}</span></div>
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
                                                                <div className="col-sm-12">Status: <span style={{fontWeight:'normal'}}>{newUser.status === true ? <span className="text-success">Active</span> :  <span className="text-danger">DeActive</span>}</span></div>
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
                 
export default ViewManageDevice