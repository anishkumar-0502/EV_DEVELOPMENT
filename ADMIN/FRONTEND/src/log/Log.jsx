import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import Footer from './components/Footer';

const Log = ({ userInfo, handleLogout }) => {
    const [visibleTable, setVisibleTable] = useState('Heartbeat');
    const [socket, setSocket] = useState(null);
    const [loading, setLoading] = useState(true);

    // States for different types of messages
    const [heartbeatData, setHeartbeatData] = useState([]);
    const [bootNotificationData, setBootNotificationData] = useState([]);
    const [statusNotificationData, setStatusNotificationData] = useState([]);
    const [startStopData, setStartStopData] = useState([]);
    const [meterValuesData, setMeterValuesData] = useState([]);
    const [authorizationData, setAuthorizationData] = useState([]);

    useEffect(() => {
        if (!socket) {
            const newSocket = new WebSocket('ws://122.166.210.142:8566');
            // const newSocket = new WebSocket('ws://122.166.210.142:7050');

            newSocket.addEventListener('open', (event) => {
                console.log('WebSocket connection opened:', event);
            });

            newSocket.addEventListener('message', (response) => {
                const parsedMessage = JSON.parse(response.data);
                console.log('parsedMessage', parsedMessage);

                  // Get current date and time
                  const currentDateTime = new Date().toLocaleString('en-IN', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: true,
                });

                // Include the timestamp in the parsed message
                const messageWithTimestamp = {
                    ...parsedMessage,
                    dateTime: currentDateTime
                };
                
                // Categorize and store messages based on their types
                switch (parsedMessage.message[2]) {
                    case 'Heartbeat':
                        setHeartbeatData(prevData => [...prevData, messageWithTimestamp]);
                        break;
                    case 'BootNotification':
                        setBootNotificationData(prevData => [...prevData, messageWithTimestamp]);
                        break;
                    case 'StatusNotification':
                        setStatusNotificationData(prevData => [...prevData, messageWithTimestamp]);
                        break;
                    case 'StartTransaction':
                    case 'StopTransaction':
                        setStartStopData(prevData => [...prevData, messageWithTimestamp]);
                        break;
                    case 'MeterValues':
                        setMeterValuesData(prevData => [...prevData, messageWithTimestamp]);
                        break;
                    case 'Authorize':
                        setAuthorizationData(prevData => [...prevData, messageWithTimestamp]);
                        break;
                    default:
                        break;
                }
            });

            newSocket.addEventListener('close', (event) => {
                console.log('WebSocket connection closed:', event);
            });

            newSocket.addEventListener('error', (event) => {
                console.error('WebSocket error:', event);
            });

            setSocket(newSocket);
            setLoading(false);
        }

        return () => {
            if (socket) {
                socket.close();
                setSocket(null);
            }
        };
    }, [socket]);

    const handleTableVisibility = (table) => {
        setVisibleTable(table);
    };

    // Search data 
    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        if (Array.isArray(socket)) {
            const filteredData = socket.filter((item) =>
                item.DeviceID.toUpperCase().includes(inputValue)
            );
            setHeartbeatData(filteredData);
        }
    };
    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper">
                <div style={{transition: 'width 0.25s ease, margin 0.25s ease', width: 'calc(100%)', minHeight: 'calc(100vh - 60px)', display: 'flex', flexDirection: 'column'}}>
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">EV Log</h3>
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
                                                        <h4 className="card-title" style={{paddingTop:'10px'}}>List Of Log</h4>  
                                                    </div>
                                                    <div className="col-8 col-xl-4">
                                                        <div className="input-group">
                                                            <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                                <span className="input-group-text" id="search">
                                                                <i className="icon-search"></i>
                                                                </span>
                                                            </div>
                                                            <input type="text" className="form-control" placeholder="Search now" aria-label="search" aria-describedby="search" autoComplete="off" onChange={handleSearchInputChange}/>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="row">
                                            <div className="col-md-12 grid-margin">
                                                <div className="row justify-content-center">
                                                    <div className="col-12 col-xl-12 text-center">
                                                        <button type="button" className="btn btn-outline-primary btn-fw" style={{marginBottom:'10px', marginRight:'10px'}} onClick={() => handleTableVisibility('Heartbeat')}>Heartbeat</button>
                                                        <button type="button" className="btn btn-outline-primary btn-fw" style={{marginBottom:'10px', marginRight:'10px'}} onClick={() => handleTableVisibility('BootNotification')}>BootNotification</button> 
                                                        <button type="button" className="btn btn-outline-primary btn-fw" style={{marginBottom:'10px', marginRight:'10px'}} onClick={() => handleTableVisibility('StatusNotification')}>StatusNotification</button> 
                                                        <button type="button" className="btn btn-outline-primary btn-fw" style={{marginBottom:'10px', marginRight:'10px'}} onClick={() => handleTableVisibility('Start/Stop')}>Start/Stop</button> 
                                                        <button type="button" className="btn btn-outline-primary btn-fw" style={{marginBottom:'10px', marginRight:'10px'}} onClick={() => handleTableVisibility('Meter/Values')}>Meter/Values</button> 
                                                        <button type="button" className="btn btn-outline-primary btn-fw" style={{marginBottom:'10px', marginRight:'10px'}} onClick={() => handleTableVisibility('Authorization')}>Authorization</button> 
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        {/* Heartbeat */}
                                        {visibleTable === 'Heartbeat' && (
                                            <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                                <h4 className="card-title" style={{paddingTop:'10px', textAlign: 'center',}}>Heartbeat</h4>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Sl.No</th>
                                                            <th>Charger ID</th>
                                                            <th>Date/Time</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="3" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(heartbeatData) && heartbeatData.length > 0 ? (
                                                                heartbeatData.map((dataItem, index) => (
                                                                <tr key={index}>
                                                                    <td>{index + 1}</td>
                                                                    <td>{dataItem.DeviceID || '-'}</td>
                                                                    <td>{dataItem.dateTime || '-'}</td>
                                                                </tr>
                                                            ))
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="3" style={{ marginTop: '50px', textAlign: 'center' }}>No Heartbeat found</td>
                                                                </tr>
                                                            )
                                                        )}                                                         
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}

                                        {/* BootNotification */}
                                        {visibleTable === 'BootNotification' && (
                                            <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                                <h4 className="card-title" style={{paddingTop:'10px', textAlign: 'center',}}>BootNotification</h4>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Sl.No</th>
                                                            <th>Charger ID</th>
                                                            <th>Date/Time</th>
                                                            <th>Charge Point Vendor</th>
                                                            <th>Charge Point Model</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="5" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(bootNotificationData) && bootNotificationData.length > 0 ? (
                                                                bootNotificationData.map((dataItem, index) => (
                                                                <tr key={index}>
                                                                    <td>{index + 1}</td>
                                                                    <td>{dataItem.DeviceID ? dataItem.DeviceID : '-'}</td>
                                                                    <td>{dataItem.dateTime ? dataItem.dateTime : '-'}</td> 
                                                                    <td>{dataItem.chargePointVendor ? dataItem.chargePointVendor : '-'}</td> 
                                                                    <td>{dataItem.chargePointModel ? dataItem.chargePointModel : '-'}</td>                                                                                                                              
                                                                </tr>
                                                            ))
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="5" style={{ marginTop: '50px', textAlign: 'center' }}>No BootNotification found</td>
                                                                </tr>
                                                            )
                                                        )}                                                               
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}

                                        {/* StatusNotification */}
                                        {visibleTable === 'StatusNotification' && (
                                            <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                                <h4 className="card-title" style={{paddingTop:'10px', textAlign: 'center',}}>StatusNotification</h4>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Sl.No</th>
                                                            <th>Charger ID</th>
                                                            <th>Date/Time</th>
                                                            <th>Connector ID</th>
                                                            <th>Status</th>
                                                            <th>Error Code</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="6" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(statusNotificationData) && statusNotificationData.length > 0 ? (
                                                                statusNotificationData.map((dataItem, index) => (
                                                                <tr key={index}>
                                                                    <td>{index + 1}</td>
                                                                    <td>{dataItem.DeviceID ? dataItem.DeviceID : '-'}</td>
                                                                    <td>{dataItem.dateTime ? dataItem.dateTime : '-'}</td> 
                                                                    <td>{dataItem.connectorId ? dataItem.connectorId : '-'}</td> 
                                                                    <td>{dataItem.status ? dataItem.status : '-'}</td>   
                                                                    <td>{dataItem.errorCode ? dataItem.errorCode : '-'}</td>                                                                                                                                      
                                                                </tr>
                                                            ))
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="6" style={{ marginTop: '50px', textAlign: 'center' }}>No StatusNotification found</td>
                                                                </tr>
                                                            )
                                                        )}                                                                
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}

                                        {/* Start/Stop */}
                                        {visibleTable === 'Start/Stop' && (
                                            <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                                <h4 className="card-title" style={{paddingTop:'10px', textAlign: 'center',}}>Start/Stop</h4>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Sl.No</th>
                                                            <th>Charger ID</th>
                                                            <th>Date/Time</th>
                                                            <th>Start Transaction /Stop Transaction</th>
                                                            <th>Connector ID</th>
                                                            <th>Tag ID</th>
                                                            <th>TransactionID</th>
                                                            <th>Reason</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                    {loading ? (
                                                            <tr>
                                                                <td colSpan="8" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(startStopData) && startStopData.length > 0 ? (
                                                                startStopData.map((dataItem, index) => (
                                                                <tr key={index}>
                                                                    <td>{index + 1}</td>
                                                                    <td>{dataItem.DeviceID ? dataItem.DeviceID : '-'}</td>
                                                                    <td>{dataItem.dateTime ? dataItem.dateTime : '-'}</td> 
                                                                    <td>{dataItem.StartTransaction ? dataItem.StartTransaction : dataItem.StopTransaction ? dataItem.StopTransaction : '-'}</td>
                                                                    <td>{dataItem.connectorId ? dataItem.connectorId : '-'}</td> 
                                                                    <td>{dataItem.idTag ? dataItem.idTag : '-'}</td>   
                                                                    <td>{dataItem.transactionId ? dataItem.transactionId : '-'}</td>                                                                                                                                      
                                                                    <td>{dataItem.reason ? dataItem.reason : '-'}</td>                                                                                                                                      
                                                                </tr>
                                                            ))
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="8" style={{ marginTop: '50px', textAlign: 'center' }}>No Start/Stop found</td>
                                                                </tr>
                                                            )
                                                        )}                                                                
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}

                                        {/* Meter/Values */}
                                        {visibleTable === 'Meter/Values' && (
                                            <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                                <h4 className="card-title" style={{paddingTop:'10px', textAlign: 'center',}}>Meter/Values</h4>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Sl.No</th>
                                                            <th>Charger ID</th>
                                                            <th>Date/Time</th>
                                                            <th>Connector ID</th>
                                                            <th>TransactionID</th>
                                                            <th>Meter Values</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                    {loading ? (
                                                            <tr>
                                                                <td colSpan="6" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(meterValuesData) && meterValuesData.length > 0 ? (
                                                                meterValuesData.map((dataItem, index) => (
                                                                <tr key={index}>
                                                                    <td>{index + 1}</td>
                                                                    <td>{dataItem.DeviceID ? dataItem.DeviceID : '-'}</td>
                                                                    <td>{dataItem.dateTime ? dataItem.dateTime : '-'}</td> 
                                                                    <td>{dataItem.connectorId ? dataItem.connectorId : '-'}</td> 
                                                                    <td>{dataItem.transactionId ? dataItem.transactionId : '-'}</td>   
                                                                    <td>{dataItem.meterValue ? dataItem.meterValue : '-'}</td>                                                                                                                                      
                                                                </tr>
                                                            ))
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="6" style={{ marginTop: '50px', textAlign: 'center' }}>No Meter/Values found</td>
                                                                </tr>
                                                            )
                                                        )}                                                                
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}

                                        {/* Authorization */}
                                        {visibleTable === 'Authorization' && (
                                            <div className="table-responsive" style={{ maxHeight: '400px', overflowY: 'auto' }}>
                                                <h4 className="card-title" style={{paddingTop:'10px', textAlign: 'center',}}>Authorization</h4>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Sl.No</th>
                                                            <th>Date/Time</th>
                                                            <th>Tag ID</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="3" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(authorizationData) && authorizationData.length > 0 ? (
                                                                authorizationData.map((dataItem, index) => (
                                                                <tr key={index}>
                                                                    <td>{index + 1}</td>
                                                                    <td>{dataItem.DeviceID ? dataItem.DeviceID : '-'}</td>
                                                                    <td>{dataItem.dateTime ? dataItem.dateTime : '-'}</td> 
                                                                    <td>{dataItem.idTag ? dataItem.idTag : '-'}</td> 
                                                                </tr>
                                                            ))
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="3" style={{ marginTop: '50px', textAlign: 'center' }}>No Authorization found</td>
                                                                </tr>
                                                            )
                                                        )}                                                                
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}
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

export default Log;
