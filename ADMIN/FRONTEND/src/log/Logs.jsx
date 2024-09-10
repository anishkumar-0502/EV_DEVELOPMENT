import React, { useState, useEffect, useRef, useCallback } from 'react';
import Header from './components/Header';
import Footer from './components/Footer';
import './styles.css';
import Swal from 'sweetalert2';

const Logs = () => {
    const [visibleTable, setVisibleTable] = useState('All');
    const [loading, setLoading] = useState(true);
    const socketRef = useRef(null);

    // States for different types of messages
    const [allData, setAllData] = useState([]);
    const [filteredData, setFilteredData] = useState([]);
    const [isSearching, setIsSearching] = useState(false);
    const [searchInput, setSearchInput] = useState(''); // State for search input

    const [heartbeatData, setHeartbeatData] = useState([]);
    const [bootNotificationData, setBootNotificationData] = useState([]);
    const [statusNotificationData, setStatusNotificationData] = useState([]);
    const [startStopData, setStartStopData] = useState([]);
    const [meterValuesData, setMeterValuesData] = useState([]);
    const [authorizationData, setAuthorizationData] = useState([]);

    const handleFrame = useCallback(async (parsedMessage) => {
        const currentDateTime = new Date().toLocaleString('en-IN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true,
        });

        const messageWithAllDataTimestamp = {
            DeviceID: parsedMessage.DeviceID,
            message: parsedMessage.message,
            dateTime: currentDateTime,
        };

        setAllData((prevData) => {
            // Add new data to allData
            const updatedData = [...prevData, messageWithAllDataTimestamp];
    
            // Update filteredData based on search status
            if (isSearching && searchInput) {
                setFilteredData((prevFilteredData) => {
                    // Check for existing entries with the same DeviceID and timestamp
                    const existingEntries = prevFilteredData.filter(item =>
                        item.DeviceID === messageWithAllDataTimestamp.DeviceID &&
                        item.dateTime === messageWithAllDataTimestamp.dateTime
                    );
                    
                    if (messageWithAllDataTimestamp.DeviceID.toUpperCase().includes(searchInput)) {
                        // Append only if no existing entry with the same timestamp
                        if (existingEntries.length === 0) {
                            return [...prevFilteredData, messageWithAllDataTimestamp];
                        }
                    }
                    return prevFilteredData;
                });
            } else {
                // Show all data if not searching
                setFilteredData(updatedData);
            }
    
            return updatedData;
        });

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
    }, [isSearching, searchInput]);

    useEffect(() => {
        if (!socketRef.current) {
            const newSocket = new WebSocket('ws://122.166.210.142:7002');

            newSocket.addEventListener('open', (event) => {
                console.log('WebSocket connection opened:', event);
                Swal.fire({
                    // title: "Success",
                    text: "WebSocket connection opened.",
                    icon: "success",
                    timer: 3000,
                    timerProgressBar: true
                });
            });

            newSocket.addEventListener('message', async(response) => {
                const parsedMessage = JSON.parse(response.data);
                console.log('parsedMessage', parsedMessage);
                await handleFrame(parsedMessage);
            });

            newSocket.addEventListener('close', (event) => {
                console.log('WebSocket connection closed:', event);
                Swal.fire({
                    // title: "Closed",
                    text: "WebSocket connection closed.",
                    icon: "error",
                    timer: 3000,
                    timerProgressBar: true
                });
            });

            newSocket.addEventListener('error', (event) => {
                console.error('WebSocket error:', event);
                Swal.fire({
                    // title: "Error",
                    text: "WebSocket connection error. Please reload the web page.",
                    icon: "error",
                    timer: 3000,
                    timerProgressBar: true
                });
            });

            socketRef.current = newSocket;
            setLoading(false);
        }

        return () => {
            if (socketRef.current) {
                socketRef.current.close();
                socketRef.current = null;
            }
        };
    }, [socketRef, handleFrame]);

    // Search data
    const handleSearchInputChange = (e) => {
        // const inputValue = e.target.value.toUpperCase();
        const inputValue = e.target.value.toUpperCase().trim(); // Trim whitespace and convert to uppercase
        setSearchInput(inputValue); // Update search input state
        setIsSearching(inputValue !== ''); // Set search status

        if (inputValue === '') {
            setFilteredData(allData); // Reset to all data if search input is cleared
        } else {
            const filtered = allData.filter((item) =>
                item.DeviceID.toUpperCase().includes(inputValue)
            );
            setFilteredData(filtered);
        }
    };

    // Handle visibility buttons
    const handleTableVisibility = (table) => {
        setVisibleTable(table);
        setSearchInput(''); // Clear search input
        setIsSearching(false); // Reset search when changing table
        setFilteredData([]); // Clear filtered data when table changes
    };

    const buttons = [
        { label: 'All', value: 'All' },
        { label: 'Heartbeat', value: 'Heartbeat' },
        { label: 'BootNotification', value: 'BootNotification' },
        { label: 'StatusNotification', value: 'StatusNotification' },
        { label: 'Start/Stop', value: 'Start/Stop' },
        { label: 'Meter/Values', value: 'Meter/Values' },
        { label: 'Authorization', value: 'Authorization' }
    ];

    const dataToShow = isSearching ? filteredData : allData;
    const heartbeatDataToShow = isSearching ? filteredData : heartbeatData;
    const bootNotificationDataToShow = isSearching ? filteredData : bootNotificationData;
    const statusNotificationDataToShow = isSearching ? filteredData : statusNotificationData;
    const startStopDataToShow = isSearching ? filteredData : startStopData;
    const meterValuesDataToShow = isSearching ? filteredData : meterValuesData;
    const authorizationDataToShow = isSearching ? filteredData : authorizationData;

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header/>
            <div className="container-fluid page-body-wrapper">
                <div style={{transition: 'width 0.25s ease, margin 0.25s ease', width: 'calc(100%)', minHeight: 'calc(100vh - 60px)', display: 'flex', flexDirection: 'column'}}>
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div className="row">
                                            <div className="col-md-12 grid-margin">
                                                <div className="row">
                                                    <div className="col-4 col-xl-8">
                                                        {/* <h4 className="card-title" style={{paddingTop:'10px'}}>EVSE Live Log</h4>  */}
                                                        {/* backgroundColor: "#28a745" */}
                                                        <div className="live-indicator" style={{ display: "flex", alignItems: "center", justifyContent: "center", backgroundColor: "red", color: "white", padding: "6px 10px", borderRadius: "15px",fontWeight: "bold", fontSize: "16px", cursor: "pointer",  width: "150px", height: "40px" }}>                                                            
                                                            <span className="live-dot" style={{ width: "12px", height: "12px", backgroundColor: "white", borderRadius: "50%", marginRight: "6px", animation: "pulse 0.2s infinite" }}></span><span className="live-text">EVSE Live Log</span>
                                                        </div> 
                                                    </div>
                                                    <div className="col-8 col-xl-4">
                                                        <div className="input-group">
                                                            <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                                <span className="input-group-text" id="search">
                                                                <i className="icon-search"></i>
                                                                </span>
                                                            </div>
                                                            <input type="text" className="form-control" placeholder="Search now" aria-label="search" aria-describedby="search" autoComplete="off"  value={searchInput} onChange={handleSearchInputChange}/>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="row">
                                            <div className="col-md-12 grid-margin">
                                                <div className="row justify-content-center">
                                                    <div className="col-12 col-xl-12 text-center">
                                                       {buttons.map(button => (
                                                            <button
                                                                key={button.value}
                                                                type="button"
                                                                className={`btn ${visibleTable === button.value ? 'btn-primary' : 'btn-outline-primary'} btn-fw`}
                                                                style={{ marginBottom: '10px', marginRight: '10px' }}
                                                                onClick={() => handleTableVisibility(button.value)}
                                                            >
                                                                {button.label}
                                                            </button>
                                                        ))}
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        {/* All */}
                                        {visibleTable === 'All' && (
                                            <div className="table-responsive" style={{ maxHeight: '520px', overflowY: 'auto' }}>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr>
                                                            <th>Date/Time</th>
                                                            <th>Device ID</th>
                                                            <th>Message</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{ textAlign: 'center' }}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="3" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(dataToShow) && dataToShow.length > 0 ? (
                                                                dataToShow.slice().reverse().map((allItem, index) => (
                                                                    <tr key={index}>
                                                                        <td>{allItem.dateTime || '-'}</td>
                                                                        <td>{allItem.DeviceID || '-'}</td>
                                                                        <td>
                                                                            {allItem.message ? (
                                                                                <textarea value={JSON.stringify(allItem.message)}  style={{ border: 'none', outline: 'none', background:'none' }} readOnly rows="6" cols="150" />
                                                                            ) : (
                                                                                '-'
                                                                            )}
                                                                        </td>
                                                                    </tr>
                                                                ))
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="3" style={{ marginTop: '50px', textAlign: 'center' }}>No AllData found</td>
                                                                </tr>
                                                            )
                                                        )}
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}
                                        {/* Heartbeat */}
                                        {visibleTable === 'Heartbeat' && (
                                            <div className="table-responsive" style={{ maxHeight: '520px', overflowY: 'auto' }}>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Date/Time</th>
                                                            <th>Device ID</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="2" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(heartbeatDataToShow) && heartbeatDataToShow.length > 0 ? (
                                                                heartbeatDataToShow.slice().reverse().map((heartbeatItem, index) => (
                                                                <tr key={index}>
                                                                    <td>{heartbeatItem.dateTime || '-'}</td>
                                                                    <td>{heartbeatItem.DeviceID || '-'}</td>
                                                                </tr>
                                                            ))
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="2" style={{ marginTop: '50px', textAlign: 'center' }}>No Heartbeat found</td>
                                                                </tr>
                                                            )
                                                        )}                                                         
                                                    </tbody>
                                                </table>
                                            </div>   
                                        )}

                                        {/* BootNotification */}
                                        {visibleTable === 'BootNotification' && (
                                            <div className="table-responsive" style={{ maxHeight: '520px', overflowY: 'auto' }}>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Date/Time</th>
                                                            <th>Device ID</th>
                                                            <th>Charge Point Vendor</th>
                                                            <th>Charge Point Model</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="4" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(bootNotificationDataToShow) && bootNotificationDataToShow.length > 0 ? (
                                                                bootNotificationDataToShow.slice().reverse().map((bootNotificationItem, index) => {
                                                                    // Extract nested properties from the message array
                                                                    const chargePointVendor = bootNotificationItem.message[3]?.chargePointVendor || '-';
                                                                    const chargePointModel = bootNotificationItem.message[3]?.chargePointModel || '-';
                                                            
                                                                    return (
                                                                        <tr key={index}>
                                                                            <td>{bootNotificationItem.dateTime || '-'}</td> 
                                                                            <td>{bootNotificationItem.DeviceID || '-'}</td>
                                                                            <td>{chargePointVendor}</td> 
                                                                            <td>{chargePointModel}</td>   
                                                                        </tr>
                                                                    );
                                                                })
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="4" style={{ marginTop: '50px', textAlign: 'center' }}>No BootNotification found</td>
                                                                </tr>
                                                            )
                                                        )}                                                               
                                                    </tbody>
                                                </table>
                                            </div>    
                                        )}

                                        {/* StatusNotification */}
                                        {visibleTable === 'StatusNotification' && (
                                            <div className="table-responsive" style={{ maxHeight: '520px', overflowY: 'auto' }}>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Date/Time</th>
                                                            <th>Device ID</th>
                                                            <th>Connector ID</th>
                                                            <th>Status</th>
                                                            <th>Error Code</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="5" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(statusNotificationDataToShow) && statusNotificationDataToShow.length > 0 ? (
                                                                statusNotificationDataToShow.slice().reverse().map((statusNotificationItem, index) => {
                                                                    const getStatusStyle = (status) => {
                                                                        switch (status) {
                                                                        case 'Available':
                                                                            return { color: '#4B49AC' };
                                                                        case 'Preparing':
                                                                        case 'Charging':
                                                                            return { color: 'green' };
                                                                        case 'Finishing':
                                                                            return { color: '#ff28ec' };  
                                                                        default:
                                                                            return { color: 'red' };
                                                                        }
                                                                    };
                                                                    // Extract nested properties from the message array
                                                                    const connectorId = statusNotificationItem.message[3]?.connectorId || '-';
                                                                    const status = statusNotificationItem.message[3]?.status || '-';
                                                                    const errorCode = statusNotificationItem.message[3]?.errorCode || '-';

                                                                    return (
                                                                        <tr key={index}>
                                                                            <td>{statusNotificationItem.dateTime || '-'}</td> 
                                                                            <td>{statusNotificationItem.DeviceID || '-'}</td>
                                                                            <td>{connectorId}</td> 
                                                                            <td style={getStatusStyle(status)}><b>{status}</b></td>  
                                                                            <td>{errorCode}</td>
                                                                        </tr>
                                                                    );
                                                                })
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="5" style={{ marginTop: '50px', textAlign: 'center' }}>No StatusNotification found</td>
                                                                </tr>
                                                            )
                                                        )}                                                                
                                                    </tbody>
                                                </table>
                                            </div>    
                                        )}

                                        {/* Start/Stop */}
                                        {visibleTable === 'Start/Stop' && (
                                            <div className="table-responsive" style={{ maxHeight: '520px', overflowY: 'auto' }}>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Date/Time</th>
                                                            <th>Device ID</th>
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
                                                                <td colSpan="7" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(startStopDataToShow) && startStopDataToShow.length > 0 ? (
                                                                startStopDataToShow.slice().reverse().map((startStopItem, index) => {
                                                                    // Extract the type of transaction
                                                                    const transactionType = startStopItem.message[2];

                                                                    // Extract nested properties from the message array
                                                                    const meterStart = transactionType === 'StartTransaction' ? startStopItem.message[3]?.meterStart || '-' : '-';
                                                                    const meterStop = transactionType === 'StopTransaction' ? startStopItem.message[3]?.meterStop || '-' : '-';
                                                                    const connectorId = startStopItem.message[3]?.connectorId || '-';
                                                                    const idTag = startStopItem.message[3]?.idTag || '-';
                                                                    const transactionId = startStopItem.message[3]?.transactionId || '-';
                                                                    const reason = startStopItem.message[3]?.reason || '-';

                                                                    return (
                                                                        <tr key={index}>
                                                                            <td>{startStopItem.dateTime || '-'}</td> 
                                                                            <td>{startStopItem.DeviceID || '-'}</td>
                                                                            <td>{transactionType === 'StartTransaction' ? meterStart : (transactionType === 'StopTransaction' ? meterStop : '-')}</td>
                                                                            <td>{connectorId}</td> 
                                                                            <td>{idTag}</td>   
                                                                            <td>{transactionId}</td>
                                                                            <td>{reason}</td>
                                                                        </tr>
                                                                    );
                                                                })
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="7" style={{ marginTop: '50px', textAlign: 'center' }}>No Start/Stop found</td>
                                                                </tr>
                                                            )
                                                        )}                                                                
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}

                                        {/* Meter/Values */}
                                        {visibleTable === 'Meter/Values' && (
                                            <div className="table-responsive" style={{ maxHeight: '520px', overflowY: 'auto' }}>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Date/Time</th>
                                                            <th>Device ID</th>
                                                            <th>Connector ID</th>
                                                            <th>TransactionID</th>
                                                            <th>Meter Values</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                    {loading ? (
                                                            <tr>
                                                                <td colSpan="5" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(meterValuesDataToShow) && meterValuesDataToShow.length > 0 ? (
                                                                meterValuesDataToShow.slice().reverse().map((meterValuesItem, index) => {
                                                                    // Extract nested properties from the message array
                                                                    const connectorId = meterValuesItem.message[3]?.connectorId || '-';
                                                                    const transactionId = meterValuesItem.message[3]?.transactionId || '-';
                                                                    // const meterValue = meterValuesItem.message[3]?.meterValue || '-';
                                                            
                                                                    // Format meter values
                                                                    const meterValues = meterValuesItem.message[3]?.meterValue || [];
                                                                    const sampledValues = meterValues[0]?.sampledValue || [];

                                                                    const formattedMeterValues = sampledValues.reduce((acc, { value, unit }) => {
                                                                        switch (unit) {
                                                                            case 'V':
                                                                                acc.voltage = `Voltage: ${value}`;
                                                                                break;
                                                                            case 'A':
                                                                                acc.current = `Current: ${value}`;
                                                                                break;
                                                                            case 'W':
                                                                                acc.power = `Power: ${value}`;
                                                                                break;
                                                                            case 'Wh':
                                                                                acc.energy = `Energy: ${value}`;
                                                                                break;
                                                                            default:
                                                                                break;
                                                                        }
                                                                        return acc;
                                                                    }, {});

                                                                    return (
                                                                        <tr key={index}>
                                                                            <td>{meterValuesItem.dateTime || '-'}</td> 
                                                                            <td>{meterValuesItem.DeviceID || '-'}</td>
                                                                            <td>{connectorId}</td> 
                                                                            <td>{transactionId}</td>   
                                                                            <td>
                                                                                {formattedMeterValues.voltage || '-'}{', '}
                                                                                {formattedMeterValues.current || '-'}{', '}
                                                                                {formattedMeterValues.power || '-'}{', '}
                                                                                {formattedMeterValues.energy || '-'}
                                                                            </td>
                                                                        </tr>
                                                                    );
                                                                })
                                                            ) : (
                                                                <tr>
                                                                    <td colSpan="5" style={{ marginTop: '50px', textAlign: 'center' }}>No Meter/Values found</td>
                                                                </tr>
                                                            )
                                                        )}                                                                
                                                    </tbody>
                                                </table>
                                            </div>    
                                        )}

                                        {/* Authorization */}
                                        {visibleTable === 'Authorization' && (
                                            <div className="table-responsive" style={{ maxHeight: '520px', overflowY: 'auto' }}>
                                                <table className="table table-striped">
                                                    <thead style={{ textAlign: 'center', position: 'sticky', tableLayout: 'fixed', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                        <tr> 
                                                            <th>Date/Time</th>
                                                            <th>Device ID</th>
                                                            <th>Tag ID</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody style={{textAlign:'center'}}>
                                                        {loading ? (
                                                            <tr>
                                                                <td colSpan="3" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                            </tr>
                                                        ) : (
                                                            Array.isArray(authorizationDataToShow) && authorizationDataToShow.length > 0 ? (
                                                                authorizationDataToShow.slice().reverse().map((authorizationItem, index) => {
                                                                    // Extract nested properties from the message array
                                                                    const idTag = authorizationItem.message[3]?.idTag || '-';
                                                                    
                                                                    return (
                                                                        <tr key={index}>
                                                                            <td>{authorizationItem.dateTime || '-'}</td> 
                                                                            <td>{authorizationItem.DeviceID || '-'}</td>
                                                                            <td>{idTag}</td>
                                                                        </tr>
                                                                    );
                                                                })
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

export default Logs;
