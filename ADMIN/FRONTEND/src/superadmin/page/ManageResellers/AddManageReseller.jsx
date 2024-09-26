import React, {useState} from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';

const AddManageReseller = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    
    // Back manage reseller
    const backManageReseller = () => {
        navigate('/superadmin/ManageReseller');
    };

    // Add reseller
    const [reseller_name, setResellerName] = useState('');
    const [phoneNumber, setPhoneNumber] = useState('');
    const [reseller_email_id, setEmailID] = useState('');
    const [reseller_address, setAddress] = useState('');
    const [errorMessage, setErrorMessage] = useState('');

    // Add manage device
    const addManageReseller = async (e) => {
        e.preventDefault();
         
        // Validate phone number
        const phoneRegex = /^\d{10}$/;
        if (!phoneNumber) {
            setErrorMessage("Phone can't be empty.");
            return;
        }
        if (!phoneRegex.test(phoneNumber)) {
            setErrorMessage('Oops! Phone must be a 10-digit number.');
            return;
        }

        try {
            const phoneNumbers = parseInt(phoneNumber);

            const response = await fetch('/superadmin/CreateReseller', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
                body: JSON.stringify({ reseller_name, reseller_phone_no:phoneNumbers, reseller_email_id, reseller_address, created_by:userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Reseller added successfully",
                    icon: "success"
                });
                setResellerName(''); 
                setPhoneNumber(''); 
                setEmailID(''); 
                setAddress(''); 
                backManageReseller();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to add reseller, " + responseData.message,
                    icon: "error"
                });
            }
        }catch (error) {
            Swal.fire({
                title: "Error:", error,
                text: "An error occurred while adding the reseller",
                icon: "error"
            });
        }
    };
    
    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout}/>
            <div className="container-fluid page-body-wrapper">
                {/* Sidebar */}
                <Sidebar/>
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Add Manage Reseller</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={backManageReseller}>Back</button>
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
                                                    <h4 className="card-title">Manage Reseller</h4>
                                                    <form className="form-sample" onSubmit={addManageReseller}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label labelInput">Reseller Name</label>
                                                                    <div className="col-sm-9">
                                                                        <input type="text" className="form-control" placeholder="Reseller Name" value={reseller_name} maxLength={25} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^a-zA-Z0-9 ]/g, ''); setResellerName(sanitizedValue);}} required/>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label labelInput">Phone Number</label>
                                                                    <div className="col-sm-9">
                                                                        <input type="text" className="form-control" placeholder="Phone Number" value={phoneNumber} maxLength={10} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^0-9]/g, ''); setPhoneNumber(sanitizedValue);}} required/>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label labelInput">Email ID</label>
                                                                    <div className="col-sm-9">
                                                                    <input type="email" className="form-control" placeholder="Email ID" value={reseller_email_id} 
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
                                                                            setEmailID(sanitizedEmail); }} required />
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label labelInput">Address</label>
                                                                    <div className="col-sm-9">
                                                                        <textarea type="text" className="form-control" placeholder="Address" value={reseller_address} maxLength={150} onChange={(e) => setAddress(e.target.value)} required/>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        {errorMessage && <div className="text-danger">{errorMessage}</div>}<br/>
                                                        <div style={{textAlign:'center'}}>
                                                            <button type="submit" className="btn btn-primary mr-2">Add</button>
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
                 
export default AddManageReseller