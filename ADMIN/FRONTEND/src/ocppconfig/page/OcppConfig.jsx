import React, { useState, useEffect, useRef } from "react";
import Header from '../components/Header';
import Footer from '../components/Footer';
import axios from 'axios';
import Swal from 'sweetalert2';

const OcppConfig = () => { 
    const [chargerId, setChargerId] = useState("");
    const [commandsLibrary, setCommandsLibrary] = useState([]);
    const [selectedCommand, setSelectedCommand] = useState("");
    const [payload, setPayload] = useState('');
    const [response, setResponse] = useState();
    const getActionPayloadCalled = useRef(false);

    function RegError(Message) {
        Swal.fire({
            title: "Sending failed",
            text: Message,
            icon: "error",
            customClass: {
                popup: 'swal-popup-center', 
                icon: 'swal-icon-center', 
            },
        });
    }

    // Get the action payload
    const getActionPayload = async () => {
        try {
            const response = await axios.get('http://192.168.1.32:4444/OcppConfig/GetAction');
            // console.log("Data", response.data);
            setCommandsLibrary(response.data);
        } catch (error) {
            console.error('Error fetching action payload:', error);
        }
    };

    useEffect(() => {
        // Fetch the list of commands from your backend
        if (!getActionPayloadCalled.current) {
            getActionPayload();
            getActionPayloadCalled.current = true;
        }
    }, []);

    // ON command click handler for the action payload
    const onCommandClick = (index) => {
        const selectedCommand = commandsLibrary[index];
        setSelectedCommand(selectedCommand.action);
        setPayload(selectedCommand.payload);
        setResponse();
    };

    // On command click handler for the action payload
    const onSendCommand = async () => {
        try {
            if (!chargerId.trim()) {
                let setMessage = "Please enter a valid charger ID";
                RegError(setMessage);
                return false;
            }
            if (!payload) {
                let setMessage = "Please select a command.";
                RegError(setMessage);
                return false;
            }

            // console.log("chargerId", chargerId);
            // console.log("payload", payload.key);
            // console.log("selectedCommand", selectedCommand);

            // Show SweetAlert
            Swal.fire({
                title: 'Loading',
                html: 'Waiting for command response...',
                // showCancelButton: true,
                // cancelButtonText: 'Cancel', 
                didOpen: async () => {
                    Swal.showLoading();
                    
                    try {
                        const response = await axios.get(`http://192.168.1.32:4444/OcppConfig/SendOCPPRequest?id=${chargerId}&req=${encodeURIComponent(JSON.stringify(payload))}&actionBtn=${selectedCommand}`);
                        const responseData = response.data;

                        // Once the response is received, set the data
                        setResponse(responseData, null, " ");

                        // Close the loading alert once the response is received
                        Swal.close();

                        // Show success alert after closing the loading alert
                        if (responseData) {
                            Swal.fire({
                                position: 'center',
                                icon: 'success',
                                title: 'Command Response Received successfully',
                                showConfirmButton: false,
                                timer: 1500
                            });
                        }
                    } catch (error) {
                        Swal.close(); // Close loading alert in case of error
                        Swal.fire({
                            position: 'center',
                            icon: 'error',
                            title: 'Error occurred while processing the request',
                            text: error.message,
                            showConfirmButton: true
                        });
                    }
                }
            });
        } catch (error) {
            console.error('Error sending command:', error);
            alert('An error occurred while sending the command.');
        }
    };

    // Function to handle changes in the payload textarea
    const handlePayloadChange = (event) => {
        setPayload(JSON.parse(event.target.value));
    };
    const handleChargerIdChange = (event) => {
        setChargerId(event.target.value);
    };

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header/>
            <div className="container-fluid page-body-wrapper">
                <div style={{transition: 'width 0.25s ease, margin 0.25s ease', width: 'calc(100%)', minHeight: 'calc(100vh - 60px)', display: 'flex', flexDirection: 'column'}}>
                    <div className="content-wrapper" style={{padding:'15px 15px 15px 15px'}}>
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card" style={{marginBottom: '0px'}}>
                                <div className="card">
                                    <div className="card-body">
                                        <div className="row" style={{height:'55px'}}>
                                            <div className="col-md-12 grid-margin">
                                                <div className="row">
                                                    <div className="col-12 col-sm-6 col-md-6 col-xl-6 mb-2 mb-sm-0">
                                                        <div style={{fontSize:'30px'}}><span style={{ fontWeight: 'bold' }}><span style={{color:'#57B657'}}>OCPP</span> Configuration</span></div> 
                                                    </div>
                                                    <div className="col-12 col-sm-6 col-md-6 col-xl-6">
                                                        <div className="input-group">
                                                            <input type="text" className="form-control" style={{borderRadius: '10px 0 0 0', borderColor:'#57B657'}} placeholder="Charger ID" aria-label="search" aria-describedby="search" autoComplete="off" value={chargerId} onChange={handleChargerIdChange} required/>
                                                            <div className="input-group-prepend">
                                                                <button type="submit" className="btn btn-success" style={{borderRadius:'0 0 10px 0'}} onClick={onSendCommand}>SEND</button>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="row" style={{textAlign:'center', paddingTop:'25px'}}>
                                            <div className="col-md-12">
                                                <div className="card-body" >
                                                    <h4 style={{textAlign: 'center', marginBottom: '0px'}}><span style={{ fontWeight: 'bold' }}>Commands</span></h4>
                                                    <div className="template-demo">
                                                        {commandsLibrary.length > 0 ? (
                                                            commandsLibrary.map((command, index) => (
                                                                <button key={index} type="button" className={`btn ${selectedCommand === command.action ? "btn-primary" : "btn-outline-primary"}`}
                                                                    onClick={() => onCommandClick(index)}>
                                                                    {command.action}
                                                                </button>
                                                            ))
                                                        ) : (
                                                            <p className="text-center">No commands available</p>
                                                        )}
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="row">
                                            <div className="col-md-6">
                                                <div className="card-body">
                                                    <h4 className="card-title" style={{color:'rgb(233 30 157)'}}>Payload</h4>
                                                    {payload ? (
                                                        <textarea style={{ border: 'none', outline: 'none', background:'none', width: '100%', backgroundColor:'#f5f7ff' }} value={payload ? JSON.stringify(payload, null, 2) : ""}  rows="22" onChange={handlePayloadChange}/>
                                                    ) : (
                                                        <p className="card-description">No payload available</p>
                                                    )}
                                                </div>
                                            </div>
                                            <div className="col-md-6">
                                                <div className="card-body">
                                                    <h4 className="card-title" style={{color:'rgb(233 30 157)'}}>Command Response</h4>
                                                    {response ? (
                                                        <textarea style={{ border: 'none', outline: 'none', background:'none', width: '100%', backgroundColor:'#f5f7ff' }} value={response ? JSON.stringify(response, null, 2) : ""} readOnly rows="22"/>
                                                    ) : (
                                                        <p className="card-description">No command response available</p>
                                                    )}
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

export default OcppConfig;
