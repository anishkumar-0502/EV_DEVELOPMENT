import React, {useState} from 'react';
import Header from '../../components/Header';
import Sidebar from '../../components/Sidebar';
import Footer from '../../components/Footer';
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2';

const CreateClients = ({ userInfo, handleLogout }) => {
    const navigate = useNavigate();
    
    // Back manage client
    const backManageClient = () => {
        navigate('/reselleradmin/ManageClient');
    };

    // Add client
    const [client_name, setClientName] = useState('');
    const [client_phone_no, setPhoneNumber] = useState('');
    const [client_email_id, setEmailID] = useState('');
    const [client_address, setAddress] = useState('');
    const [errorMessage, setErrorMessage] = useState('');

    // Add manage device
    const addManageClient = async (e) => {
        e.preventDefault();
         
        // Validate phone number
        const phoneRegex = /^\d{10}$/;
        if (!client_phone_no) {
            setErrorMessage("Phone can't be empty.");
            return;
        }
        if (!phoneRegex.test(client_phone_no)) {
            setErrorMessage('Oops! Phone must be a 10-digit number.');
            return;
        }

        try {
            const PhoneNumber = parseInt(client_phone_no);

            const response = await fetch('/reselleradmin/addNewClient', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
                body: JSON.stringify({ reseller_id:userInfo.data.reseller_id, client_name, client_phone_no:PhoneNumber, client_email_id, client_address, created_by:userInfo.data.email_id }),
            });
            if (response.status === 200) {
                Swal.fire({
                    title: "Client added successfully",
                    icon: "success"
                });
                setClientName(''); 
                setPhoneNumber(''); 
                setEmailID(''); 
                setAddress(''); 
                backManageClient();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to add client, " + responseData.message,
                    icon: "error"
                });
            }
        }catch (error) {
            Swal.fire({
                title: "Error:", error,
                text: "An error occurred while adding the client",
                icon: "error"
            });
        }
    };
    
    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout}/>
            <div className="container-fluid page-body-wrapper" style={{paddingTop:'40px'}}>
                {/* Sidebar */}
                <Sidebar/>
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Manage Clients</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={backManageClient}>Back</button>
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
                                                    <h4 className="card-title">Create Client Users</h4>
                                                    <form className="form-sample" onSubmit={addManageClient}>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Client Name</label>
                                                                    <div className="col-sm-9">
                                                                        <input type="text" className="form-control" placeholder="Client Name" value={client_name} maxLength={25} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^a-zA-Z0-9 ]/g, ''); setClientName(sanitizedValue);}} required/>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Phone Number</label>
                                                                    <div className="col-sm-9">
                                                                        <input type="text" className="form-control" placeholder="Phone Number" value={client_phone_no} maxLength={10} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^0-9]/g, ''); setPhoneNumber(sanitizedValue);}} required/>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div className="row">
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Email ID</label>
                                                                    <div className="col-sm-9">
                                                                        <input type="email" className="form-control" placeholder="Email ID" value={client_email_id} onChange={(e) => {const value = e.target.value;
                                                                                // Remove spaces and invalid characters
                                                                                const noSpaces = value.replace(/\s/g, '');
                                                                                const validChars = noSpaces.replace(/[^a-zA-Z0-9@.]/g, '');
                                                                                // Convert to lowercase
                                                                                const lowerCaseEmail = validChars.toLowerCase();
                                                                                // Handle multiple @ symbols
                                                                                const atCount = (lowerCaseEmail.match(/@/g) || []).length;
                                                                                const sanitizedEmail = atCount <= 1 ? lowerCaseEmail : lowerCaseEmail.replace(/@.*@/, '@');
                                                                                // Set the sanitized and lowercase email
                                                                                setEmailID(sanitizedEmail); }}required/>  
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div className="col-md-6">
                                                                <div className="form-group row">
                                                                    <label className="col-sm-3 col-form-label">Address</label>
                                                                    <div className="col-sm-9">
                                                                        <textarea type="text" className="form-control" placeholder="Address" value={client_address} maxLength={150} onChange={(e) => setAddress(e.target.value)} required/>
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
                 
export default CreateClients